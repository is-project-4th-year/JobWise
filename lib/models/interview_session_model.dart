import 'package:cloud_firestore/cloud_firestore.dart';
import 'feedback_model.dart';

/// Represents a single interview practice session.
///
/// Contains the user's recording, transcript, scores, metrics,
/// and comprehensive feedback.
class InterviewSession {
  /// Unique identifier for the session
  final String id;

  /// ID of the role being practiced
  final String roleId;

  /// ID of the question being answered
  final String questionId;

  /// Cloud Storage URL for the audio recording
  final String? audioUrl;

  /// Transcribed text from the audio
  final String? transcript;

  /// Duration of the recording in seconds
  final int durationSeconds;

  /// Status of the session (pending, processing, completed, failed)
  final String status;

  /// Score breakdown across different dimensions
  final Map<String, double> scores;

  /// Detailed metrics about the response
  final Map<String, dynamic> metrics;

  /// Structured feedback for the user
  final Feedback feedback;

  /// Whether this was a practice mode session
  final bool isPracticeMode;

  /// Attempt number for this specific question
  final int attemptNumber;

  /// Timestamp when the session was created
  final DateTime createdAt;

  /// Timestamp when the session was processed (if applicable)
  final DateTime? processedAt;

  InterviewSession({
    required this.id,
    required this.roleId,
    required this.questionId,
    this.audioUrl,
    this.transcript,
    this.durationSeconds = 0,
    this.status = 'pending',
    required this.scores,
    required this.metrics,
    required this.feedback,
    this.isPracticeMode = false,
    this.attemptNumber = 1,
    required this.createdAt,
    this.processedAt,
  });

  /// Creates an InterviewSession instance from a JSON map
  factory InterviewSession.fromJson(Map<String, dynamic> json) {
    return InterviewSession(
      id: json['id'] as String? ?? '',
      roleId: json['role_id'] as String? ?? '',
      questionId: json['question_id'] as String? ?? '',
      audioUrl: json['audio_url'] as String?,
      transcript: json['transcript'] as String?,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      scores: _parseScores(json['scores']),
      metrics: json['metrics'] as Map<String, dynamic>? ?? {},
      feedback: json['feedback'] != null
          ? Feedback.fromJson(json['feedback'] as Map<String, dynamic>)
          : Feedback(
              strengths: [],
              improvements: [],
              missingKeywords: [],
              suggestions: [],
            ),
      isPracticeMode: json['is_practice_mode'] as bool? ?? false,
      attemptNumber: json['attempt_number'] as int? ?? 1,
      createdAt: _parseTimestamp(json['created_at']) ?? DateTime.now(),
      processedAt: _parseTimestamp(json['processed_at'], nullable: true),
    );
  }

  /// Converts the InterviewSession instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_id': roleId,
      'question_id': questionId,
      'audio_url': audioUrl,
      'transcript': transcript,
      'duration_seconds': durationSeconds,
      'status': status,
      'scores': scores,
      'metrics': metrics,
      'feedback': feedback.toJson(),
      'is_practice_mode': isPracticeMode,
      'attempt_number': attemptNumber,
      'created_at': Timestamp.fromDate(createdAt),
      'processed_at': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
    };
  }

  /// Creates a copy of this InterviewSession with the given fields replaced
  InterviewSession copyWith({
    String? id,
    String? roleId,
    String? questionId,
    String? audioUrl,
    String? transcript,
    int? durationSeconds,
    String? status,
    Map<String, double>? scores,
    Map<String, dynamic>? metrics,
    Feedback? feedback,
    bool? isPracticeMode,
    int? attemptNumber,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    return InterviewSession(
      id: id ?? this.id,
      roleId: roleId ?? this.roleId,
      questionId: questionId ?? this.questionId,
      audioUrl: audioUrl ?? this.audioUrl,
      transcript: transcript ?? this.transcript,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      scores: scores ?? this.scores,
      metrics: metrics ?? this.metrics,
      feedback: feedback ?? this.feedback,
      isPracticeMode: isPracticeMode ?? this.isPracticeMode,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  /// Helper method to parse scores map
  static Map<String, double> _parseScores(dynamic scoresData) {
    if (scoresData == null) {
      return {
        'overall': 0.0,
        'relevance': 0.0,
        'clarity': 0.0,
        'pacing': 0.0,
        'structure': 0.0,
        'pronunciation': 0.0,
      };
    }

    final Map<String, double> scores = {};
    if (scoresData is Map) {
      scoresData.forEach((key, value) {
        scores[key.toString()] = (value as num?)?.toDouble() ?? 0.0;
      });
    }

    // Ensure all required score fields exist
    scores.putIfAbsent('overall', () => 0.0);
    scores.putIfAbsent('relevance', () => 0.0);
    scores.putIfAbsent('clarity', () => 0.0);
    scores.putIfAbsent('pacing', () => 0.0);
    scores.putIfAbsent('structure', () => 0.0);
    scores.putIfAbsent('pronunciation', () => 0.0);

    return scores;
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

  /// Gets the overall score as a percentage (0-100)
  double get overallScorePercentage => scores['overall'] ?? 0.0;

  /// Checks if the session has been processed
  bool get isProcessed => status == 'completed' && processedAt != null;

  /// Checks if the session is still pending processing
  bool get isPending => status == 'pending';

  /// Checks if the session processing failed
  bool get hasFailed => status == 'failed';

  /// Gets the words per minute if available
  double? get wordsPerMinute {
    final wpm = metrics['words_per_minute'];
    return wpm != null ? (wpm as num).toDouble() : null;
  }

  /// Gets the filler word count if available
  int? get fillerWordCount {
    final count = metrics['filler_word_count'];
    return count != null ? count as int : null;
  }

  @override
  String toString() {
    return 'InterviewSession(id: $id, roleId: $roleId, status: $status, overallScore: ${scores['overall']})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InterviewSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
