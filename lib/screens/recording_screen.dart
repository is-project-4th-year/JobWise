import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/role_model.dart';
import '../models/question_model.dart';
import '../models/interview_session_model.dart';
import '../models/feedback_model.dart' as model;
import '../services/audio_service.dart';
import '../services/firestore_service.dart';
import '../services/api_service.dart'; // NEW: Import API service
import '../services/session_manager.dart'; // NEW: Import SessionManager
import 'processing_screen.dart'; // NEW: Import processing screen

/// Enum to represent the recording flow state
enum RecordingState {
  preparing, // 30s countdown before recording
  idle, // Ready to record
  recording, // Currently recording
  recorded, // Recording complete, ready to submit
  uploading, // Submitting to backend
  error, // Something went wrong
}

/// Screen for recording interview answers
class RecordingScreen extends StatefulWidget {
  final Role role;
  final Question question;

  const RecordingScreen({
    super.key,
    required this.role,
    required this.question,
  });

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> with SingleTickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  final FirestoreService _firestoreService = FirestoreService();
  final ApiService _apiService = ApiService(); // NEW: Initialize API service
  late final SessionManager _sessionManager; // NEW: SessionManager

  RecordingState _recordingState = RecordingState.preparing;
  int _preparationTime = 30;
  int _recordingDurationSeconds = 0;
  String? _recordingPath;
  Timer? _preparationTimer;
  StreamSubscription<int>? _durationSubscription;

  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;

  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();

    // NEW: Initialize SessionManager with all 3 services
    _sessionManager = SessionManager(
      firestoreService: _firestoreService,
      audioService: _audioService,
      apiService: _apiService,
    );

    _loadPreparationTime();
    _setupPulseAnimation();
  }

  Future<void> _loadPreparationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final prepTime = prefs.getInt('preparation_time') ?? 30;
    setState(() {
      _preparationTime = prepTime;
    });
    _startPreparationTimer();
  }

  @override
  void dispose() {
    _preparationTimer?.cancel();
    _durationSubscription?.cancel();
    _audioPlayer?.dispose();
    _pulseController?.dispose();
    _audioService.dispose();
    super.dispose();
  }

  void _setupPulseAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  void _startPreparationTimer() {
    setState(() {
      _recordingState = RecordingState.preparing;
      // _preparationTime is already set from SharedPreferences
    });

    _preparationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _preparationTime--;
      });

      if (_preparationTime <= 0) {
        timer.cancel();
        setState(() {
          _recordingState = RecordingState.idle;
        });
        _showSnackbar('Ready to record!');
      }
    });
  }

  Future<void> _startRecording() async {
    try {
      // Check microphone permissions
      bool hasPermission = await _audioService.requestPermissions();
      if (!hasPermission) {
        _showPermissionDialog();
        return;
      }

      // Start recording
      bool started = await _audioService.startRecording();
      if (!started) {
        _showErrorDialog('Failed to start recording. Please try again.');
        return;
      }

      // Update UI state
      setState(() {
        _recordingState = RecordingState.recording;
        _recordingDurationSeconds = 0;
      });

      // Start pulse animation
      _pulseController?.repeat(reverse: true);

      // Listen to duration updates
      _durationSubscription = _audioService.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _recordingDurationSeconds = duration;
          });
        }
      });
    } catch (e) {
      _showErrorDialog('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      // Stop recording and get file path
      String? audioPath = await _audioService.stopRecording();

      if (audioPath == null) {
        if (_recordingDurationSeconds < 10) {
          _showErrorDialog(
            'Recording too short. Please record at least 10 seconds.',
          );
        } else {
          _showErrorDialog('Failed to save recording. Please try again.');
        }
        setState(() {
          _recordingState = RecordingState.idle;
        });
        return;
      }

      // Stop pulse animation
      _pulseController?.stop();
      _pulseController?.reset();

      // Update state
      setState(() {
        _recordingState = RecordingState.recorded;
        _recordingPath = audioPath;
      });

      // Enable playback
      await _loadAudioForPlayback(audioPath);
    } catch (e) {
      _showErrorDialog('Error stopping recording: $e');
      setState(() {
        _recordingState = RecordingState.idle;
      });
    }
  }

  Future<void> _cancelRecording() async {
    await _audioService.cancelRecording();
    _pulseController?.stop();
    _pulseController?.reset();
    setState(() {
      _recordingState = RecordingState.idle;
      _recordingDurationSeconds = 0;
    });
    _showSnackbar('Recording cancelled');
  }

  Future<void> _loadAudioForPlayback(String path) async {
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setFilePath(path);

      // Listen to player state
      _audioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });

          if (state.processingState == ProcessingState.completed) {
            setState(() {
              _isPlaying = false;
            });
            _audioPlayer!.seek(Duration.zero);
          }
        }
      });
    } catch (e) {
      _showErrorDialog('Error loading audio for playback: $e');
    }
  }

  Future<void> _togglePlayback() async {
    if (_audioPlayer == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer!.pause();
      } else {
        await _audioPlayer!.play();
      }
    } catch (e) {
      _showErrorDialog('Error during playback: $e');
    }
  }

  Future<void> _reRecord() async {
    // Clean up audio player
    await _audioPlayer?.dispose();
    _audioPlayer = null;

    // Delete the recording file
    if (_recordingPath != null) {
      await _audioService.deleteRecording(_recordingPath!);
    }

    // Reset state
    setState(() {
      _recordingState = RecordingState.idle;
      _recordingPath = null;
      _recordingDurationSeconds = 0;
      _isPlaying = false;
    });
  }

  // UPDATED: Now uses SessionManager with API integration
  Future<void> _submitRecording() async {
    if (_recordingPath == null) {
      _showErrorDialog('No recording to submit');
      return;
    }

    setState(() {
      _recordingState = RecordingState.uploading;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get attempt count for this question
final attemptCount = await _firestoreService.getQuestionAttemptCount(
  userId,
  widget.question.id,
);

// Create interview session object WITHOUT ID first
final session = InterviewSession(
  id: '', // Will be set after Firestore creates document
  roleId: widget.role.id,
  questionId: widget.question.id,
  audioUrl: '', // Will be set by SessionManager
  durationSeconds: _recordingDurationSeconds,
  attemptNumber: attemptCount + 1,
  createdAt: DateTime.now(),
  status: 'pending', // Initial status
  scores: {}, // Will be populated by backend
  metrics: {}, // Will be populated by backend
  feedback: model.Feedback(
    strengths: [],
    improvements: [],
    missingKeywords: [],
    suggestions: [],
  ),
);

// Check if online
final isOnline = await _sessionManager.isOnline();

if (isOnline) {
  // ONLINE: Upload directly
  debugPrint('[RecordingScreen] Device is online, uploading directly...');
  
  // Generate sessionId for filename ONLY
  final filenameSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
  
  // Upload audio
  final String? audioUrl = await _audioService.uploadRecording(
    _recordingPath!,
    userId,
    filenameSessionId,
  );

  if (audioUrl == null) {
    throw Exception('Failed to upload audio');
  }

  // Update session with audio URL
  final updatedSession = session.copyWith(audioUrl: audioUrl);

// Create session in Firestore and GET the auto-generated Document ID
final sessionId = await _firestoreService.createSession(userId, updatedSession);
debugPrint('[RecordingScreen] ✅ Got sessionId from Firestore: $sessionId');

// Update the session document to include its own ID in the 'id' field
await _firestoreService.updateSession(userId, sessionId, {'id': sessionId});
debugPrint('[RecordingScreen] ✅ Updated session.id field to: $sessionId');

// NEW: Send to backend for processing
debugPrint('[RecordingScreen] Sending to backend for transcription...');
debugPrint('[RecordingScreen] 🔥 About to call API with sessionId: $sessionId');
final result = await _apiService.processInterview(
  audioUrl: audioUrl,
  questionId: widget.question.id,
  userId: userId,
  sessionId: sessionId,
);

  if (result != null) {
    debugPrint('[RecordingScreen] Backend processing initiated successfully!');
  } else {
    debugPrint('[RecordingScreen] ⚠️ Backend processing failed, but session saved');
  }

  // Navigate to processing screen
  if (mounted) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(
          sessionId: sessionId,
          userId: userId,
        ),
      ),
    );
  }
} else {
  // OFFLINE: Queue for later upload
  debugPrint('[RecordingScreen] Device is offline, queueing session...');
  
  await _sessionManager.queueSession(
    session,
    _recordingPath!,
    userId,
  );

  // Show success message
  if (mounted) {
    _showSnackbar('Recording saved! Will upload when online.');
    Navigator.pop(context);
  }
      }
    } catch (e) {
      debugPrint('[RecordingScreen] Error submitting recording: $e');
      
      setState(() {
        _recordingState = RecordingState.error;
      });
      
      _showErrorDialog('Failed to submit recording: $e');
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
          'This app needs microphone access to record your interview answers. '
          'Please grant permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _skipQuestion() {
    showDialog(
      context: context,
      builder: (context) => Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: AlertDialog(
          title: const Text('Skip Question?'),
          content: const Text(
            'Are you sure you want to skip this question? '
            'You can practice it again later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to question list
              },
              child: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Prevent back navigation during recording or uploading
        if (_recordingState == RecordingState.recording) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Stop Recording?'),
              content: const Text(
                'Are you sure you want to stop? Your recording will be lost.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Continue Recording'),
                ),
                TextButton(
                  onPressed: () {
                    _cancelRecording();
                    Navigator.pop(context, true);
                  },
                  child: const Text('Stop'),
                ),
              ],
            ),
          );

          if (shouldPop == true && context.mounted) {
            Navigator.pop(context);
          }
        } else {
          // Allow navigation if not recording/uploading
          if (_recordingState != RecordingState.recording &&
              _recordingState != RecordingState.uploading) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Record Your Answer'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Question Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.role.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.question.questionText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: _buildMainContent(),
            ),

            // Control Section
            _buildControlSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Preparation Countdown
            if (_recordingState == RecordingState.preparing) ...[
              Text(
                'Prepare Your Answer',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '$_preparationTime',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'seconds remaining',
                style: TextStyle(fontSize: 16),
              ),
            ],

            // Microphone Icon
            if (_recordingState != RecordingState.preparing)
              _buildMicrophoneIcon(),

            const SizedBox(height: 32),

            // Status Text
            Text(
              _getStatusText(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Duration Display
            if (_recordingState == RecordingState.recording ||
                _recordingState == RecordingState.recorded)
              Text(
                _formatDuration(_recordingDurationSeconds),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _recordingState == RecordingState.recording
                      ? Colors.red
                      : Colors.grey[700],
                ),
              ),

            // Audio Player (when recorded)
            if (_recordingState == RecordingState.recorded &&
                _audioPlayer != null)
              _buildAudioPlayer(),

            // Upload Progress
            if (_recordingState == RecordingState.uploading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicrophoneIcon() {
    Color iconColor;
    Color? backgroundColor;
    double iconSize = 120;

    switch (_recordingState) {
      case RecordingState.preparing:
        iconColor = Colors.grey;
        backgroundColor = Colors.grey[200];
        break;
      case RecordingState.idle:
        iconColor = Colors.blue;
        backgroundColor = Colors.blue[50];
        break;
      case RecordingState.recording:
        iconColor = Colors.red;
        backgroundColor = Colors.red[50];
        break;
      case RecordingState.recorded:
        iconColor = Colors.green;
        backgroundColor = Colors.green[50];
        break;
      case RecordingState.uploading:
        iconColor = Colors.orange;
        backgroundColor = Colors.orange[50];
        break;
      case RecordingState.error:
        iconColor = Colors.red;
        backgroundColor = Colors.red[50];
        break;
    }

    Widget iconWidget = Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        Icons.mic_rounded,
        size: iconSize,
        color: iconColor,
      ),
    );

    // Add pulse animation when recording
    if (_recordingState == RecordingState.recording && _pulseController != null) {
      return Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController!,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController!.value * 0.2),
                child: iconWidget,
              );
            },
          ),
          const SizedBox(height: 16),
          // Recording indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'REC',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return iconWidget;
  }

  Widget _buildAudioPlayer() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          StreamBuilder<Duration>(
            stream: _audioPlayer!.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _audioPlayer!.duration ?? Duration.zero;

              return Column(
                children: [
                  Slider(
                    value: position.inMilliseconds.toDouble(),
                    max: duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      _audioPlayer!.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position.inSeconds)),
                      Text(_formatDuration(duration.inSeconds)),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: _buildControlButtons(),
    );
  }

  Widget _buildControlButtons() {
    switch (_recordingState) {
      case RecordingState.preparing:
        return Column(
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Take your time to prepare your answer...'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _skipQuestion,
              child: const Text('Skip Question'),
            ),
          ],
        );

      case RecordingState.idle:
        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: _startRecording,
              icon: const Icon(Icons.mic),
              label: const Text('Start Recording'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _skipQuestion,
              child: const Text('Skip Question'),
            ),
          ],
        );

      case RecordingState.recording:
        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: _stopRecording,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Recording'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _cancelRecording,
              child: const Text('Cancel'),
            ),
          ],
        );

      case RecordingState.recorded:
        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: _togglePlayback,
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              label: Text(_isPlaying ? 'Pause Recording' : 'Play Recording'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reRecord,
                    child: const Text('Re-record'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        );

      case RecordingState.uploading:
        return const Column(
          children: [
            Text('Uploading your recording...'),
            SizedBox(height: 16),
            LinearProgressIndicator(),
          ],
        );

      case RecordingState.error:
        return Column(
          children: [
            const Text('An error occurred. Please try again.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _recordingState = RecordingState.idle;
                });
              },
              child: const Text('Try Again'),
            ),
          ],
        );
    }
  }

  String _getStatusText() {
    switch (_recordingState) {
      case RecordingState.preparing:
        return 'Prepare your answer...';
      case RecordingState.idle:
        return 'Tap to start recording';
      case RecordingState.recording:
        return 'Recording... Speak clearly';
      case RecordingState.recorded:
        return 'Recording complete!';
      case RecordingState.uploading:
        return 'Uploading recording...';
      case RecordingState.error:
        return 'Error occurred';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}