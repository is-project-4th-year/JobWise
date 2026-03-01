import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_session/audio_session.dart';

/// Enum to represent the current recording status
enum RecordingStatus {
  idle,
  recording,
  paused,
  stopped,
}

/// Service class for handling audio recording and Firebase Storage uploads
class AudioService {
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Recording state
  RecordingStatus _status = RecordingStatus.idle;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  Timer? _durationTimer;
  int _recordingDurationSeconds = 0;
  bool _isInitialized = false;

  // Stream controller for recording status updates
  final StreamController<RecordingStatus> _statusController =
      StreamController<RecordingStatus>.broadcast();

  // Stream controller for duration updates
  final StreamController<int> _durationController =
      StreamController<int>.broadcast();

  // Constants
  static const int maxRecordingDurationSeconds = 300; // 5 minutes
  static const int minRecordingDurationSeconds = 10; // 10 seconds
  static const int maxStorageSizeMB = 50;

  AudioService() {
    _initialize();
  }

  /// Initialize the audio recorder
  Future<void> _initialize() async {
    try {
      _log('Initializing FlutterSoundRecorder...');
      
      // Configure audio session
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
                AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));

      // Open the audio session
      await _audioRecorder.openRecorder();
      _isInitialized = true;
      _log('FlutterSoundRecorder initialized successfully');
    } catch (e) {
      _log('Error initializing recorder: $e');
      _isInitialized = false;
    }
  }

  /// Stream of recording status changes
  Stream<RecordingStatus> get recordingStream => _statusController.stream;

  /// Stream of recording duration updates (in seconds)
  Stream<int> get durationStream => _durationController.stream;

  /// Get current recording status
  RecordingStatus get status => _status;

  /// Get current recording duration in seconds
  int get recordingDurationSeconds => _recordingDurationSeconds;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AudioService] $message');
    }
  }

  /// Request microphone permissions
  Future<bool> requestPermissions() async {
    try {
      _log('Requesting microphone permissions...');

      // Check if permission is already granted
      PermissionStatus status = await Permission.microphone.status;

      if (status.isGranted) {
        _log('Microphone permission already granted');
        return true;
      }

      // Request permission
      status = await Permission.microphone.request();

      if (status.isGranted) {
        _log('Microphone permission granted');
        return true;
      } else if (status.isPermanentlyDenied) {
        _log('Microphone permission permanently denied');
        return false;
      } else {
        _log('Microphone permission denied');
        return false;
      }
    } catch (e) {
      _log('Error requesting permissions: $e');
      return false;
    }
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      _log('Starting recording...');

      // Ensure recorder is initialized
      if (!_isInitialized) {
        await _initialize();
        if (!_isInitialized) {
          _log('Failed to initialize recorder');
          return false;
        }
      }

      // Check permissions
      if (!await hasPermission()) {
        _log('No microphone permission');
        return false;
      }

      // Check if already recording
      if (_status == RecordingStatus.recording) {
        _log('Already recording');
        return false;
      }

      // Get temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '${tempDir.path}/recording_$timestamp.m4a';

      _log('Recording to: $filePath');

      // Start recording with flutter_sound
      await _audioRecorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacMP4, // AAC format for M4A
        bitRate: 128000, // 128 kbps
        sampleRate: 16000, // 16kHz for Whisper
        numChannels: 1, // Mono
      );

      // Update state
      _currentRecordingPath = filePath;
      _recordingStartTime = DateTime.now();
      _recordingDurationSeconds = 0;
      _status = RecordingStatus.recording;
      _statusController.add(_status);

      // Start duration timer
      _startDurationTimer();

      _log('Recording started successfully');
      return true;
    } catch (e) {
      _log('Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    try {
      _log('Stopping recording...');

      if (_status != RecordingStatus.recording) {
        _log('Not currently recording');
        return null;
      }

      // Stop the duration timer
      _durationTimer?.cancel();

      // Stop recording
      await _audioRecorder.stopRecorder();

      // Update state
      _status = RecordingStatus.stopped;
      _statusController.add(_status);

      if (_currentRecordingPath != null) {
        _log('Recording stopped. File saved at: $_currentRecordingPath');

        // Check minimum duration
        if (_recordingDurationSeconds < minRecordingDurationSeconds) {
          _log('Recording too short: ${_recordingDurationSeconds}s');
          // Clean up the file
          await _deleteFile(_currentRecordingPath!);
          return null;
        }

        return _currentRecordingPath;
      } else {
        _log('Recording stopped but no file path available');
        return null;
      }
    } catch (e) {
      _log('Error stopping recording: $e');
      return null;
    }
  }

  /// Cancel recording and delete the file
  Future<void> cancelRecording() async {
    try {
      _log('Cancelling recording...');

      // Stop recording
      await _audioRecorder.stopRecorder();

      // Delete the file if it exists
      if (_currentRecordingPath != null) {
        await _deleteFile(_currentRecordingPath!);
      }

      // Stop timer
      _durationTimer?.cancel();

      // Reset state
      _currentRecordingPath = null;
      _recordingStartTime = null;
      _recordingDurationSeconds = 0;
      _status = RecordingStatus.idle;
      _statusController.add(_status);

      _log('Recording cancelled');
    } catch (e) {
      _log('Error cancelling recording: $e');
    }
  }

  /// Upload audio file to Firebase Storage and return download URL
  Future<String?> uploadRecording(
    String filePath,
    String userId,
    String sessionId,
  ) async {
    try {
      _log('Uploading recording to Firebase Storage...');

      // Check if file exists
      final File file = File(filePath);
      if (!await file.exists()) {
        _log('File does not exist: $filePath');
        return null;
      }

      // Check file size
      final int fileSizeBytes = await file.length();
      final double fileSizeMB = fileSizeBytes / (1024 * 1024);
      _log('File size: ${fileSizeMB.toStringAsFixed(2)} MB');

      if (fileSizeMB > maxStorageSizeMB) {
        _log('File too large: ${fileSizeMB}MB > ${maxStorageSizeMB}MB');
        return null;
      }

      // Create storage reference
      final String storagePath = 'users/$userId/recordings/$sessionId.m4a';
      final Reference storageRef = _storage.ref().child(storagePath);

      _log('Uploading to: $storagePath');

      // Upload file
      final UploadTask uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'audio/m4a',
          customMetadata: {
            'sessionId': sessionId,
            'userId': userId,
            'durationSeconds': _recordingDurationSeconds.toString(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadURL = await snapshot.ref.getDownloadURL();

      _log('Upload successful. Download URL: $downloadURL');

      // Clean up local file after successful upload
      await _deleteFile(filePath);

      return downloadURL;
    } catch (e) {
      _log('Error uploading recording: $e');
      return null;
    }
  }

  /// Stop recording and upload to Firebase Storage
  Future<String?> stopAndUpload(String userId, String sessionId) async {
    try {
      _log('Stopping recording and uploading...');

      // Stop recording
      final String? filePath = await stopRecording();

      if (filePath == null) {
        _log('Failed to stop recording');
        return null;
      }

      // Upload to Firebase Storage
      final String? downloadURL = await uploadRecording(
        filePath,
        userId,
        sessionId,
      );

      return downloadURL;
    } catch (e) {
      _log('Error in stopAndUpload: $e');
      return null;
    }
  }

  /// Delete a recording file
  Future<void> deleteRecording(String path) async {
    await _deleteFile(path);
  }

  /// Get the current recording duration
  Future<Duration> getRecordingDuration() async {
    if (_recordingStartTime == null) {
      return Duration.zero;
    }
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Start the duration timer
  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingDurationSeconds++;
      _durationController.add(_recordingDurationSeconds);

      // Auto-stop if max duration reached
      if (_recordingDurationSeconds >= maxRecordingDurationSeconds) {
        _log('Max recording duration reached. Auto-stopping...');
        stopRecording();
      }
    });
  }

  /// Delete a file from the filesystem
  Future<void> _deleteFile(String path) async {
    try {
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
        _log('Deleted file: $path');
      }
    } catch (e) {
      _log('Error deleting file: $e');
    }
  }

  /// Clean up old recordings from temporary directory
  Future<void> cleanupOldRecordings() async {
    try {
      _log('Cleaning up old recordings...');

      final Directory tempDir = await getTemporaryDirectory();
      final List<FileSystemEntity> files = tempDir.listSync();

      int deletedCount = 0;
      for (var file in files) {
        if (file is File && file.path.contains('recording_')) {
          await file.delete();
          deletedCount++;
        }
      }

      _log('Deleted $deletedCount old recordings');
    } catch (e) {
      _log('Error cleaning up old recordings: $e');
    }
  }

  /// Check if storage space is available
  Future<bool> hasStorageSpace() async {
    try {
      // This is a simplified check
      // In production, you'd want to check actual available storage
      return true;
    } catch (e) {
      _log('Error checking storage space: $e');
      return false;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _audioRecorder.closeRecorder();
    }
    _statusController.close();
    _durationController.close();
    _durationTimer?.cancel();
  }
}