/// Represents feedback provided for an interview session.
///
/// Includes strengths, areas for improvement, missing keywords,
/// and actionable suggestions.
class Feedback {
  /// List of identified strengths in the response
  final List<String> strengths;

  /// List of areas that need improvement
  final List<String> improvements;

  /// Keywords that were expected but missing from the response
  final List<String> missingKeywords;

  /// Actionable suggestions for improvement
  final List<String> suggestions;

  Feedback({
    required this.strengths,
    required this.improvements,
    required this.missingKeywords,
    required this.suggestions,
  });

  /// Creates a Feedback instance from a JSON map
  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      strengths: (json['strengths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      improvements: (json['improvements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      missingKeywords: (json['missing_keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Converts the Feedback instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'strengths': strengths,
      'improvements': improvements,
      'missing_keywords': missingKeywords,
      'suggestions': suggestions,
    };
  }

  /// Creates a copy of this Feedback with the given fields replaced with new values
  Feedback copyWith({
    List<String>? strengths,
    List<String>? improvements,
    List<String>? missingKeywords,
    List<String>? suggestions,
  }) {
    return Feedback(
      strengths: strengths ?? this.strengths,
      improvements: improvements ?? this.improvements,
      missingKeywords: missingKeywords ?? this.missingKeywords,
      suggestions: suggestions ?? this.suggestions,
    );
  }

  /// Checks if there is any feedback available
  bool get hasContent =>
      strengths.isNotEmpty ||
      improvements.isNotEmpty ||
      missingKeywords.isNotEmpty ||
      suggestions.isNotEmpty;

  /// Gets the total number of feedback items
  int get totalItems =>
      strengths.length +
      improvements.length +
      missingKeywords.length +
      suggestions.length;

  @override
  String toString() {
    return 'Feedback(strengths: ${strengths.length}, improvements: ${improvements.length}, suggestions: ${suggestions.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Feedback &&
        _listEquals(other.strengths, strengths) &&
        _listEquals(other.improvements, improvements) &&
        _listEquals(other.missingKeywords, missingKeywords) &&
        _listEquals(other.suggestions, suggestions);
  }

  @override
  int get hashCode =>
      strengths.hashCode ^
      improvements.hashCode ^
      missingKeywords.hashCode ^
      suggestions.hashCode;

  /// Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
