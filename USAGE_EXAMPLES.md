# JobWise Firestore Usage Examples

Quick reference for using the FirestoreService in your app.

## Initialization

```dart
import 'package:jobwise_app/services/firestore_service.dart';

final firestoreService = FirestoreService();
```

---

## Role Management

### Get All Roles

```dart
final roles = await firestoreService.getAllRoles();
// Returns: List<Role> with 15 roles
```

### Get Roles by Industry

```dart
// Technology roles
final techRoles = await firestoreService.getRolesByIndustry('Technology');

// Finance roles
final financeRoles = await firestoreService.getRolesByIndustry('Finance');

// Healthcare roles
final healthRoles = await firestoreService.getRolesByIndustry('Healthcare');
```

### Get Roles by Level

```dart
// Entry-level roles
final internRoles = await firestoreService.getRolesByLevel('Intern');

// Junior roles
final juniorRoles = await firestoreService.getRolesByLevel('Junior');

// Mid-level roles
final midRoles = await firestoreService.getRolesByLevel('Mid-Level');

// Senior roles
final seniorRoles = await firestoreService.getRolesByLevel('Senior');
```

### Get Specific Role

```dart
final role = await firestoreService.getRoleById('tech_software_intern');

if (role != null) {
  print('Role: ${role.displayName}');
  print('Companies: ${role.kenyanCompanies.join(', ')}');
  print('Salary: ${role.avgSalaryKsh}');
  print('Skills: ${role.keySkills.join(', ')}');
}
```

---

## Question Management

### Get Questions for a Role

```dart
final questions = await firestoreService.getQuestionsForRole(
  'tech_software_intern',
  limit: 20,
);

for (var question in questions) {
  print('Q: ${question.questionText}');
  print('Type: ${question.questionType}');
  print('Difficulty: ${question.difficulty}');
}
```

### Get Random Unseen Question

```dart
final userId = 'current_user_id';
final roleId = 'tech_software_intern';

final question = await firestoreService.getRandomUnseenQuestion(userId, roleId);

if (question != null) {
  print('Question: ${question.questionText}');
  print('Time limit: ${question.timeLimitSeconds}s');
  print('Expected keywords: ${question.expectedKeywords.join(', ')}');
  print('Kenyan examples: ${question.kenyanContextExamples.join(', ')}');
}
```

### Get Questions by Type

```dart
// Behavioral questions
final behavioralQuestions = await firestoreService.getQuestionsByType(
  'tech_software_intern',
  'behavioral',
);

// Technical questions
final technicalQuestions = await firestoreService.getQuestionsByType(
  'tech_software_intern',
  'technical',
);

// Situational questions
final situationalQuestions = await firestoreService.getQuestionsByType(
  'tech_software_intern',
  'situational',
);
```

### Get Questions by Difficulty

```dart
// Easy questions
final easyQuestions = await firestoreService.getQuestionsByDifficulty(
  'tech_software_intern',
  'easy',
);

// Medium questions
final mediumQuestions = await firestoreService.getQuestionsByDifficulty(
  'tech_software_intern',
  'medium',
);

// Hard questions
final hardQuestions = await firestoreService.getQuestionsByDifficulty(
  'tech_software_intern',
  'hard',
);
```

---

## Session Management

### Create New Session

```dart
import 'package:jobwise_app/models/interview_session_model.dart';
import 'package:jobwise_app/models/feedback_model.dart';

final session = InterviewSession(
  id: '', // Will be auto-generated
  roleId: 'tech_software_intern',
  questionId: 'question_123',
  audioUrl: null, // Set after upload
  transcript: null, // Set after processing
  durationSeconds: 0,
  status: 'pending',
  scores: {},
  metrics: {},
  feedback: Feedback(
    strengths: [],
    improvements: [],
    missingKeywords: [],
    suggestions: [],
  ),
  isPracticeMode: false,
  attemptNumber: 1,
  createdAt: DateTime.now(),
);

final sessionId = await firestoreService.createSession(userId, session);
print('Session created: $sessionId');
```

### Update Session with Results

```dart
await firestoreService.updateSession(
  userId,
  sessionId,
  {
    'status': 'completed',
    'transcript': 'User's transcribed answer...',
    'duration_seconds': 95,
    'scores': {
      'overall': 78.0,
      'relevance': 75.0,
      'clarity': 82.0,
      'pacing': 90.0,
      'structure': 65.0,
      'pronunciation': 80.0,
    },
    'metrics': {
      'word_count': 142,
      'words_per_minute': 145.0,
      'filler_word_count': 8,
      'filler_words': {'um': 3, 'uh': 2, 'like': 3},
    },
    'feedback': {
      'strengths': ['Good pacing', 'Clear structure'],
      'improvements': ['Reduce filler words', 'Add specific metrics'],
      'missing_keywords': ['result', 'impact'],
      'suggestions': ['Include specific outcomes'],
    },
    'processed_at': FieldValue.serverTimestamp(),
  },
);
```

### Get User Sessions

```dart
// Get recent sessions
final recentSessions = await firestoreService.getUserSessions(
  userId,
  limit: 10,
);

// Get sessions for specific role
final roleSessions = await firestoreService.getSessionsByRole(
  userId,
  'tech_software_intern',
);

// Get completed sessions
final completedSessions = await firestoreService.getSessionsByStatus(
  userId,
  'completed',
);

// Get pending sessions
final pendingSessions = await firestoreService.getSessionsByStatus(
  userId,
  'pending',
);
```

### Get Specific Session

```dart
final session = await firestoreService.getSession(userId, sessionId);

if (session != null) {
  print('Status: ${session.status}');
  print('Overall score: ${session.overallScorePercentage}%');
  print('Duration: ${session.durationSeconds}s');
  print('WPM: ${session.wordsPerMinute}');
  print('Filler words: ${session.fillerWordCount}');
}
```

---

## Progress Tracking

### Get User Progress

```dart
final progress = await firestoreService.getUserProgress(userId);

if (progress != null) {
  print('Total sessions: ${progress.totalSessions}');
  print('Practice time: ${progress.practiceTimeHours.toStringAsFixed(1)} hours');
  print('Average score: ${progress.avgOverallScore.toStringAsFixed(1)}%');
  print('Improvement rate: ${progress.improvementRate.toStringAsFixed(1)}%');
  print('Most practiced: ${progress.mostPracticedRole}');
  print('Latest score: ${progress.latestScore}');
  print('Is improving: ${progress.isImproving}');
}
```

### Update Progress Manually

```dart
import 'package:jobwise_app/models/user_progress_model.dart';

final newProgress = UserProgress(
  totalSessions: 15,
  totalPracticeTimeMinutes: 450,
  avgOverallScore: 76.5,
  scoreTrend: [65.0, 70.0, 72.0, 75.0, 78.0],
  improvementRate: 15.2,
  mostPracticedRole: 'tech_software_intern',
  fillerWordTrend: [12, 10, 8, 7, 6],
  achievements: ['first_session', '10_sessions', 'improvement_streak'],
  lastSessionDate: DateTime.now(),
  updatedAt: DateTime.now(),
);

await firestoreService.updateProgress(userId, newProgress);
```

### Recalculate Progress

```dart
// Automatically recalculate all progress metrics from sessions
await firestoreService.recalculateUserProgress(userId);

// Then get updated progress
final updatedProgress = await firestoreService.getUserProgress(userId);
```

### Calculate Progress Statistics

```dart
final stats = await firestoreService.calculateProgressStats(userId);

print('Total sessions: ${stats['total_sessions']}');
print('Average score: ${stats['avg_score']}');
print('Improvement rate: ${stats['improvement_rate']}%');
print('Total practice time: ${stats['total_practice_time']}s');
```

---

## Analytics

### Check Question Attempt

```dart
final hasAttempted = await firestoreService.hasAttemptedQuestion(
  userId,
  'question_123',
);

if (hasAttempted) {
  print('User has already attempted this question');
}
```

### Get Question Attempt Count

```dart
final attemptCount = await firestoreService.getQuestionAttemptCount(
  userId,
  'question_123',
);

print('Question attempted $attemptCount times');
```

### Get All Attempts for Question

```dart
final attempts = await firestoreService.getQuestionAttempts(
  userId,
  'question_123',
);

for (var i = 0; i < attempts.length; i++) {
  print('Attempt ${i + 1}: ${attempts[i].scores['overall']}%');
}
```

### Get Improvement Metrics

```dart
final improvementMetrics = await firestoreService.getImprovementMetrics(userId);

List<double> scores = improvementMetrics['improvement_trend'];
double avgImprovement = improvementMetrics['avg_improvement_per_session'];

print('Score progression: ${scores.join(' → ')}');
print('Average improvement per session: ${avgImprovement.toStringAsFixed(1)}%');
```

### Get Role Performance Comparison

```dart
final rolePerformance = await firestoreService.getRolePerformanceComparison(userId);

rolePerformance.forEach((roleId, avgScore) {
  print('$roleId: ${avgScore.toStringAsFixed(1)}%');
});

// Find best performing role
final bestRole = rolePerformance.entries
    .reduce((a, b) => a.value > b.value ? a : b);
print('Best role: ${bestRole.key} (${bestRole.value.toStringAsFixed(1)}%)');
```

### Get Average Score Breakdown

```dart
final scoreBreakdown = await firestoreService.getAverageScoreBreakdown(userId);

print('Overall: ${scoreBreakdown['overall']?.toStringAsFixed(1)}%');
print('Relevance: ${scoreBreakdown['relevance']?.toStringAsFixed(1)}%');
print('Clarity: ${scoreBreakdown['clarity']?.toStringAsFixed(1)}%');
print('Pacing: ${scoreBreakdown['pacing']?.toStringAsFixed(1)}%');
print('Structure: ${scoreBreakdown['structure']?.toStringAsFixed(1)}%');
print('Pronunciation: ${scoreBreakdown['pronunciation']?.toStringAsFixed(1)}%');
```

---

## Database Seeding

### Seed Database on App Initialization

```dart
import 'package:jobwise_app/scripts/seed_firestore.dart';

Future<void> initializeApp() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Check if seeding needed
  final firestoreService = FirestoreService();
  final isSeeded = await firestoreService.isDatabaseSeeded();

  if (!isSeeded) {
    final seeder = FirestoreSeeder();

    await seeder.seedDatabase(
      onProgress: (message) {
        print(message);
      },
    );
  }
}
```

### Manual Reseed (Admin Only)

```dart
// In app settings for admins
Future<void> reseedDatabase(BuildContext context) async {
  final seeder = FirestoreSeeder();

  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Reseeding database...'),
        ],
      ),
    ),
  );

  await seeder.seedDatabase(
    onProgress: (message) {
      debugPrint(message);
    },
  );

  Navigator.pop(context);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Database reseeded successfully!')),
  );
}
```

---

## Error Handling

### Best Practices

```dart
try {
  final roles = await firestoreService.getAllRoles();
  // Use roles
} on FirebaseException catch (e) {
  // Handle Firebase-specific errors
  print('Firebase error: ${e.code} - ${e.message}');

  if (e.code == 'permission-denied') {
    // User not authenticated or no permission
  } else if (e.code == 'unavailable') {
    // Network error or Firestore down
  }
} catch (e) {
  // Handle other errors
  print('Error: $e');
}
```

### Check Authentication

```dart
import 'package:firebase_auth/firebase_auth.dart';

final currentUser = FirebaseAuth.instance.currentUser;

if (currentUser != null) {
  // User is authenticated, safe to use Firestore
  final roles = await firestoreService.getAllRoles();
} else {
  // Redirect to login
  print('User not authenticated');
}
```

---

## Performance Tips

### Use Pagination

```dart
// Limit results for better performance
final sessions = await firestoreService.getUserSessions(
  userId,
  limit: 20, // Load only 20 sessions
);
```

### Cache Frequently Accessed Data

```dart
// Cache roles locally
class RoleCache {
  static List<Role>? _cachedRoles;
  static DateTime? _cacheTime;

  static Future<List<Role>> getRoles(FirestoreService service) async {
    final now = DateTime.now();

    // Cache for 1 hour
    if (_cachedRoles != null &&
        _cacheTime != null &&
        now.difference(_cacheTime!).inHours < 1) {
      return _cachedRoles!;
    }

    _cachedRoles = await service.getAllRoles();
    _cacheTime = now;
    return _cachedRoles!;
  }
}
```

### Use Streams for Real-time Updates

```dart
// For real-time progress updates
Stream<UserProgress?> watchUserProgress(String userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('progress')
      .doc('main')
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists) {
      return UserProgress.fromJson(snapshot.data() as Map<String, dynamic>);
    }
    return null;
  });
}

// Usage in widget
StreamBuilder<UserProgress?>(
  stream: watchUserProgress(userId),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final progress = snapshot.data!;
      return Text('Score: ${progress.avgOverallScore}%');
    }
    return CircularProgressIndicator();
  },
)
```

---

## Testing

### Mock FirestoreService for Tests

```dart
class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  group('Role Management Tests', () {
    late MockFirestoreService mockService;

    setUp(() {
      mockService = MockFirestoreService();
    });

    test('getAllRoles returns list of roles', () async {
      when(mockService.getAllRoles()).thenAnswer(
        (_) async => [
          Role(
            id: 'test_role',
            industry: 'Technology',
            // ... other fields
          ),
        ],
      );

      final roles = await mockService.getAllRoles();
      expect(roles.length, 1);
      expect(roles.first.id, 'test_role');
    });
  });
}
```

---

**For more details, see [FIRESTORE_SETUP.md](FIRESTORE_SETUP.md)**
