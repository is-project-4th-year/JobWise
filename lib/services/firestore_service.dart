import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/role_model.dart';
import '../models/question_model.dart';
import '../models/interview_session_model.dart';
import '../models/user_progress_model.dart';

/// Service class for handling Firestore database operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Debug mode flag
  static const bool _debugMode = kDebugMode;

  void _log(String message) {
    if (_debugMode) {
      debugPrint('[FirestoreService] $message');
    }
  }

  /// Create or update user document in Firestore
  Future<void> createUserDocument({
    required User user,
    required String phoneNumber,
    bool isPhoneVerified = false,
    bool isMFAEnabled = false,
  }) async {
    try {
      _log('Creating user document for user: ${user.uid}');

      final userData = {
        'email': user.email ?? '',
        'phoneNumber': phoneNumber,
        'isPhoneVerified': isPhoneVerified,
        'isMFAEnabled': isMFAEnabled,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      _log('User document created successfully');
    } catch (e) {
      _log('Create user document error: $e');
      rethrow;
    }
  }

  /// Update user's phone verification status
  Future<void> updatePhoneVerificationStatus({
    required String userId,
    required String phoneNumber,
    required bool isVerified,
  }) async {
    try {
      _log('Updating phone verification status for user: $userId');

      await _firestore.collection('users').doc(userId).update({
        'phoneNumber': phoneNumber,
        'isPhoneVerified': isVerified,
        'phoneVerifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _log('Phone verification status updated');
    } catch (e) {
      _log('Update phone verification error: $e');
      rethrow;
    }
  }

  /// Update user's MFA enrollment status
  Future<void> updateMFAStatus({
    required String userId,
    required bool isMFAEnabled,
  }) async {
    try {
      _log('Updating MFA status for user: $userId');

      await _firestore.collection('users').doc(userId).update({
        'isMFAEnabled': isMFAEnabled,
        'mfaEnabledAt': isMFAEnabled ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _log('MFA status updated');
    } catch (e) {
      _log('Update MFA status error: $e');
      rethrow;
    }
  }

  /// Update user's last login timestamp
  Future<void> updateLastLogin({required String userId}) async {
    try {
      _log('Updating last login for user: $userId');

      await _firestore.collection('users').doc(userId).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      _log('Last login updated');
    } catch (e) {
      _log('Update last login error: $e');
      // Don't throw - this is a non-critical operation
    }
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData({required String userId}) async {
    try {
      _log('Fetching user data for user: $userId');

      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        _log('User data found');
        return doc.data();
      } else {
        _log('User data not found');
        return null;
      }
    } catch (e) {
      _log('Get user data error: $e');
      rethrow;
    }
  }

  /// Check if user's phone is verified
  Future<bool> isPhoneVerified({required String userId}) async {
    try {
      _log('Checking phone verification for user: $userId');

      final userData = await getUserData(userId: userId);
      final isVerified = userData?['isPhoneVerified'] ?? false;

      _log('Phone verified: $isVerified');
      return isVerified;
    } catch (e) {
      _log('Check phone verification error: $e');
      return false;
    }
  }

  /// Check if user has MFA enabled
  Future<bool> isMFAEnabled({required String userId}) async {
    try {
      _log('Checking MFA status for user: $userId');

      final userData = await getUserData(userId: userId);
      final mfaEnabled = userData?['isMFAEnabled'] ?? false;

      _log('MFA enabled: $mfaEnabled');
      return mfaEnabled;
    } catch (e) {
      _log('Check MFA status error: $e');
      return false;
    }
  }

  /// Get user's phone number from Firestore
  Future<String?> getUserPhoneNumber({required String userId}) async {
    try {
      _log('Fetching phone number for user: $userId');

      final userData = await getUserData(userId: userId);
      final phoneNumber = userData?['phoneNumber'] as String?;

      _log('Phone number: ${phoneNumber ?? 'not found'}');
      return phoneNumber;
    } catch (e) {
      _log('Get phone number error: $e');
      return null;
    }
  }

  /// Stream user data changes
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserData({
    required String userId,
  }) {
    _log('Starting user data stream for user: $userId');
    return _firestore.collection('users').doc(userId).snapshots();
  }

  /// Delete user data (for account deletion)
  Future<void> deleteUserData({required String userId}) async {
    try {
      _log('Deleting user data for user: $userId');

      await _firestore.collection('users').doc(userId).delete();

      _log('User data deleted successfully');
    } catch (e) {
      _log('Delete user data error: $e');
      rethrow;
    }
  }

  /// Update user profile information
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      _log('Updating user profile for user: $userId');

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) {
        updates['displayName'] = displayName;
      }

      if (photoURL != null) {
        updates['photoURL'] = photoURL;
      }

      if (additionalData != null) {
        updates.addAll(additionalData);
      }

      await _firestore.collection('users').doc(userId).update(updates);

      _log('User profile updated successfully');
    } catch (e) {
      _log('Update user profile error: $e');
      rethrow;
    }
  }

  // ==================== ROLE MANAGEMENT ====================

  /// Get all available roles across all industries
  Future<List<Role>> getAllRoles() async {
    try {
      _log('Fetching all roles...');
      QuerySnapshot snapshot = await _firestore.collection('roles').get();
      List<Role> roles = snapshot.docs
          .map((doc) => Role.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      _log('Fetched ${roles.length} roles');
      return roles;
    } catch (e) {
      _log('Error fetching roles: $e');
      rethrow;
    }
  }

  /// Get roles filtered by industry (Technology, Finance, Healthcare)
  Future<List<Role>> getRolesByIndustry(String industry) async {
    try {
      _log('Fetching roles for industry: $industry');
      QuerySnapshot snapshot = await _firestore
          .collection('roles')
          .where('industry', isEqualTo: industry)
          .get();
      List<Role> roles = snapshot.docs
          .map((doc) => Role.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      _log('Found ${roles.length} roles in $industry');
      return roles;
    } catch (e) {
      _log('Error fetching roles by industry: $e');
      rethrow;
    }
  }

  /// Get roles filtered by department
  Future<List<Role>> getRolesByDepartment(String department) async {
    try {
      _log('Fetching roles for department: $department');
      QuerySnapshot snapshot = await _firestore
          .collection('roles')
          .where('department', isEqualTo: department)
          .get();
      List<Role> roles = snapshot.docs
          .map((doc) => Role.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      _log('Found ${roles.length} roles in $department');
      return roles;
    } catch (e) {
      _log('Error fetching roles by department: $e');
      rethrow;
    }
  }

  /// Get a specific role by ID
  Future<Role?> getRoleById(String roleId) async {
    try {
      _log('Fetching role: $roleId');
      DocumentSnapshot doc =
          await _firestore.collection('roles').doc(roleId).get();
      if (doc.exists) {
        _log('Role found: $roleId');
        return Role.fromJson(doc.data() as Map<String, dynamic>);
      }
      _log('Role not found: $roleId');
      return null;
    } catch (e) {
      _log('Error fetching role by ID: $e');
      rethrow;
    }
  }

  /// Get roles filtered by experience level
  Future<List<Role>> getRolesByLevel(String level) async {
    try {
      _log('Fetching roles for level: $level');
      QuerySnapshot snapshot = await _firestore
          .collection('roles')
          .where('level', isEqualTo: level)
          .get();
      List<Role> roles = snapshot.docs
          .map((doc) => Role.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      _log('Found ${roles.length} roles at $level level');
      return roles;
    } catch (e) {
      _log('Error fetching roles by level: $e');
      rethrow;
    }
  }

  // ==================== QUESTION MANAGEMENT ====================

  /// Get all questions for a specific role
  Future<List<Question>> getQuestionsForRole(String roleId,
      {int limit = 20}) async {
    try {
      _log('Fetching questions for role: $roleId');
      QuerySnapshot snapshot = await _firestore
          .collection('questions')
          .where('role_id', isEqualTo: roleId)
          .limit(limit)
          .get();
      List<Question> questions = snapshot.docs
          .map((doc) => Question.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      _log('Found ${questions.length} questions');
      return questions;
    } catch (e) {
      _log('Error fetching questions: $e');
      rethrow;
    }
  }

  /// Get a random unseen question for a user and role
  Future<Question?> getRandomUnseenQuestion(
      String userId, String roleId) async {
    try {
      _log('Finding random unseen question for role: $roleId');

      // Get all questions for role
      List<Question> allQuestions = await getQuestionsForRole(roleId);

      if (allQuestions.isEmpty) {
        _log('No questions found for role: $roleId');
        return null;
      }

      // Get user's question history
      List<String> attemptedQuestionIds =
          await getUserQuestionHistory(userId, roleId)
              .then((sessions) => sessions.map((s) => s.questionId).toList());

      // Filter out attempted questions
      List<Question> unseenQuestions = allQuestions
          .where((q) => !attemptedQuestionIds.contains(q.id))
          .toList();

      if (unseenQuestions.isEmpty) {
        _log('No unseen questions left for role: $roleId');
        // Return a random question from all questions as fallback
        allQuestions.shuffle();
        _log('Returning random question from all questions');
        return allQuestions.first;
      }

      // Return random unseen question
      unseenQuestions.shuffle();
      _log('Found unseen question: ${unseenQuestions.first.id}');
      return unseenQuestions.first;
    } catch (e) {
      _log('Error getting random unseen question: $e');
      rethrow;
    }
  }

  /// Get a specific question by ID
  Future<Question?> getQuestionById(String questionId) async {
    try {
      _log('Fetching question: $questionId');
      QuerySnapshot snapshot = await _firestore
          .collection('questions')
          .where('id', isEqualTo: questionId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _log('Question found: $questionId');
        return Question.fromJson(
            snapshot.docs.first.data() as Map<String, dynamic>);
      }
      _log('Question not found: $questionId');
      return null;
    } catch (e) {
      _log('Error fetching question by ID: $e');
      rethrow;
    }
  }

  /// Get questions filtered by type (behavioral, technical, situational)
  Future<List<Question>> getQuestionsByType(
      String roleId, String questionType) async {
    try {
      _log('Fetching $questionType questions for role: $roleId');
      QuerySnapshot snapshot = await _firestore
          .collection('questions')
          .where('role_id', isEqualTo: roleId)
          .where('question_type', isEqualTo: questionType)
          .get();
      List<Question> questions = snapshot.docs
          .map((doc) => Question.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      _log('Found ${questions.length} $questionType questions');
      return questions;
    } catch (e) {
      _log('Error fetching questions by type: $e');
      rethrow;
    }
  }

  /// Get questions filtered by difficulty level
  Future<List<Question>> getQuestionsByDifficulty(
      String roleId, String difficulty) async {
    try {
      _log('Fetching $difficulty questions for role: $roleId');
      QuerySnapshot snapshot = await _firestore
          .collection('questions')
          .where('role_id', isEqualTo: roleId)
          .where('difficulty', isEqualTo: difficulty)
          .get();
      List<Question> questions = snapshot.docs
          .map((doc) => Question.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      _log('Found ${questions.length} $difficulty questions');
      return questions;
    } catch (e) {
      _log('Error fetching questions by difficulty: $e');
      rethrow;
    }
  }

  /// Get user's question history for a specific role
  Future<List<InterviewSession>> getUserQuestionHistory(
      String userId, String roleId) async {
    try {
      _log('Fetching question history for user: $userId, role: $roleId');
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .where('role_id', isEqualTo: roleId)
          .get();

      List<InterviewSession> sessions = snapshot.docs
          .map((doc) => InterviewSession.fromJson(
              doc.data() as Map<String, dynamic>))
          .toList();
      _log('Found ${sessions.length} previous sessions');
      return sessions;
    } catch (e) {
      _log('Error fetching question history: $e');
      rethrow;
    }
  }

  // ==================== SESSION MANAGEMENT ====================

  /// Create a new interview session
  Future<String> createSession(
      String userId, InterviewSession session) async {
    try {
      _log('Creating new session for user: $userId');
      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .add(session.toJson());
      _log('Session created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _log('Error creating session: $e');
      rethrow;
    }
  }

  /// Update an existing session
  Future<void> updateSession(
      String userId, String sessionId, Map<String, dynamic> updates) async {
    try {
      _log('Updating session: $sessionId');
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .doc(sessionId)
          .update(updates);
      _log('Session updated: $sessionId');
    } catch (e) {
      _log('Error updating session: $e');
      rethrow;
    }
  }

  /// Get a specific session
  Future<InterviewSession?> getSession(String userId, String sessionId) async {
    try {
      _log('Fetching session: $sessionId');
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .doc(sessionId)
          .get();

      if (doc.exists) {
        _log('Session found: $sessionId');
        return InterviewSession.fromJson(doc.data() as Map<String, dynamic>);
      }
      _log('Session not found: $sessionId');
      return null;
    } catch (e) {
      _log('Error fetching session: $e');
      rethrow;
    }
  }

  /// Get all sessions for a user
  Future<List<InterviewSession>> getUserSessions(String userId,
      {int limit = 50}) async {
    try {
      _log('Fetching sessions for user: $userId');
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      List<InterviewSession> sessions = snapshot.docs
          .map((doc) => InterviewSession.fromJson(
              doc.data() as Map<String, dynamic>))
          .toList();
      _log('Found ${sessions.length} sessions');
      return sessions;
    } catch (e) {
      _log('Error fetching user sessions: $e');
      rethrow;
    }
  }

  /// Get sessions filtered by role
  Future<List<InterviewSession>> getSessionsByRole(
      String userId, String roleId) async {
    try {
      _log('Fetching sessions for user: $userId, role: $roleId');
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .where('role_id', isEqualTo: roleId)
          .orderBy('created_at', descending: true)
          .get();

      List<InterviewSession> sessions = snapshot.docs
          .map((doc) => InterviewSession.fromJson(
              doc.data() as Map<String, dynamic>))
          .toList();
      _log('Found ${sessions.length} sessions for role: $roleId');
      return sessions;
    } catch (e) {
      _log('Error fetching sessions by role: $e');
      rethrow;
    }
  }

  /// Get sessions filtered by status
  Future<List<InterviewSession>> getSessionsByStatus(
      String userId, String status) async {
    try {
      _log('Fetching $status sessions for user: $userId');
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .where('status', isEqualTo: status)
          .orderBy('created_at', descending: true)
          .get();

      List<InterviewSession> sessions = snapshot.docs
          .map((doc) => InterviewSession.fromJson(
              doc.data() as Map<String, dynamic>))
          .toList();
      _log('Found ${sessions.length} $status sessions');
      return sessions;
    } catch (e) {
      _log('Error fetching sessions by status: $e');
      rethrow;
    }
  }

  /// Delete a session
  Future<void> deleteSession(String userId, String sessionId) async {
    try {
      _log('Deleting session: $sessionId');
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .doc(sessionId)
          .delete();
      _log('Session deleted: $sessionId');
    } catch (e) {
      _log('Error deleting session: $e');
      rethrow;
    }
  }

  // ==================== PROGRESS TRACKING ====================

  /// Get user's progress data
  Future<UserProgress?> getUserProgress(String userId) async {
    try {
      _log('Fetching progress for user: $userId');
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc('main')
          .get();

      if (doc.exists) {
        _log('Progress found for user: $userId');
        return UserProgress.fromJson(doc.data() as Map<String, dynamic>);
      }
      _log('No progress data found for user: $userId');
      return null;
    } catch (e) {
      _log('Error fetching user progress: $e');
      rethrow;
    }
  }

  /// Update user's progress data
  Future<void> updateProgress(String userId, UserProgress progress) async {
    try {
      _log('Updating progress for user: $userId');
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc('main')
          .set(progress.toJson(), SetOptions(merge: true));
      _log('Progress updated for user: $userId');
    } catch (e) {
      _log('Error updating progress: $e');
      rethrow;
    }
  }

  /// Calculate comprehensive progress statistics
  Future<Map<String, dynamic>> calculateProgressStats(String userId) async {
    try {
      _log('Calculating progress stats for user: $userId');
      List<InterviewSession> sessions =
          await getUserSessions(userId, limit: 100);

      if (sessions.isEmpty) {
        _log('No sessions found for stats calculation');
        return {
          'total_sessions': 0,
          'avg_score': 0.0,
          'improvement_rate': 0.0,
          'total_practice_time': 0,
        };
      }

      // Calculate average score
      double avgScore = sessions
              .map((s) => s.scores['overall'] as double)
              .reduce((a, b) => a + b) /
          sessions.length;

      // Calculate improvement rate (first 5 vs last 5)
      double improvementRate = 0.0;
      if (sessions.length >= 10) {
        List<double> firstFive = sessions
            .skip(sessions.length - 5)
            .map((s) => s.scores['overall'] as double)
            .toList();
        List<double> lastFive = sessions
            .take(5)
            .map((s) => s.scores['overall'] as double)
            .toList();

        double firstAvg = firstFive.reduce((a, b) => a + b) / 5;
        double lastAvg = lastFive.reduce((a, b) => a + b) / 5;
        improvementRate = ((lastAvg - firstAvg) / firstAvg) * 100;
      }

      // Calculate total practice time
      int totalPracticeTime = sessions
          .map((s) => s.durationSeconds)
          .reduce((a, b) => a + b);

      _log('Stats calculated: avg=$avgScore, improvement=$improvementRate%');
      return {
        'total_sessions': sessions.length,
        'avg_score': avgScore,
        'improvement_rate': improvementRate,
        'total_practice_time': totalPracticeTime,
      };
    } catch (e) {
      _log('Error calculating progress stats: $e');
      rethrow;
    }
  }

  /// Recalculate and update user progress based on all sessions
  Future<void> recalculateUserProgress(String userId) async {
    try {
      _log('Recalculating progress for user: $userId');

      final stats = await calculateProgressStats(userId);
      final sessions = await getUserSessions(userId, limit: 100);

      // Get most practiced role
      String? mostPracticedRole;
      if (sessions.isNotEmpty) {
        final roleCount = <String, int>{};
        for (var session in sessions) {
          roleCount[session.roleId] = (roleCount[session.roleId] ?? 0) + 1;
        }
        mostPracticedRole = roleCount.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      // Build score and filler word trends
      final scoreTrend = sessions.reversed
          .take(10)
          .map((s) => s.scores['overall'] as double)
          .toList();

      final fillerWordTrend = sessions.reversed
          .take(10)
          .map((s) => (s.metrics['filler_word_count'] as int?) ?? 0)
          .toList();

      // Create updated progress
      final progress = UserProgress(
        totalSessions: stats['total_sessions'] as int,
        totalPracticeTimeMinutes:
            ((stats['total_practice_time'] as int) / 60).round(),
        avgOverallScore: stats['avg_score'] as double,
        scoreTrend: scoreTrend,
        improvementRate: stats['improvement_rate'] as double,
        mostPracticedRole: mostPracticedRole,
        fillerWordTrend: fillerWordTrend,
        achievements: [], // Will be calculated separately
        lastSessionDate: sessions.isNotEmpty ? sessions.first.createdAt : null,
        updatedAt: DateTime.now(),
      );

      await updateProgress(userId, progress);
      _log('Progress recalculated and updated');
    } catch (e) {
      _log('Error recalculating progress: $e');
      rethrow;
    }
  }

  // ==================== ANALYTICS ====================

  /// Check if user has attempted a specific question
  Future<bool> hasAttemptedQuestion(String userId, String questionId) async {
    try {
      _log('Checking if question attempted: $questionId');
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .where('question_id', isEqualTo: questionId)
          .limit(1)
          .get();

      bool attempted = snapshot.docs.isNotEmpty;
      _log('Question attempted: $attempted');
      return attempted;
    } catch (e) {
      _log('Error checking question attempt: $e');
      rethrow;
    }
  }

  /// Get number of times user attempted a question
  Future<int> getQuestionAttemptCount(String userId, String questionId) async {
    try {
      _log('Counting attempts for question: $questionId');
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .where('question_id', isEqualTo: questionId)
          .get();

      int count = snapshot.docs.length;
      _log('Attempt count: $count');
      return count;
    } catch (e) {
      _log('Error getting attempt count: $e');
      rethrow;
    }
  }

  /// Get all attempts for a specific question
  Future<List<InterviewSession>> getQuestionAttempts(
      String userId, String questionId) async {
    try {
      _log('Fetching all attempts for question: $questionId');
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .where('question_id', isEqualTo: questionId)
          .orderBy('created_at', descending: true)
          .get();

      List<InterviewSession> attempts = snapshot.docs
          .map((doc) => InterviewSession.fromJson(
              doc.data() as Map<String, dynamic>))
          .toList();
      _log('Found ${attempts.length} attempts');
      return attempts;
    } catch (e) {
      _log('Error fetching question attempts: $e');
      rethrow;
    }
  }

  /// Calculate improvement metrics across all sessions
  Future<Map<String, dynamic>> getImprovementMetrics(String userId) async {
    try {
      _log('Calculating improvement metrics for user: $userId');
      List<InterviewSession> sessions =
          await getUserSessions(userId, limit: 100);

      if (sessions.isEmpty) {
        _log('No sessions for improvement metrics');
        return {
          'improvement_trend': [],
          'avg_improvement_per_session': 0.0
        };
      }

      // Calculate improvement trend
      List<double> scores = sessions.reversed
          .map((s) => s.scores['overall'] as double)
          .toList();

      // Calculate average improvement per session
      double totalImprovement = 0.0;
      for (int i = 1; i < scores.length; i++) {
        totalImprovement += scores[i] - scores[i - 1];
      }
      double avgImprovementPerSession = scores.length > 1
          ? totalImprovement / (scores.length - 1)
          : 0.0;

      _log('Improvement metrics calculated: avg=$avgImprovementPerSession per session');
      return {
        'improvement_trend': scores,
        'avg_improvement_per_session': avgImprovementPerSession,
      };
    } catch (e) {
      _log('Error calculating improvement metrics: $e');
      rethrow;
    }
  }

  /// Get performance comparison across different roles
  Future<Map<String, double>> getRolePerformanceComparison(
      String userId) async {
    try {
      _log('Calculating role performance comparison for user: $userId');
      List<InterviewSession> sessions =
          await getUserSessions(userId, limit: 100);

      if (sessions.isEmpty) {
        _log('No sessions for role comparison');
        return {};
      }

      // Group sessions by role and calculate average scores
      final roleScores = <String, List<double>>{};
      for (var session in sessions) {
        if (!roleScores.containsKey(session.roleId)) {
          roleScores[session.roleId] = [];
        }
        roleScores[session.roleId]!.add(session.scores['overall'] as double);
      }

      // Calculate averages
      final roleAverages = <String, double>{};
      roleScores.forEach((roleId, scores) {
        roleAverages[roleId] = scores.reduce((a, b) => a + b) / scores.length;
      });

      _log('Role performance calculated for ${roleAverages.length} roles');
      return roleAverages;
    } catch (e) {
      _log('Error calculating role performance: $e');
      rethrow;
    }
  }

  /// Get detailed score breakdown across all dimensions
  Future<Map<String, double>> getAverageScoreBreakdown(String userId) async {
    try {
      _log('Calculating average score breakdown for user: $userId');
      List<InterviewSession> sessions =
          await getUserSessions(userId, limit: 100);

      if (sessions.isEmpty) {
        _log('No sessions for score breakdown');
        return {};
      }

      // Calculate averages for each score dimension
      final scoreDimensions = [
        'overall',
        'relevance',
        'clarity',
        'pacing',
        'structure',
        'pronunciation'
      ];

      final averages = <String, double>{};
      for (var dimension in scoreDimensions) {
        final scores = sessions
            .map((s) => s.scores[dimension] ?? 0.0)
            .toList();
        averages[dimension] = scores.reduce((a, b) => a + b) / scores.length;
      }

      _log('Score breakdown calculated');
      return averages;
    } catch (e) {
      _log('Error calculating score breakdown: $e');
      rethrow;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Check if the database has been seeded
  Future<bool> isDatabaseSeeded() async {
    try {
      _log('Checking if database is seeded');
      DocumentSnapshot doc =
          await _firestore.collection('_metadata').doc('seeding').get();
      bool seeded = doc.exists;
      _log('Database seeded: $seeded');
      return seeded;
    } catch (e) {
      _log('Error checking database seed status: $e');
      return false;
    }
  }

  /// Get database metadata
  Future<Map<String, dynamic>?> getDatabaseMetadata() async {
    try {
      _log('Fetching database metadata');
      DocumentSnapshot doc =
          await _firestore.collection('_metadata').doc('seeding').get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      _log('Error fetching database metadata: $e');
      return null;
    }
  }
}
