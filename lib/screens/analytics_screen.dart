import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  String? error;

  // Stats
  int totalSessions = 0;
  double averageScore = 0.0;
  Map<String, double> categoryAverages = {};
  List<Map<String, dynamic>> recentSessions = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'Not authenticated';

      // Get all sessions (filter completed sessions in code to avoid index requirement)
      final sessionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .orderBy('createdAt', descending: true)
          .get();

      // Filter completed sessions in code
      final completedSessions = sessionsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .toList();

      if (completedSessions.isEmpty) {
        setState(() {
          isLoading = false;
          totalSessions = 0;
        });
        return;
      }

      // Calculate stats
      final sessions = completedSessions;
      totalSessions = sessions.length;

      double totalOverallScore = 0;
      Map<String, List<double>> categoryScores = {
        'clarity': [],
        'pacing': [],
        'structure': [],
        'confidence': [],
      };

      List<Map<String, dynamic>> sessionsData = [];

      for (var doc in sessions) {
        final data = doc.data();
        final scores = data['scores'] as Map<String, dynamic>? ?? {};
        
        // Overall score
        final overall = (scores['overall'] ?? 0).toDouble();
        totalOverallScore += overall;

        // Category scores
        categoryScores['clarity']!.add((scores['clarity'] ?? 0).toDouble());
        categoryScores['pacing']!.add((scores['pacing'] ?? 0).toDouble());
        categoryScores['structure']!.add((scores['structure'] ?? 0).toDouble());
        categoryScores['confidence']!.add((scores['confidence'] ?? 0).toDouble());

        // Recent sessions (top 5)
        if (sessionsData.length < 5) {
          sessionsData.add({
            'id': doc.id,
            'overallScore': overall.toInt(),
            'createdAt': data['createdAt'],
            'questionId': data['questionId'],
          });
        }
      }

      // Calculate averages
      averageScore = totalOverallScore / totalSessions;

      categoryAverages = {
        'clarity': _calculateAverage(categoryScores['clarity']!),
        'pacing': _calculateAverage(categoryScores['pacing']!),
        'structure': _calculateAverage(categoryScores['structure']!),
        'confidence': _calculateAverage(categoryScores['confidence']!),
      };

      setState(() {
        recentSessions = sessionsData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  double _calculateAverage(List<double> scores) {
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'clarity':
        return '🎤';
      case 'pacing':
        return '⏱️';
      case 'structure':
        return '📝';
      case 'confidence':
        return '💪';
      default:
        return '📊';
    }
  }

  String _getCategoryLabel(String category) {
    return category[0].toUpperCase() + category.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Error loading analytics'),
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadAnalytics,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (totalSessions == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No Data Yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete your first interview to see analytics',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Start Practicing'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _loadAnalytics();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Sessions',
                      totalSessions.toString(),
                      Icons.assessment,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Average Score',
                      '${averageScore.toInt()}%',
                      Icons.trending_up,
                      _getScoreColor(averageScore.toInt()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Category Breakdown
              const Text(
                'Performance by Category',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...categoryAverages.entries.map((entry) => 
                _buildCategoryRow(entry.key, entry.value)
              ),

              const SizedBox(height: 24),

              // Best & Worst
              Row(
                children: [
                  Expanded(child: _buildBestWorstCard(true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildBestWorstCard(false)),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Sessions
              const Text(
                'Recent Sessions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (recentSessions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No recent sessions'),
                  ),
                )
              else
                ...recentSessions.map((session) => _buildSessionCard(session)),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String category, double score) {
    final percentage = (score / 100);
    final color = _getScoreColor(score.toInt());

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(_getCategoryIcon(category), style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    _getCategoryLabel(category),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                '${score.toInt()}%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestWorstCard(bool isBest) {
    // Find best/worst category
    if (categoryAverages.isEmpty) return const SizedBox();

    final sortedCategories = categoryAverages.entries.toList()
      ..sort((a, b) => isBest 
          ? b.value.compareTo(a.value) 
          : a.value.compareTo(b.value));

    final category = sortedCategories.first;
    final score = category.value.toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBest ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBest ? Colors.green[300]! : Colors.orange[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isBest ? Icons.star : Icons.trending_down,
                color: isBest ? Colors.green[700] : Colors.orange[700],
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                isBest ? 'Strongest' : 'Improve',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isBest ? Colors.green[700] : Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(_getCategoryIcon(category.key), style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCategoryLabel(category.key),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$score%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isBest ? Colors.green[700] : Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final score = session['overallScore'] as int;
    final timestamp = (session['createdAt'] as Timestamp?)?.toDate();
    final timeAgo = timestamp != null ? _getTimeAgo(timestamp) : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getScoreColor(score).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$score',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(score),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interview Session',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}