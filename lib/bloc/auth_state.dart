import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Base class for all authentication states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state when app starts
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State when authentication operation is in progress
class AuthLoading extends AuthState {
  final String? message;

  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// State when user is authenticated and verified
class AuthAuthenticated extends AuthState {
  final User user;
  final bool isMFAEnabled;

  const AuthAuthenticated({
    required this.user,
    this.isMFAEnabled = false,
  });

  @override
  List<Object?> get props => [user, isMFAEnabled];
}

/// State when user is not authenticated
class AuthUnauthenticated extends AuthState {
  final String? message;

  const AuthUnauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}

/// State when phone verification is required
class AuthPhoneVerificationRequired extends AuthState {
  final User user;
  final String? verificationId;

  const AuthPhoneVerificationRequired({
    required this.user,
    this.verificationId,
  });

  @override
  List<Object?> get props => [user, verificationId];
}

/// State when phone verification code has been sent
class AuthPhoneCodeSent extends AuthState {
  final User user;
  final String verificationId;
  final String phoneNumber;

  const AuthPhoneCodeSent({
    required this.user,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [user, verificationId, phoneNumber];
}

/// State when MFA challenge is required during login
class AuthMFARequired extends AuthState {
  final MultiFactorResolver resolver;
  final String? verificationId;
  final String? phoneNumber;

  const AuthMFARequired({
    required this.resolver,
    this.verificationId,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [resolver, verificationId, phoneNumber];
}

/// State when MFA code has been sent
class AuthMFACodeSent extends AuthState {
  final MultiFactorResolver resolver;
  final String verificationId;
  final String phoneNumber;

  const AuthMFACodeSent({
    required this.resolver,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [resolver, verificationId, phoneNumber];
}

/// State when an authentication error occurs
class AuthError extends AuthState {
  final String message;
  final String? errorCode;

  const AuthError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

/// State when password reset email has been sent
class AuthPasswordResetSent extends AuthState {
  final String email;

  const AuthPasswordResetSent({required this.email});

  @override
  List<Object?> get props => [email];
}

/// State when signup is successful but needs phone verification
class AuthSignUpSuccess extends AuthState {
  final User user;

  const AuthSignUpSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}
