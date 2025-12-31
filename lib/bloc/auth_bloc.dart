import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  StreamSubscription<User?>? _authSubscription;

  static const bool _debugMode = kDebugMode;

  void _log(String message) {
    if (_debugMode) {
      debugPrint('[AuthBloc] $message');
    }
  }

  AuthBloc({
    required AuthService authService,
    required FirestoreService firestoreService,
  })  : _authService = authService,
        _firestoreService = firestoreService,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<LoginRequested>(_onLoginRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthStateChanged>(_onAuthStateChanged);

    _authSubscription = _authService.authStateChanges.listen((user) {
      add(AuthStateChanged(user: user));
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log('Checking auth state');
    emit(const AuthLoading(message: 'Checking authentication...'));

    try {
      final user = _authService.currentUser;

      if (user == null) {
        _log('No user signed in');
        emit(const AuthUnauthenticated());
        return;
      }

      _log('User authenticated: ${user.uid}');
      emit(AuthAuthenticated(user: user, isMFAEnabled: false));
    } catch (e) {
      _log('Auth check error: $e');
      emit(AuthError(message: 'Error checking authentication: $e'));
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log('Sign up requested for: ${event.email}');
    emit(const AuthLoading(message: 'Creating account...'));

    try {
      final credential = await _authService.signUp(
        email: event.email,
        password: event.password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('User creation failed');
      }

      await _firestoreService.createUserDocument(
        user: user,
        phoneNumber: '',
        isPhoneVerified: true,
        isMFAEnabled: false,
      );

      _log('Sign up successful - going straight to authenticated');
      emit(AuthAuthenticated(user: user, isMFAEnabled: false));
      
    } catch (e) {
      _log('Sign up error: $e');
      final message = e is Exception ? e.toString().replaceAll('Exception: ', '') : e.toString();
      emit(AuthError(message: message));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log('Login requested for: ${event.email}');
    emit(const AuthLoading(message: 'Signing in...'));

    try {
      final credential = await _authService.signIn(
        email: event.email,
        password: event.password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Sign in failed');
      }

      _log('Sign in successful for user: ${user.uid}');
      await _firestoreService.updateLastLogin(userId: user.uid);

      _log('Login successful - authenticated');
      emit(AuthAuthenticated(user: user, isMFAEnabled: false));

    } catch (e) {
      _log('Login error: $e');
      final message = e is Exception ? e.toString().replaceAll('Exception: ', '') : e.toString();
      emit(AuthError(message: message));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log('Password reset requested for: ${event.email}');
    emit(const AuthLoading(message: 'Sending reset email...'));

    try {
      await _authService.resetPassword(email: event.email);
      _log('Password reset email sent');
      emit(AuthPasswordResetSent(email: event.email));

      await Future.delayed(const Duration(seconds: 2));
      emit(const AuthUnauthenticated());
    } catch (e) {
      _log('Password reset error: $e');
      final message = e is Exception ? e.toString().replaceAll('Exception: ', '') : e.toString();
      emit(AuthError(message: message));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log('Logout requested');
    emit(const AuthLoading(message: 'Signing out...'));

    try {
      await _authService.signOut();
      _log('Logout successful');
      emit(const AuthUnauthenticated(message: 'Signed out successfully'));
    } catch (e) {
      _log('Logout error: $e');
      emit(AuthError(message: 'Error signing out: $e'));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    final userId = event.user?.uid ?? 'null';
    _log('Auth state changed. User: $userId');

    if (state is! AuthInitial && state is! AuthUnauthenticated) {
      return;
    }

    if (event.user == null) {
      emit(const AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}