import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a job role in the JobWise application.
///
/// Each role includes industry classification, level, and Kenyan market context
/// such as typical companies, salary ranges, and required skills.
class Role {
  /// Unique identifier for the role (e.g., "tech_software_intern")
  final String id;

  /// Industry category (Technology, Finance, Healthcare)
  final String industry;

  /// Specific department within the industry
  final String department;

  /// Experience level (Intern, Junior, Mid-Level, Senior)
  final String level;

  /// Human-readable display name
  final String displayName;

  /// List of Kenyan companies that hire for this role
  final List<String> kenyanCompanies;

  /// Number of interview questions available for this role
  final int questionCount;

  /// Average salary range in Kenyan Shillings
  final String avgSalaryKsh;

  /// Key skills required for this role
  final List<String> keySkills;

  /// Timestamp when the role was created
  final DateTime createdAt;

  /// Timestamp when the role was last updated
  final DateTime updatedAt;

  Role({
    required this.id,
    required this.industry,
    required this.department,
    required this.level,
    required this.displayName,
    required this.kenyanCompanies,
    required this.questionCount,
    required this.avgSalaryKsh,
    required this.keySkills,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a Role instance from a JSON map
  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as String? ?? '',
      industry: json['industry'] as String? ?? '',
      department: json['department'] as String? ?? '',
      level: json['level'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      kenyanCompanies: (json['kenyan_companies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      questionCount: json['question_count'] as int? ?? 0,
      avgSalaryKsh: json['avg_salary_ksh'] as String? ?? '',
      keySkills: (json['key_skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  /// Converts the Role instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'industry': industry,
      'department': department,
      'level': level,
      'display_name': displayName,
      'kenyan_companies': kenyanCompanies,
      'question_count': questionCount,
      'avg_salary_ksh': avgSalaryKsh,
      'key_skills': keySkills,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Creates a copy of this Role with the given fields replaced with new values
  Role copyWith({
    String? id,
    String? industry,
    String? department,
    String? level,
    String? displayName,
    List<String>? kenyanCompanies,
    int? questionCount,
    String? avgSalaryKsh,
    List<String>? keySkills,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Role(
      id: id ?? this.id,
      industry: industry ?? this.industry,
      department: department ?? this.department,
      level: level ?? this.level,
      displayName: displayName ?? this.displayName,
      kenyanCompanies: kenyanCompanies ?? this.kenyanCompanies,
      questionCount: questionCount ?? this.questionCount,
      avgSalaryKsh: avgSalaryKsh ?? this.avgSalaryKsh,
      keySkills: keySkills ?? this.keySkills,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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

  @override
  String toString() {
    return 'Role(id: $id, displayName: $displayName, industry: $industry, level: $level)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Role && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
