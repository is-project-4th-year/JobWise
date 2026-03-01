import 'dart:async';
import 'package:flutter/material.dart';
import '../models/interview_session_model.dart';
import '../services/firestore_service.dart';
import 'feedback_screen.dart';

/// Screen shown while the interview session is being processed
class ProcessingScreen extends StatefulWidget {
  final String sessionId;
  final String userId;

  const ProcessingScreen({
    super.key,
    required this.sessionId,
    required this.userId,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();

  StreamSubscription<InterviewSession?>? _sessionSubscription;
  String _currentStatus = 'Uploading your response...';
  int _estimatedTimeRemaining = 120; // 2 minutes
  Timer? _countdownTimer;
  bool _isCancelled = false;

  AnimationController? _animationController;

  final List<String> _statusMessages = [
    'Uploading your response...',
    'Transcribing your answer...',
    'Analyzing your response...',
    'Generating feedback...',
  ];

  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startStatusUpdates();
    _startCountdownTimer();
    _listenToSessionUpdates();
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _countdownTimer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  void _startStatusUpdates() {
    // Update status message every 30 seconds
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted || _isCancelled) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentMessageIndex = (_currentMessageIndex + 1) % _statusMessages.length;
        _currentStatus = _statusMessages[_currentMessageIndex];
      });
    });
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isCancelled) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_estimatedTimeRemaining > 0) {
          _estimatedTimeRemaining--;
        }
      });

      // Timeout after 5 minutes
      if (_estimatedTimeRemaining <= -180) {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void _listenToSessionUpdates() {
    // Poll Firestore for session status updates
    _sessionSubscription = Stream.periodic(const Duration(seconds: 5))
        .asyncMap((_) => _firestoreService.getSession(
              widget.userId,
              widget.sessionId,
            ))
        .listen((session) {
      if (!mounted || _isCancelled) return;

      if (session != null) {
        if (session.status == 'completed') {
          // Processing complete - navigate to feedback screen
          _navigateToFeedback();
        } else if (session.status == 'failed') {
          // Processing failed
          _handleProcessingError();
        }
      }
    });
  }

  void _navigateToFeedback() {
    if (!mounted || _isCancelled) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(
          sessionId: widget.sessionId,
        ),
      ),
    );
  }

  void _handleProcessingError() {
    if (!mounted || _isCancelled) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Processing Failed'),
        content: const Text(
          'There was an error processing your recording. '
          'Please try again later or contact support.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleTimeout() {
    if (!mounted || _isCancelled) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Processing Taking Longer'),
        content: const Text(
          'Your recording is taking longer to process than expected. '
          'You can check back later in your history.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isCancelled = true;
              });
              Navigator.pop(context); // Close dialog
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _cancelProcessing() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Processing?'),
        content: const Text(
          'Your recording will continue processing in the background. '
          'You can check the results in your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isCancelled = true;
              });
              Navigator.pop(context); // Close dialog
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _cancelProcessing,
            child: const Text('Leave'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Loading Indicator
              _buildLoadingAnimation(),
              const SizedBox(height: 48),

              // Status Message
              Text(
                _currentStatus,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Progress Indicator
              const LinearProgressIndicator(),
              const SizedBox(height: 24),

              // Estimated Time
              if (_estimatedTimeRemaining > 0)
                Text(
                  'Estimated time: ${_formatTime(_estimatedTimeRemaining)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                )
              else
                Text(
                  'Almost done...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              const SizedBox(height: 48),

              // Info Card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We\'re analyzing your response using AI to provide '
                        'detailed feedback on your interview performance.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    return AnimatedBuilder(
      animation: _animationController!,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animationController!.value * 2 * 3.14159,
          child: Icon(
            Icons.psychology,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes min $secs sec';
    } else {
      return '$secs seconds';
    }
  }
}
