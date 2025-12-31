# JobWise - Interview Preparation App

JobWise is a mobile interview preparation app designed for Kenyan graduates. It helps users practice interview questions through audio recording, receive AI-powered feedback, and track their progress.

## Features Implemented

### ✅ Prompt 1: Firebase Authentication & Data Models
- Firebase Authentication with MFA support
- Firestore database with complete schema
- All Dart models with serialization (Role, Question, InterviewSession, UserProgress, Feedback)
- FirestoreService with 20+ methods for data operations
- Authentication BLoC architecture

### ✅ Prompt 2: Interview Flow & Audio Recording Interface
- **Role Selection Screen**: Browse and filter job roles by industry, department, and search
- **Question List Screen**: View questions with attempt history and progress tracking
- **Recording Screen**: Complete audio recording flow with state machine
  - 30-second preparation timer
  - Audio recording with real-time duration tracking
  - Playback capability before submission
  - Upload to Firebase Storage
- **Processing Screen**: Session processing status with animated feedback
- **Offline Support**: Queue sessions for upload when offline with automatic sync
- **Audio Service**: Full audio recording and upload functionality
- **Session Manager**: Manage offline queue and retry failed uploads
- **Bottom Navigation**: Navigate between Home, Progress, History, and Profile

## Tech Stack

- **Framework**: Flutter 3.x
- **Backend**: Firebase (Auth, Firestore, Storage)
- **State Management**: BLoC pattern
- **Audio Recording**: `record` package
- **Audio Playback**: `just_audio` package
- **Permissions**: `permission_handler` package
- **Connectivity**: `connectivity_plus` package

## Project Structure

```
lib/
├── bloc/                      # BLoC state management
│   ├── auth_bloc.dart
│   ├── auth_event.dart
│   └── auth_state.dart
├── models/                    # Data models
│   ├── role_model.dart
│   ├── question_model.dart
│   ├── interview_session_model.dart
│   ├── user_progress_model.dart
│   └── feedback_model.dart
├── screens/                   # Application screens
│   ├── role_selection_screen.dart
│   ├── question_list_screen.dart
│   ├── recording_screen.dart
│   └── processing_screen.dart
├── services/                  # Business logic services
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── audio_service.dart
│   └── session_manager.dart
├── ui/                        # Authentication UI
│   ├── auth/
│   └── home/
├── widgets/                   # Reusable widgets
│   └── bottom_nav_bar.dart
├── main.dart                  # Application entry point
└── theme.dart                 # App theme configuration
```

## Setup Instructions

### Prerequisites

1. Flutter SDK (3.1.2 or higher)
2. Firebase project configured
3. Android Studio / Xcode for mobile development

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd jobwise_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Follow instructions in [FIREBASE_CONSOLE_SETUP.md](FIREBASE_CONSOLE_SETUP.md)
   - Enable Authentication, Firestore, and Storage in Firebase Console
   - Download and add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

4. **Run the app**
   ```bash
   flutter run
   ```

## Permissions

### Android
Microphone and storage permissions are configured in `android/app/src/main/AndroidManifest.xml`:
- `RECORD_AUDIO`: Record interview answers
- `WRITE_EXTERNAL_STORAGE`: Save audio files temporarily
- `READ_EXTERNAL_STORAGE`: Read audio files for upload
- `INTERNET`: Upload to Firebase
- `ACCESS_NETWORK_STATE`: Check connectivity for offline mode

### iOS
Microphone permission is configured in `ios/Runner/Info.plist`:
- `NSMicrophoneUsageDescription`: Record interview answers

## Testing

### Manual Testing Checklist

#### Role Selection
- [ ] All roles load successfully
- [ ] Industry filter works (Technology, Finance, Healthcare)
- [ ] Department dropdown filters correctly
- [ ] Search functionality works
- [ ] Navigation to questions works

#### Question List
- [ ] Questions load for selected role
- [ ] Attempt history shows correctly (green/yellow/gray badges)
- [ ] Progress panel displays accurate stats
- [ ] Random question button works
- [ ] Navigation to recording works

#### Recording Flow
- [ ] Microphone permissions requested properly
- [ ] 30-second preparation timer works
- [ ] Recording starts and stops correctly
- [ ] Duration displays accurately
- [ ] Playback works before submission
- [ ] Re-record functionality works
- [ ] Upload succeeds and navigates to processing
- [ ] Minimum 10-second validation works
- [ ] Maximum 5-minute auto-stop works

#### Offline Mode
- [ ] Sessions queue when offline
- [ ] Automatic sync when connection restored
- [ ] Pending session count updates
- [ ] Retry logic works for failed uploads

### Running Tests

```bash
# Run Flutter tests
flutter test

# Run Flutter analyze
flutter analyze

# Check for outdated packages
flutter pub outdated
```

## Audio Recording Specifications

- **Format**: M4A (AAC-LC encoding)
- **Sample Rate**: 16 kHz (optimized for Whisper ASR)
- **Bit Rate**: 128 kbps
- **Channels**: Mono (1 channel)
- **Min Duration**: 10 seconds
- **Max Duration**: 5 minutes (300 seconds)
- **Max File Size**: 50 MB

## Firebase Firestore Schema

### Collections

1. **roles**: Job roles with questions
2. **questions**: Interview questions for each role
3. **users/{userId}/sessions**: User interview sessions
4. **users/{userId}/progress**: User progress tracking

See [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) for detailed schema.

## Known Limitations

1. **Feedback Display**: Not yet implemented (Prompt 4)
2. **Progress Screen**: Placeholder (Prompt 5)
3. **History Screen**: Placeholder (Prompt 5)
4. **Profile Screen**: Placeholder (Prompt 5)
5. **Backend Processing**: Requires Python backend (Prompt 3)

## Next Steps (Future Prompts)

### Prompt 3: Python Backend
- Whisper ASR for transcription
- BERT for answer analysis
- Feedback generation with LLM
- Firebase Cloud Functions integration

### Prompt 4: Feedback Display
- Show transcription
- Display scores and metrics
- Present structured feedback
- Compare attempts

### Prompt 5: Analytics & History
- Progress dashboard
- Session history
- Performance trends
- User profile

## Troubleshooting

### Audio Recording Issues

**Problem**: Microphone permission denied
- **Solution**: Go to device settings and manually enable microphone permission for JobWise

**Problem**: Recording fails on emulator
- **Solution**: Test on a real device (emulators often have microphone issues)

**Problem**: Upload fails
- **Solution**: Check Firebase Storage rules and internet connectivity

### Firestore Issues

**Problem**: "Permission denied" errors
- **Solution**: Update Firestore security rules to allow authenticated users

**Problem**: No roles/questions loading
- **Solution**: Run the seed script: `dart lib/scripts/seed_firestore.dart`

### Build Issues

**Problem**: Gradle build fails (Android)
- **Solution**: Update Android SDK and ensure `google-services.json` is in place

**Problem**: Pod install fails (iOS)
- **Solution**: Run `cd ios && pod install --repo-update`

## Contributing

When contributing to JobWise:
1. Follow Flutter/Dart style guidelines
2. Maintain existing BLoC architecture
3. Add tests for new features
4. Update documentation
5. Ensure compatibility with existing Firestore schema

## License

Copyright © 2024 JobWise. All rights reserved.

## Support

For issues or questions:
- Check [TESTING_GUIDE.md](TESTING_GUIDE.md) for detailed testing procedures
- Review [FIREBASE_CONSOLE_SETUP.md](FIREBASE_CONSOLE_SETUP.md) for configuration help
- Open an issue in the project repository

---

**Last Updated**: Prompt 2 Implementation Complete
**Version**: 1.0.0
**Flutter Version**: 3.1.2+
