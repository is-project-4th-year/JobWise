import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user's overall progress in the JobWise application.
///
/// Tracks total sessions, practice time, score trends, improvements,
/// and achievements over time.
class UserProgress {
  /// Total number of interview sessions completed
  final int totalSessions;

  /// Total practice time in minutes
  final int totalPracticeTimeMinutes;

  /// Average overall score across all sessions
  final double avgOverallScore;

  /// Trend of overall scores over recent sessions (up to last 10)
  final List<double> scoreTrend;

  /// Improvement rate as a percentage
  final double improvementRate;

  /// ID of the most frequently practiced role
  final String? mostPracticedRole;

  /// Trend of filler word counts over recent sessions
  final List<int> fillerWordTrend;

  /// List of achievement IDs earned by the user
  final List<String> achievements;

  /// Timestamp of the last session
  final DateTime? lastSessionDate;

  /// Timestamp when progress was last updated
  final DateTime updatedAt;

  UserProgress({
    this.totalSessions = 0,
    this.totalPracticeTimeMinutes = 0,
    this.avgOverallScore = 0.0,
    this.scoreTrend = const [],
    this.improvementRate = 0.0,
    this.mostPracticedRole,
    this.fillerWordTrend = const [],
    this.achievements = const [],
    this.lastSessionDate,
    required this.updatedAt,
  });

  /// Creates a UserProgress instance from a JSON map
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      totalSessions: json['total_sessions'] as int? ?? 0,
      totalPracticeTimeMinutes: json['total_practice_time_minutes'] as int? ?? 0,
      avgOverallScore: (json['avg_overall_score'] as num?)?.toDouble() ?? 0.0,
      scoreTrend: (json['score_trend'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      improvementRate: (json['improvement_rate'] as num?)?.toDouble() ?? 0.0,
      mostPracticedRole: json['most_practiced_role'] as String?,
      fillerWordTrend: (json['filler_word_trend'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      lastSessionDate: _parseTimestamp(json['last_session_date'], nullable: true),
      updatedAt: _parseTimestamp(json['updated_at']) ?? DateTime.now(),
    );
  }

  /// Converts the UserProgress instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'total_sessions': totalSessions,
      'total_practice_time_minutes': totalPracticeTimeMinutes,
      'avg_overall_score': avgOverallScore,
      'score_trend': scoreTrend,
      'improvement_rate': improvementRate,
      'most_practiced_role': mostPracticedRole,
      'filler_word_trend': fillerWordTrend,
      'achievements': achievements,
      'last_session_date': lastSessionDate != null
          ? Timestamp.fromDate(lastSessionDate!)
          : null,
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Creates a copy of this UserProgress with the given fields replaced
  UserProgress copyWith({
    int? totalSessions,
    int? totalPracticeTimeMinutes,
    double? avgOverallScore,
    List<double>? scoreTrend,
    double? improvementRate,
    String? mostPracticedRole,
    List<int>? fillerWordTrend,
    List<String>? achievements,
    DateTime? lastSessionDate,
    DateTime? updatedAt,
  }) {
    return UserProgress(
      totalSessions: totalSessions ?? this.totalSessions,
      totalPracticeTimeMinutes:
          totalPracticeTimeMinutes ?? this.totalPracticeTimeMinutes,
      avgOverallScore: avgOverallScore ?? this.avgOverallScore,
      scoreTrend: scoreTrend ?? this.scoreTrend,
      improvementRate: improvementRate ?? this.improvementRate,
      mostPracticedRole: mostPracticedRole ?? this.mostPracticedRole,
      fillerWordTrend: fillerWordTrend ?? this.fillerWordTrend,
      achievements: achievements ?? this.achievements,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper method to parse Firestore Timestamp to DateTime
  static DateTime? _parseTimestamp(dynamic timestamp, {bool nullable = false}) {
    if (timestamp == null) {
      return nullable ? null : DateTime.now();
    }
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (timestamp is DateTime) {
      return timestamp;
    }
    return nullable ? null : DateTime.now();
  }

  /// Checks if the user has any sessions completed
  bool get hasSessions => totalSessions > 0;

  /// Gets the most recent score from the trend, or 0 if no trend data
  double get latestScore => scoreTrend.isNotEmpty ? scoreTrend.last : 0.0;

  /// Gets the earliest score from the trend, or 0 if no trend data
  double get earliestScore => scoreTrend.isNotEmpty ? scoreTrend.first : 0.0;

  /// Calculates the absolute improvement from first to latest score
  double get absoluteImprovement => latestScore - earliestScore;

  /// Checks if the user is improving (positive improvement rate)
  bool get isImproving => improvementRate > 0;

  /// Checks if the user has achieved any milestones
  bool get hasAchievements => achievements.isNotEmpty;

  /// Gets practice time in hours (rounded to 1 decimal)
  double get practiceTimeHours => totalPracticeTimeMinutes / 60.0;

  /// Gets the most recent filler word count, or 0 if no data
  int get latestFillerWordCount =>
      fillerWordTrend.isNotEmpty ? fillerWordTrend.last : 0;

  /// Calculates the average filler words per session
  double get avgFillerWordsPerSession {
    if (fillerWordTrend.isEmpty) return 0.0;
    final sum = fillerWordTrend.reduce((a, b) => a + b);
    return sum / fillerWordTrend.length;
  }

  @override
  String toString() {
    return 'UserProgress(sessions: $totalSessions, avgScore: $avgOverallScore, improvementRate: $improvementRate%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProgress &&
        other.totalSessions == totalSessions &&
        other.avgOverallScore == avgOverallScore;
  }

  @override
  int get hashCode => totalSessions.hashCode ^ avgOverallScore.hashCode;
}
