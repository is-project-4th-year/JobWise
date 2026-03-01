import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an interview question in the JobWise application.
///
/// Questions are role-specific and include Kenyan context, expected keywords,
/// and ideal answer structure guidance.
class Question {
  /// Unique identifier for the question
  final String id;

  /// ID of the role this question belongs to
  final String roleId;

  /// The main question text
  final String questionText;

  /// Type of question (behavioral, technical, situational, communication)
  final String questionType;

  /// Difficulty level (easy, medium, hard)
  final String difficulty;

  /// Group identifier for question variants
  final String variantGroup;

  /// Alternative phrasings of the same question
  final List<String> variants;

  /// Keywords expected in a good answer
  final List<String> expectedKeywords;

  /// Ideal structure for the answer (STAR, Technical, Situational)
  final String idealAnswerStructure;

  /// Kenyan-specific context examples
  final List<String> kenyanContextExamples;

  /// Time limit for answering in seconds
  final int timeLimitSeconds;

  /// Timestamp when the question was created
  final DateTime createdAt;

  Question({
    required this.id,
    required this.roleId,
    required this.questionText,
    required this.questionType,
    required this.difficulty,
    required this.variantGroup,
    required this.variants,
    required this.expectedKeywords,
    required this.idealAnswerStructure,
    required this.kenyanContextExamples,
    this.timeLimitSeconds = 180,
    required this.createdAt,
  });

  /// Creates a Question instance from a JSON map
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String? ?? '',
      roleId: json['role_id'] as String? ?? '',
      questionText: json['question_text'] as String? ?? '',
      questionType: json['question_type'] as String? ?? 'behavioral',
      difficulty: json['difficulty'] as String? ?? 'medium',
      variantGroup: json['variant_group'] as String? ?? '',
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      expectedKeywords: (json['expected_keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      idealAnswerStructure: json['ideal_answer_structure'] as String? ?? 'STAR',
      kenyanContextExamples: (json['kenyan_context_examples'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      timeLimitSeconds: json['time_limit_seconds'] as int? ?? 180,
      createdAt: _parseTimestamp(json['created_at']),
    );
  }

  /// Converts the Question instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_id': roleId,
      'question_text': questionText,
      'question_type': questionType,
      'difficulty': difficulty,
      'variant_group': variantGroup,
      'variants': variants,
      'expected_keywords': expectedKeywords,
      'ideal_answer_structure': idealAnswerStructure,
      'kenyan_context_examples': kenyanContextExamples,
      'time_limit_seconds': timeLimitSeconds,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a copy of this Question with the given fields replaced with new values
  Question copyWith({
    String? id,
    String? roleId,
    String? questionText,
    String? questionType,
    String? difficulty,
    String? variantGroup,
    List<String>? variants,
    List<String>? expectedKeywords,
    String? idealAnswerStructure,
    List<String>? kenyanContextExamples,
    int? timeLimitSeconds,
    DateTime? createdAt,
  }) {
    return Question(
      id: id ?? this.id,
      roleId: roleId ?? this.roleId,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      difficulty: difficulty ?? this.difficulty,
      variantGroup: variantGroup ?? this.variantGroup,
      variants: variants ?? this.variants,
      expectedKeywords: expectedKeywords ?? this.expectedKeywords,
      idealAnswerStructure:
          idealAnswerStructure ?? this.idealAnswerStructure,
      kenyanContextExamples:
          kenyanContextExamples ?? this.kenyanContextExamples,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Helper method to parse Firestore Timestamp to DateTime
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (timestamp is DateTime) {
      return timestamp;
    }
    return DateTime.now();
  }

  /// Gets a random variant of this question, or the main question text if no variants
  String getRandomVariant() {
    if (variants.isEmpty) {
      return questionText;
    }
    final allQuestions = [questionText, ...variants];
    allQuestions.shuffle();
    return allQuestions.first;
  }

  @override
  String toString() {
    return 'Question(id: $id, roleId: $roleId, type: $questionType, difficulty: $difficulty)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Question && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
