# JobWise Firestore Database Setup Guide

This guide provides complete instructions for setting up the Firestore database for the JobWise interview preparation application.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Database Structure](#database-structure)
4. [Setup Instructions](#setup-instructions)
5. [Data Seeding](#data-seeding)
6. [Security Rules Deployment](#security-rules-deployment)
7. [Testing](#testing)
8. [Troubleshooting](#troubleshooting)

---

## Overview

JobWise uses Firebase Firestore as its primary database. The database includes:

- **15 roles** across 3 industries (Technology, Finance, Healthcare)
- **300 questions** with Kenyan market context (20 per role)
- **User sessions** tracking for interview practice
- **Progress tracking** for user improvement metrics

### Industries & Roles

**Technology:**
- Software Development Intern
- Junior Software Engineer
- Mid-Level Data Analyst
- Junior IT Support Specialist
- Senior Product Manager

**Finance:**
- Financial Analyst Intern
- Junior Accountant
- Mid-Level Risk Analyst
- Senior Relationship Manager
- Mid-Level Internal Auditor

**Healthcare:**
- Junior Registered Nurse
- Mid-Level Laboratory Technician
- Junior Pharmacist
- Mid-Level Health Records Administrator
- Mid-Level Public Health Officer

---

## Prerequisites

Before setting up the database, ensure you have:

1. **Firebase Project** created at [Firebase Console](https://console.firebase.google.com)
2. **Firebase CLI** installed:
   ```bash
   npm install -g firebase-tools
   ```
3. **Firestore enabled** in your Firebase project
4. **Firebase Admin SDK** credentials (for server-side operations)
5. **Flutter environment** set up with Firebase FlutterFire configured

---

## Database Structure

### Collections

#### 1. `roles` Collection
Stores job role information.

**Document Structure:**
```dart
{
  "id": "tech_software_intern",
  "industry": "Technology",
  "department": "Software Development",
  "level": "Intern",
  "display_name": "Software Development Intern",
  "kenyan_companies": ["Safaricom", "Andela", "M-KOPA", "Cellulant"],
  "question_count": 20,
  "avg_salary_ksh": "30000-50000",
  "key_skills": ["Programming", "Problem-solving", "Communication"],
  "created_at": Timestamp,
  "updated_at": Timestamp
}
```

#### 2. `questions` Collection
Stores interview questions with Kenyan context.

**Document Structure:**
```dart
{
  "id": "auto_generated_id",
  "role_id": "tech_software_intern",
  "question_text": "Tell me about a challenging project...",
  "question_type": "behavioral",
  "difficulty": "medium",
  "variant_group": "project_experience",
  "variants": ["Alternative question 1", "Alternative question 2"],
  "expected_keywords": ["situation", "challenge", "solution", "result"],
  "ideal_answer_structure": "STAR",
  "kenyan_context_examples": ["M-Pesa integration", "Matatu system"],
  "time_limit_seconds": 180,
  "created_at": Timestamp
}
```

#### 3. `users/{userId}/sessions` Subcollection
Stores user interview practice sessions.

**Document Structure:**
```dart
{
  "id": "session_id",
  "role_id": "tech_software_intern",
  "question_id": "question_id",
  "audio_url": "gs://bucket/audio.wav",
  "transcript": "transcribed text",
  "duration_seconds": 95,
  "status": "completed",
  "scores": {
    "overall": 78.0,
    "relevance": 75.0,
    "clarity": 82.0,
    "pacing": 90.0,
    "structure": 65.0,
    "pronunciation": 80.0
  },
  "metrics": {
    "word_count": 142,
    "words_per_minute": 145.0,
    "filler_word_count": 8,
    "filler_words": {"um": 3, "uh": 2, "like": 3}
  },
  "feedback": {
    "strengths": ["Good pacing", "Clear structure"],
    "improvements": ["Reduce filler words"],
    "missing_keywords": ["result", "impact"],
    "suggestions": ["Include specific outcomes"]
  },
  "is_practice_mode": false,
  "attempt_number": 1,
  "created_at": Timestamp,
  "processed_at": Timestamp
}
```

#### 4. `users/{userId}/progress` Subcollection
Stores user progress tracking data.

**Document Structure:**
```dart
{
  "total_sessions": 15,
  "total_practice_time_minutes": 450,
  "avg_overall_score": 76.5,
  "score_trend": [65.0, 70.0, 72.0, 75.0, 78.0],
  "improvement_rate": 15.2,
  "most_practiced_role": "tech_software_intern",
  "filler_word_trend": [12, 10, 8, 7, 6],
  "achievements": ["first_session", "10_sessions"],
  "last_session_date": Timestamp,
  "updated_at": Timestamp
}
```

#### 5. `_metadata` Collection
Stores database metadata and seeding status.

---

## Setup Instructions

### Step 1: Firebase Project Configuration

1. Navigate to [Firebase Console](https://console.firebase.google.com)
2. Select your JobWise project
3. Go to **Firestore Database**
4. Click **Create Database**
5. Choose **Production mode** (security rules will be added later)
6. Select your preferred location (e.g., `eur3` for Europe Multi-Region)

### Step 2: FlutterFire Configuration

Ensure your Flutter app is connected to Firebase:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your Flutter app
flutterfire configure
```

### Step 3: Add Dependencies

Ensure these packages are in your `pubspec.yaml`:

```yaml
dependencies:
  cloud_firestore: ^4.13.0
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
```

### Step 4: Initialize Firebase in Your App

In `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}
```

---

## Data Seeding

### Method 1: Automatic Seeding (Recommended)

The app automatically seeds the database on first launch if no data exists.

**Implementation:**

1. The seeding script is located at `lib/scripts/seed_firestore.dart`
2. Call the seeder from your app initialization:

```dart
import 'package:jobwise_app/scripts/seed_firestore.dart';
import 'package:jobwise_app/services/firestore_service.dart';

Future<void> initializeDatabase() async {
  final firestoreService = FirestoreService();
  final seeder = FirestoreSeeder();

  // Check if already seeded
  bool isSeeded = await firestoreService.isDatabaseSeeded();

  if (!isSeeded) {
    print('Database not seeded. Starting seeding process...');

    await seeder.seedDatabase(
      onProgress: (message) {
        print(message);
      },
    );

    print('Database seeding completed!');
  } else {
    print('Database already seeded.');
  }
}
```

3. Call `initializeDatabase()` in your app's startup logic:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Seed database if needed
  await initializeDatabase();

  runApp(MyApp());
}
```

### Method 2: Manual Seeding via Admin Script

For server-side seeding or manual control, create a standalone script:

**Create `seed_database.dart` in your project root:**

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:jobwise_app/scripts/seed_firestore.dart';

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp();

  // Run seeder
  final seeder = FirestoreSeeder();

  print('Starting database seeding...');

  await seeder.seedDatabase(
    onProgress: (message) {
      print(message);
    },
  );

  print('Seeding complete!');
}
```

**Run the script:**

```bash
dart seed_database.dart
```

### Method 3: Manual Reseed Option in Settings

Add a manual reseed button in your app settings for admins:

```dart
ElevatedButton(
  onPressed: () async {
    final seeder = FirestoreSeeder();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Seeding database...'),
          ],
        ),
      ),
    );

    await seeder.seedDatabase(
      onProgress: (message) {
        print(message);
      },
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Database seeded successfully!')),
    );
  },
  child: Text('Reseed Database'),
)
```

---

## Security Rules Deployment

### Step 1: Review Security Rules

The security rules file is located at `firestore.rules` in the project root.

**Key Security Features:**
- Users can only access their own data
- Roles and questions are read-only for all authenticated users
- Write access to roles/questions restricted to admins (Firebase Console only)
- Session and progress data is user-isolated

### Step 2: Deploy Security Rules

**Using Firebase CLI:**

1. Login to Firebase:
   ```bash
   firebase login
   ```

2. Initialize Firebase in your project (if not already done):
   ```bash
   firebase init firestore
   ```

3. Select your Firebase project

4. When prompted for Firestore rules file, use `firestore.rules`

5. Deploy the rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

6. Verify deployment:
   ```bash
   firebase firestore:rules:get
   ```

### Step 3: Test Security Rules

**Test that users can only access their own data:**

```dart
// This should succeed
await FirebaseFirestore.instance
    .collection('users')
    .doc(currentUserId)
    .collection('sessions')
    .get();

// This should fail (access denied)
await FirebaseFirestore.instance
    .collection('users')
    .doc(otherUserId)  // Different user ID
    .collection('sessions')
    .get();
```

**Test that users can read roles and questions:**

```dart
// This should succeed for authenticated users
await FirebaseFirestore.instance
    .collection('roles')
    .get();

await FirebaseFirestore.instance
    .collection('questions')
    .get();
```

---

## Testing

### Step 1: Verify Data Seeding

```dart
import 'package:jobwise_app/services/firestore_service.dart';

Future<void> testSeeding() async {
  final service = FirestoreService();

  // Test roles
  final roles = await service.getAllRoles();
  print('Total roles: ${roles.length}');  // Should be 15

  // Test questions
  final questions = await service.getQuestionsForRole('tech_software_intern');
  print('Questions for role: ${questions.length}');  // Should be 20

  // Test metadata
  final metadata = await service.getDatabaseMetadata();
  print('Seeding metadata: $metadata');
}
```

### Step 2: Test FirestoreService Methods

```dart
Future<void> testFirestoreService() async {
  final service = FirestoreService();
  final userId = 'test_user_id';

  // Test getting roles by industry
  final techRoles = await service.getRolesByIndustry('Technology');
  print('Tech roles: ${techRoles.length}');  // Should be 5

  // Test getting random unseen question
  final question = await service.getRandomUnseenQuestion(
    userId,
    'tech_software_intern',
  );
  print('Random question: ${question?.questionText}');

  // Test progress calculation
  final stats = await service.calculateProgressStats(userId);
  print('Progress stats: $stats');
}
```

### Step 3: Test Models Serialization

```dart
import 'package:jobwise_app/models/role_model.dart';

void testModels() {
  // Test Role model
  final roleJson = {
    'id': 'test_role',
    'industry': 'Technology',
    'display_name': 'Test Role',
    // ... other fields
  };

  final role = Role.fromJson(roleJson);
  final serialized = role.toJson();

  print('Role serialization: ${serialized == roleJson}');
}
```

---

## Troubleshooting

### Issue: "Permission Denied" Errors

**Cause:** Security rules not deployed or user not authenticated.

**Solution:**
1. Deploy security rules: `firebase deploy --only firestore:rules`
2. Ensure user is authenticated before accessing Firestore
3. Check that user is accessing only their own data

### Issue: Database Already Seeded

**Cause:** Metadata document exists from previous seeding.

**Solution:**
1. Delete the `_metadata/seeding` document in Firebase Console
2. Run seeding again
3. Or use the manual reseed option with force flag

### Issue: Slow Query Performance

**Cause:** Missing indexes for complex queries.

**Solution:**
1. Check Firebase Console for index recommendations
2. Create composite indexes for common queries:
   - `users/{userId}/sessions`: `role_id` + `created_at`
   - `questions`: `role_id` + `question_type`

### Issue: Models Not Deserializing Correctly

**Cause:** Data type mismatch or missing fields.

**Solution:**
1. Check that all required fields are present in Firestore
2. Verify data types match model definitions
3. Use null-safe operators (`??`) for optional fields
4. Check timestamp parsing logic

---

## Database Maintenance

### Backup Strategy

**Automated Backups:**
1. Enable Firebase daily backups in Google Cloud Console
2. Configure retention policy (default: 7 days)

**Manual Backup:**
```bash
# Export entire database
gcloud firestore export gs://[BUCKET_NAME]/[EXPORT_FOLDER]

# Import database
gcloud firestore import gs://[BUCKET_NAME]/[EXPORT_FOLDER]
```

### Data Migration

When updating database schema:

1. Create migration script in `lib/scripts/migrate_database.dart`
2. Test migration on development environment
3. Run migration during low-traffic hours
4. Verify data integrity after migration

### Performance Optimization

**Best Practices:**
1. Use pagination for large collections
2. Limit query results with `.limit()`
3. Use indexes for frequently queried fields
4. Cache frequently accessed data locally
5. Use Firestore offline persistence

---

## Next Steps

After completing the database setup:

1. **Integrate with FastAPI Backend** for Whisper ASR and BERT analysis
2. **Implement Audio Recording** for interview practice
3. **Add Progress Tracking UI** to display user metrics
4. **Create Dashboard** with role selection and question browsing
5. **Implement Offline Mode** for basic features

---

## Support

For issues or questions:

- **Firebase Documentation:** https://firebase.google.com/docs/firestore
- **FlutterFire Documentation:** https://firebase.flutter.dev/docs/overview
- **Project Repository:** [Add your repo URL]

---

**Version:** 1.0.0
**Last Updated:** 2025-11-11
**Author:** JobWise Development Team
