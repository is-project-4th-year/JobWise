import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/interview_session_model.dart';
import 'audio_service.dart';
import 'firestore_service.dart';
import 'api_service.dart'; // NEW: Import API service

/// Manager for handling offline session queue and synchronization
class SessionManager {
  final FirestoreService _firestoreService;
  final AudioService _audioService;
  final ApiService _apiService; // NEW: Add API service
  final Connectivity _connectivity = Connectivity();

  static const String _queueKey = 'pending_sessions_queue';
  static const String _maxRetries = '3';

  SessionManager({
    required FirestoreService firestoreService,
    required AudioService audioService,
    required ApiService apiService, // NEW: Require API service
  })  : _firestoreService = firestoreService,
        _audioService = audioService,
        _apiService = apiService; // NEW: Initialize API service

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[SessionManager] $message');
    }
  }

  /// Queue a session for upload when offline
  Future<void> queueSession(
    InterviewSession session,
    String audioPath,
    String userId,
  ) async {
    try {
      _log('Queueing session for offline upload: ${session.id}');

      final prefs = await SharedPreferences.getInstance();

      // Get existing queue
      final String? queueJson = prefs.getString(_queueKey);
      final List<dynamic> queue =
          queueJson != null ? json.decode(queueJson) : [];

      // Add new session to queue
      queue.add({
        'session': session.toJson(),
        'audioPath': audioPath,
        'userId': userId,
        'retryCount': 0,
        'queuedAt': DateTime.now().toIso8601String(),
      });

      // Save updated queue
      await prefs.setString(_queueKey, json.encode(queue));

      _log('Session queued successfully. Queue length: ${queue.length}');
    } catch (e) {
      _log('Error queueing session: $e');
      rethrow;
    }
  }

  /// Get all pending sessions from the queue
  Future<List<Map<String, dynamic>>> getPendingQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? queueJson = prefs.getString(_queueKey);

      if (queueJson == null) {
        return [];
      }

      final List<dynamic> queue = json.decode(queueJson);
      return queue.cast<Map<String, dynamic>>();
    } catch (e) {
      _log('Error getting pending queue: $e');
      return [];
    }
  }

  /// Get count of pending sessions
  Future<int> getPendingSessionCount() async {
    final queue = await getPendingQueue();
    return queue.length;
  }

  /// Process the queue and upload pending sessions
  Future<void> processQueue() async {
    try {
      _log('Processing pending session queue...');

      // Check if online
      if (!await isOnline()) {
        _log('Device is offline. Skipping queue processing.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final String? queueJson = prefs.getString(_queueKey);

      if (queueJson == null) {
        _log('No pending sessions in queue');
        return;
      }

      final List<dynamic> queue = json.decode(queueJson);

      if (queue.isEmpty) {
        _log('Queue is empty');
        return;
      }

      _log('Processing ${queue.length} pending sessions...');

      final List<dynamic> remainingQueue = [];

      for (var item in queue) {
        final Map<String, dynamic> queueItem = item as Map<String, dynamic>;
        final String userId = queueItem['userId'] as String;
        final String audioPath = queueItem['audioPath'] as String;
        final int retryCount = queueItem['retryCount'] as int? ?? 0;
        final InterviewSession session = InterviewSession.fromJson(
          queueItem['session'] as Map<String, dynamic>,
        );

        _log('Processing session: ${session.id} (retry: $retryCount)');

        try {
          // Upload audio file
          final String? audioUrl = await _audioService.uploadRecording(
            audioPath,
            userId,
            session.id,
          );

          if (audioUrl == null) {
            throw Exception('Failed to upload audio');
          }

          // Update session with audio URL
          final updatedSession = session.copyWith(audioUrl: audioUrl);

          // Create session in Firestore
          await _firestoreService.createSession(userId, updatedSession);

          // NEW: Send to backend for processing
          _log('Sending session to backend for transcription...');
          final result = await _apiService.processInterview(
            audioUrl: audioUrl,
            questionId: session.questionId,
            userId: userId,
            sessionId: session.id,
          );

          if (result != null) {
            _log('Backend processing successful!');
            // The backend will update Firestore directly
          } else {
            _log('⚠️ Backend processing failed, but session saved');
          }

          _log('Session uploaded successfully: ${session.id}');
        } catch (e) {
          _log('Failed to process session ${session.id}: $e');

          // Check retry count
          if (retryCount < int.parse(_maxRetries)) {
            // Add back to queue with incremented retry count
            queueItem['retryCount'] = retryCount + 1;
            remainingQueue.add(queueItem);
            _log('Session ${session.id} will be retried (${retryCount + 1}/$_maxRetries)');
          } else {
            _log('Session ${session.id} exceeded max retries. Removing from queue.');
            // Optionally: Save to a "failed" queue for manual review
          }
        }
      }

      // Save remaining queue
      await prefs.setString(_queueKey, json.encode(remainingQueue));

      _log('Queue processing complete. Remaining items: ${remainingQueue.length}');
    } catch (e) {
      _log('Error processing queue: $e');
    }
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      return results.isNotEmpty &&
          !results.every((result) => result == ConnectivityResult.none);
    } catch (e) {
      _log('Error checking connectivity: $e');
      return false;
    }
  }

  /// Stream of connectivity changes
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((results) {
      final isConnected = results.isNotEmpty &&
          !results.every((result) => result == ConnectivityResult.none);
      _log('Connectivity changed: $isConnected');
      return isConnected;
    });
  }

  /// Get pending sessions for a specific user
  Future<List<InterviewSession>> getPendingSessions(String userId) async {
    try {
      _log('Getting pending sessions for user: $userId');

      final queue = await getPendingQueue();

      final List<InterviewSession> pendingSessions = [];

      for (var item in queue) {
        if (item['userId'] == userId) {
          final session = InterviewSession.fromJson(
            item['session'] as Map<String, dynamic>,
          );
          pendingSessions.add(session);
        }
      }

      _log('Found ${pendingSessions.length} pending sessions for user');
      return pendingSessions;
    } catch (e) {
      _log('Error getting pending sessions: $e');
      return [];
    }
  }

  /// Retry failed uploads
  Future<void> retryFailedUploads() async {
    _log('Retrying failed uploads...');
    await processQueue();
  }

  /// Clear the entire queue (use with caution)
  Future<void> clearQueue() async {
    try {
      _log('Clearing session queue...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_queueKey);
      _log('Queue cleared');
    } catch (e) {
      _log('Error clearing queue: $e');
    }
  }

  /// Remove a specific session from the queue
  Future<void> removeFromQueue(String sessionId) async {
    try {
      _log('Removing session from queue: $sessionId');

      final prefs = await SharedPreferences.getInstance();
      final String? queueJson = prefs.getString(_queueKey);

      if (queueJson == null) {
        return;
      }

      final List<dynamic> queue = json.decode(queueJson);

      // Filter out the session
      final updatedQueue = queue.where((item) {
        final session = InterviewSession.fromJson(
          item['session'] as Map<String, dynamic>,
        );
        return session.id != sessionId;
      }).toList();

      // Save updated queue
      await prefs.setString(_queueKey, json.encode(updatedQueue));

      _log('Session removed from queue');
    } catch (e) {
      _log('Error removing session from queue: $e');
    }
  }

  /// Start auto-sync when connectivity is restored
  StreamSubscription<bool>? startAutoSync() {
    _log('Starting auto-sync...');

    return connectivityStream.listen((isOnline) {
      if (isOnline) {
        _log('Device is online. Processing queue...');
        processQueue();
      } else {
        _log('Device is offline. Queue processing paused.');
      }
    });
  }
}