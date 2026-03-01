import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for communicating with the JobWise FastAPI backend
class ApiService {
  // TODO: Replace YOUR_PC_IP_HERE with your actual PC IP address
  // Get it by running: ipconfig (look for IPv4 Address like 192.168.1.100)
  // Example: "http://192.168.1.100:8000"
  static const String baseUrl = "http://192.168.100.29:8000";
  
  static const Duration timeoutDuration = Duration(seconds: 120);

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ApiService] $message');
    }
  }

  /// Send audio to backend for transcription and analysis
  /// This triggers the Whisper ASR model and feedback generation
  Future<Map<String, dynamic>?> processInterview({
    required String audioUrl,
    required String questionId,
    required String userId,
    required String sessionId,
  }) async {
    try {
      _log('Sending interview for processing...');
      _log('Audio URL: $audioUrl');
      _log('Session ID: $sessionId');

      final response = await http
          .post(
            Uri.parse('$baseUrl/process'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'audio_url': audioUrl,
              'question_id': questionId,
              'user_id': userId,
              'session_id': sessionId,
            }),
          )
          .timeout(timeoutDuration);

      _log('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _log('Processing successful');
        _log('Transcription: ${data['transcription']}');
        return data;
      } else {
        _log('Processing failed: ${response.statusCode}');
        _log('Response body: ${response.body}');
        return null;
      }
    } on SocketException catch (e) {
      _log('Network error: $e');
      _log('❌ Cannot reach backend at $baseUrl');
      _log('Make sure:');
      _log('1. Backend is running (uvicorn app.main:app --host 0.0.0.0 --port 8000)');
      _log('2. PC IP is correct in baseUrl');
      _log('3. Phone and PC are on same WiFi');
      return null;
    } on TimeoutException catch (e) {
      _log('Request timeout: $e');
      _log('Backend is taking too long to respond');
      return null;
    } on http.ClientException catch (e) {
      _log('HTTP client error: $e');
      return null;
    } catch (e) {
      _log('Unexpected error: $e');
      return null;
    }
  }

  /// Check if backend is reachable and healthy
  Future<bool> checkBackendHealth() async {
    try {
      _log('Checking backend health at $baseUrl/health');
      
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _log('✅ Backend is healthy');
        return true;
      }
      
      _log('⚠️ Backend returned status ${response.statusCode}');
      return false;
    } on SocketException {
      _log('❌ Cannot reach backend - check IP and network');
      return false;
    } on TimeoutException {
      _log('❌ Backend health check timed out');
      return false;
    } catch (e) {
      _log('❌ Backend health check failed: $e');
      return false;
    }
  }
}