import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Base class for all authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when checking initial auth state
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Event triggered when user requests to sign up
class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String phoneNumber;

  const SignUpRequested({
    required this.email,
    required this.password,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [email, password, phoneNumber];
}

/// Event triggered when user requests to sign in
class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Event triggered when phone verification is requested
class SendPhoneVerificationRequested extends AuthEvent {
  final String phoneNumber;

  const SendPhoneVerificationRequested({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

/// Event triggered when verifying phone OTP
class VerifyPhoneRequested extends AuthEvent {
  final String verificationId;
  final String smsCode;
  final bool enrollInMFA;

  const VerifyPhoneRequested({
    required this.verificationId,
    required this.smsCode,
    this.enrollInMFA = false,
  });

  @override
  List<Object?> get props => [verificationId, smsCode, enrollInMFA];
}

/// Event triggered when MFA challenge needs to be resolved
class SendMFAVerificationRequested extends AuthEvent {
  final MultiFactorResolver resolver;

  const SendMFAVerificationRequested({required this.resolver});

  @override
  List<Object?> get props => [resolver];
}

/// Event triggered when verifying MFA OTP
class VerifyMFARequested extends AuthEvent {
  final MultiFactorResolver resolver;
  final String verificationId;
  final String smsCode;

  const VerifyMFARequested({
    required this.resolver,
    required this.verificationId,
    required this.smsCode,
  });

  @override
  List<Object?> get props => [resolver, verificationId, smsCode];
}

/// Event triggered when password reset is requested
class PasswordResetRequested extends AuthEvent {
  final String email;

  const PasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Event triggered when user requests to sign out
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Event triggered when auth state changes
class AuthStateChanged extends AuthEvent {
  final User? user;

  const AuthStateChanged({this.user});

  @override
  List<Object?> get props => [user];
}

/// Event to store verification ID
class VerificationIdReceived extends AuthEvent {
  final String verificationId;

  const VerificationIdReceived({required this.verificationId});

  @override
  List<Object?> get props => [verificationId];
}
