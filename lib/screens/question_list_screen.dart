import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/role_model.dart';
import '../models/question_model.dart';
import '../services/firestore_service.dart';
import 'recording_screen.dart';

/// Screen for displaying questions for a selected role
class QuestionListScreen extends StatefulWidget {
  final Role role;

  const QuestionListScreen({
    super.key,
    required this.role,
  });

  @override
  State<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Question> _questions = [];
  Map<String, QuestionAttemptInfo> _attemptInfo = {};
  bool _isLoading = true;

  int _completedQuestions = 0;
  double _averageScore = 0.0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Load questions for this role
      final questions = await _firestoreService.getQuestionsForRole(
        widget.role.id,
        limit: 20,
      );

      // Load attempt history for each question
      final attemptInfo = <String, QuestionAttemptInfo>{};
      int completedCount = 0;
      double totalScore = 0.0;
      int scoredCount = 0;

      for (var question in questions) {
        final attempts = await _firestoreService.getQuestionAttempts(
          userId,
          question.id,
        );

        if (attempts.isNotEmpty) {
          // Get best attempt
          final bestAttempt = attempts.reduce((a, b) =>
              (a.overallScorePercentage > b.overallScorePercentage) ? a : b);

          final info = QuestionAttemptInfo(
            attempted: true,
            attemptCount: attempts.length,
            bestScore: bestAttempt.overallScorePercentage,
            lastAttemptDate: attempts.first.createdAt,
          );

          attemptInfo[question.id] = info;

          if (bestAttempt.overallScorePercentage >= 70) {
            completedCount++;
          }

          totalScore += bestAttempt.overallScorePercentage;
          scoredCount++;
        } else {
          attemptInfo[question.id] = QuestionAttemptInfo(
            attempted: false,
            attemptCount: 0,
            bestScore: 0,
          );
        }
      }

      setState(() {
        _questions = questions;
        _attemptInfo = attemptInfo;
        _completedQuestions = completedCount;
        _averageScore = scoredCount > 0 ? totalScore / scoredCount : 0.0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading questions: $e')),
        );
      }
    }
  }

  Future<void> _getRandomQuestion() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final question = await _firestoreService.getRandomUnseenQuestion(
        userId,
        widget.role.id,
      );

      if (question == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No unseen questions available'),
            ),
          );
        }
        return;
      }

      _navigateToRecording(question);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.role.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Random Question',
            onPressed: _getRandomQuestion,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress Info Panel
                _buildProgressPanel(),

                // Questions List
                Expanded(
                  child: _questions.isEmpty
                      ? _buildEmptyState()
                      : _buildQuestionsList(),
                ),

                // Bottom Action Button
                _buildBottomActionButton(),
              ],
            ),
    );
  }

  Widget _buildProgressPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Completed',
                '$_completedQuestions/${_questions.length}',
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatItem(
                'Average Score',
                '${_averageScore.toStringAsFixed(0)}%',
                Icons.trending_up,
                Colors.blue,
              ),
              _buildStatItem(
                'Questions',
                '${_questions.length}',
                Icons.question_answer,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No questions available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        final question = _questions[index];
        final info = _attemptInfo[question.id]!;
        return _buildQuestionCard(question, info, index + 1);
      },
    );
  }

  Widget _buildQuestionCard(
    Question question,
    QuestionAttemptInfo info,
    int questionNumber,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToRecording(question),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 120,
            maxHeight: 180,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Question Number Badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$questionNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Question Type
                  Expanded(
                    child: Text(
                      question.questionType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Attempt Badge
                  _buildAttemptBadge(info),
                ],
              ),
              const SizedBox(height: 12),

              // Question Text
              Flexible(
                child: Text(
                  question.questionText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Difficulty Badge and Stats
              Row(
                children: [
                  _buildDifficultyBadge(question.difficulty),
                  const SizedBox(width: 5.5),
                  if (info.attempted)
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Best: ${info.bestScore.toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${info.attemptCount}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToRecording(question),
                    icon: const Icon(Icons.mic, size: 8),//16
                    label: Text(
                      info.attempted ? 'Re-record' : 'Start',
                      style: const TextStyle(fontSize: 11),//13
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),//12,8
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttemptBadge(QuestionAttemptInfo info) {
    IconData icon;
    Color color;

    if (!info.attempted) {
      icon = Icons.circle_outlined;
      color = Colors.grey;
    } else if (info.bestScore >= 70) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else {
      icon = Icons.warning;
      color = Colors.orange;
    }

    return Icon(icon, color: color, size: 24);
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = Colors.green;
        break;
      case 'hard':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBottomActionButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _getRandomQuestion,
        icon: const Icon(Icons.shuffle),
        label: const Text('Get Random Question'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  void _navigateToRecording(Question question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordingScreen(
          role: widget.role,
          question: question,
        ),
      ),
    ).then((_) {
      // Reload questions when returning from recording screen
      _loadQuestions();
    });
  }
}

/// Class to hold question attempt information
class QuestionAttemptInfo {
  final bool attempted;
  final int attemptCount;
  final double bestScore;
  final DateTime? lastAttemptDate;

  QuestionAttemptInfo({
    required this.attempted,
    required this.attemptCount,
    required this.bestScore,
    this.lastAttemptDate,
  });
}
