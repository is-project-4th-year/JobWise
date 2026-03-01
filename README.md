# JobWise

An AI-powered interview preparation app designed for the Kenyan job market. JobWise helps job seekers practice interview questions with real-time voice analysis, transcription, and personalized feedback.

## Overview

JobWise combines Flutter mobile development with FastAPI backend services to provide:
- Voice-based interview practice sessions
- Real-time transcription using fine-tuned Whisper ASR (Kenyan English)
- Automated feedback and scoring
- Progress tracking and analytics
- 300+ interview questions across 15 job roles in Technology, Finance, and Healthcare sectors

## Architecture

### Frontend (Flutter)
- **Location**: `jobwise_app/`
- **Framework**: Flutter 3.1.2+
- **State Management**: Flutter BLoC
- **Database**: Cloud Firestore (offline-first)
- **Authentication**: Firebase Auth
- **Storage**: Firebase Storage (audio files)

### Backend (FastAPI)
- **Location**: `jobwise-backend/`
- **Framework**: FastAPI
- **ML Models**: Whisper ASR (fine-tuned for Kenyan English)
- **Processing**: Automated background processing (30s polling)
- **Database**: Firebase Admin SDK

## Features

### For Job Seekers
- Browse 300+ contextually relevant interview questions
- Practice with voice recording
- Get AI-powered transcription and feedback
- Track progress across multiple practice sessions
- View improvement metrics and analytics
- Offline support for uninterrupted practice

### Technical Features
- Kenyan context-aware questions (M-Pesa, local companies, regional scenarios)
- STAR method feedback for behavioral questions
- Multi-dimensional scoring (clarity, relevance, structure)
- Role-based question filtering
- Difficulty-based progression
- Comprehensive progress analytics

## Project Structure

```
Jobwise/
├── jobwise_app/                 # Flutter mobile app
│   ├── lib/
│   │   ├── models/             # Data models (Role, Question, Session, Progress, Feedback)
│   │   ├── services/           # Firebase & API services
│   │   ├── bloc/               # State management
│   │   ├── screens/            # UI screens
│   │   ├── widgets/            # Reusable components
│   │   ├── utils/              # Utilities
│   │   └── scripts/            # Database seeding scripts
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── jobwise-backend/            # FastAPI backend
│   ├── app/
│   │   ├── main.py            # Server entry point
│   │   └── models/            # ML models
│   ├── requirements.txt
│   └── .env                   # Environment variables (not tracked)
│
├── firestore.rules            # Firestore security rules
└── README.md
```

## Setup Instructions

### Prerequisites
- Flutter SDK 3.1.2 or higher
- Python 3.8 or higher
- Firebase project with Firestore, Auth, and Storage enabled
- Git

### Flutter App Setup

1. **Navigate to the app directory**:
   ```bash
   cd jobwise_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**:
   - Download `google-services.json` from your Firebase project
   - Place it in `jobwise_app/android/app/` (already gitignored)
   - Update Firebase configuration in `lib/firebase_options.dart`

4. **Run the app**:
   ```bash
   flutter run
   ```

5. **Seed the database** (first-time setup):
   - Use the seeding script in `lib/scripts/seed_firestore.dart`
   - This populates 15 roles and 300 questions
   - See [FIRESTORE_SETUP.md](FIRESTORE_SETUP.md) for detailed instructions

### Backend Setup

1. **Navigate to backend directory**:
   ```bash
   cd jobwise-backend
   ```

2. **Create virtual environment**:
   ```bash
   python -m venv venv

   # Windows
   venv\Scripts\activate

   # macOS/Linux
   source venv/bin/activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment**:
   - Download `serviceAccountKey.json` from Firebase Console
   - Place it in `jobwise-backend/` (already gitignored)
   - Create `.env` file with required variables (already gitignored)

5. **Add Whisper model**:
   - Place your fine-tuned Whisper model in `jobwise-backend/models/whisper-kenyan-finetuned/`
   - Model folder is gitignored due to size

6. **Run the server**:
   ```bash
   python -m app.main
   ```

   Server runs at `http://localhost:8000`

### Deploy Firestore Security Rules

```bash
firebase deploy --only firestore:rules
```

## Environment Variables

### Backend (.env)
Create a `.env` file in `jobwise-backend/` with:
```env
FIREBASE_STORAGE_BUCKET=your-project.appspot.com
FIREBASE_DATABASE_URL=https://your-project.firebaseio.com
ENVIRONMENT=development
```

## Configuration Files to Obtain

Before running the project, you'll need to obtain these files from Firebase:

1. **google-services.json** - Firebase Android configuration
   - Location: `jobwise_app/android/app/google-services.json`
   - Obtain from: Firebase Console > Project Settings > Your Apps > Android app

2. **serviceAccountKey.json** - Firebase Admin SDK credentials
   - Location: `jobwise-backend/serviceAccountKey.json`
   - Obtain from: Firebase Console > Project Settings > Service Accounts > Generate new private key

3. **.env** - Backend environment variables
   - Location: `jobwise-backend/.env`
   - Create manually using the template above

All these files are gitignored for security.

## API Documentation

Once the backend is running, visit:
- Interactive docs: `http://localhost:8000/docs`
- Health check: `http://localhost:8000/health`

### Key Endpoints
- `GET /` - Health check
- `GET /health` - Detailed server status
- `POST /process` - Manually trigger session processing
- `GET /sessions/pending` - View pending sessions

## Database Schema

### Collections
- `roles` - Job roles (15 across 3 industries)
- `questions` - Interview questions (300 total, 20 per role)
- `users/{userId}/sessions` - User practice sessions
- `users/{userId}/progress` - User progress tracking
- `users/{userId}/feedback` - Session feedback

For detailed schema, see [FIRESTORE_SETUP.md](FIRESTORE_SETUP.md)

## Kenyan Market Context

JobWise is specifically designed for the Kenyan job market with:

### Companies Featured
- **Technology**: Safaricom, Andela, M-KOPA, Cellulant, Twiga Foods
- **Finance**: KCB, Equity Bank, NCBA, Britam, Deloitte Kenya
- **Healthcare**: Aga Khan Hospital, Nairobi Hospital, Kenyatta Hospital

### Contextual Scenarios
- M-Pesa payment integration
- Matatu transportation system
- Power outage handling
- Mobile-first solutions
- Regulatory compliance (KRA, CBK, NHIF)
- Limited resource environments

## Development Workflow

### How It Works
1. User selects a role and question in the Flutter app
2. Records their answer using the device microphone
3. Audio is uploaded to Firebase Storage
4. Session is created in Firestore with `pending` status
5. Backend polls Firestore every 30 seconds
6. Backend downloads audio, transcribes with Whisper
7. Analyzes response and generates feedback
8. Updates Firestore with results
9. Flutter app displays transcription and feedback

## Testing

### Flutter App
```bash
cd jobwise_app
flutter test
flutter analyze
```

### Backend
```bash
cd jobwise-backend
# Check health
curl http://localhost:8000/health

# Process pending sessions
curl -X POST http://localhost:8000/process
```

## Security

### Configuration Protection
All sensitive files are gitignored and never committed to the repository:
- `.env` files (backend environment variables)
- `serviceAccountKey.json` (Firebase Admin SDK credentials)
- `google-services.json` (Firebase Android configuration)
- ML model files (too large, stored separately)

### API Key Restrictions
The Firebase API keys visible in configuration files are **protected and restricted**:

#### ✅ Active Restrictions
- **Android App Restriction**: Keys only function within the JobWise Android application package
- **API Scope Restrictions**: Limited to Firebase Authentication, Firestore, and Storage APIs only
- **No Billing Access**: Keys cannot incur charges beyond free tier limits
- **Monitored Usage**: Firebase automatically monitors for unusual activity

#### What This Means
Even though configuration files are visible in this repository:
- API keys **cannot be used** outside the JobWise Android app
- They are **restricted to specific Firebase services** only
- They have **no access to billing or administrative functions**
- Unauthorized use attempts are **automatically blocked**

### For Collaborators & Reviewers

**To run this project locally**, you must create your own Firebase project:

1. **Create Firebase Project**: Visit https://console.firebase.google.com
2. **Enable Services**:
   - Firebase Authentication (Email/Password provider)
   - Cloud Firestore (Database)
   - Firebase Storage (for audio files)
3. **Download Credentials**:
   - Android: `google-services.json` → place in `jobwise_app/android/app/`
   - Backend: Service account key → save as `serviceAccountKey.json` in `jobwise-backend/`
4. **Configure Environment**:
   - Create `backend/.env` with your Firebase project details
   - Update `lib/firebase_options.dart` with your configuration

**The credentials in this repository will NOT work for external setups.**

### Repository Access
- **Visibility**: Private repository
- **Organization**: Strathmore University School Projects
- **Access**: Limited to project team and academic supervisors
- **Purpose**: Academic capstone project demonstration

### Firestore Security Rules
- User data isolation enforced at database level
- Users can only read/write their own sessions and progress
- Roles and questions are read-only for authenticated users
- Admin-only write access for roles and questions

### Security Best Practices Applied
- ✅ Credentials stored in gitignored files
- ✅ API keys restricted to specific applications and services
- ✅ Firebase security rules enforce data isolation
- ✅ HTTPS-only communication
- ✅ Environment-specific configuration
- ✅ No hardcoded secrets in source code

### Reporting Security Issues
For security concerns or questions:
- **Developer**: Elvis Mwitari (mwitarielvis@gmail.com)
- **Institution**: Strathmore University, School of Computing and Engineering Sciences

## Documentation

- [FIRESTORE_SETUP.md](FIRESTORE_SETUP.md) - Detailed database setup and seeding
- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - Development summary
- [USAGE_EXAMPLES.md](USAGE_EXAMPLES.md) - Usage examples and API calls
- [VERIFICATION_REPORT.md](VERIFICATION_REPORT.md) - Testing and verification

## Tech Stack

### Frontend
- Flutter 3.1.2+
- Firebase (Auth, Firestore, Storage)
- Flutter BLoC (State Management)
- Just Audio (Audio playback)
- Flutter Sound (Audio recording)
- FL Chart (Analytics visualization)

### Backend
- FastAPI
- PyTorch & Transformers
- Whisper ASR (fine-tuned)
- Firebase Admin SDK
- Librosa (Audio processing)

## Contributing

This is a private project. For authorized contributors:

1. Create a feature branch
2. Make changes
3. Test thoroughly
4. Submit pull request

## License

Proprietary - All rights reserved

## Support

For issues or questions, contact the development team.

## Roadmap

- [ ] BERT semantic analysis integration
- [ ] Real-time feedback during recording
- [ ] Additional job sectors (Education, Hospitality, etc.)
- [ ] Video interview practice
- [ ] Interview tips and resources
- [ ] Performance comparison with peers
- [ ] Mock interview scheduler
- [ ] Interview coach chatbot

---

**Version**: 1.0.0
**Status**: Production-ready
**Last Updated**: January 2026
