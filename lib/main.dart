import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme.dart';

// Services
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

// BLoC
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';

// Screens
import 'ui/auth/auth_wrapper.dart';
import 'ui/auth/login_screen_new.dart';
import 'ui/auth/signup_screen.dart';
import 'ui/auth/phone_verification_screen.dart';
import 'ui/auth/mfa_challenge_screen.dart';
import 'ui/auth/password_reset_screen.dart';
import 'ui/home/dashboard_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/question_list_screen.dart';
import 'screens/recording_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase - UNCOMMENTED
  await Firebase.initializeApp();

  runApp(const JobWiseApp());
}

class JobWiseApp extends StatelessWidget {
  const JobWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthService>(
          create: (context) => AuthService(),
        ),
        RepositoryProvider<FirestoreService>(
          create: (context) => FirestoreService(),
        ),
      ],
      child: BlocProvider(
        create: (context) => AuthBloc(
          authService: context.read<AuthService>(),
          firestoreService: context.read<FirestoreService>(),
        )..add(const AuthCheckRequested()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'JobWise',
          theme: appTheme,
          initialRoute: '/',
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(
                  builder: (_) => const AuthWrapper(),
                );
              case '/login':
                return MaterialPageRoute(
                  builder: (_) => const LoginScreenNew(),
                );
              case '/signup':
                return MaterialPageRoute(
                  builder: (_) => const SignupScreen(),
                );
              case '/phone-verification':
                return MaterialPageRoute(
                  builder: (_) => const PhoneVerificationScreen(),
                );
              case '/mfa-challenge':
                final resolver = settings.arguments;
                return MaterialPageRoute(
                  builder: (_) => MFAChallengeScreen(
                    resolver: resolver as dynamic,
                  ),
                );
              case '/password-reset':
                return MaterialPageRoute(
                  builder: (_) => const PasswordResetScreen(),
                );
              case '/dashboard':
                return MaterialPageRoute(
                  builder: (_) => const DashboardScreen(),
                );
              case '/home':
                return MaterialPageRoute(
                  builder: (_) => const RoleSelectionScreen(),
                );
              case '/questions':
                final role = settings.arguments;
                return MaterialPageRoute(
                  builder: (_) => QuestionListScreen(role: role as dynamic),
                );
              case '/recording':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => RecordingScreen(
                    role: args['role'] as dynamic,
                    question: args['question'] as dynamic,
                  ),
                );
              case '/processing':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => ProcessingScreen(
                    sessionId: args['sessionId'] as String,
                    userId: args['userId'] as String,
                  ),
                );
              case '/history':
                return MaterialPageRoute(
                  builder: (_) => const HistoryScreen(),
                );
              case '/settings':
                return MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                );
              default:
                return MaterialPageRoute(
                  builder: (_) => const AuthWrapper(),
                );
            }
          },
        ),
      ),
    );
  }
}