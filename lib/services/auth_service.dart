import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service class for handling Firebase Authentication operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Debug mode flag
  static const bool _debugMode = kDebugMode;

  void _log(String message) {
    if (_debugMode) {
      debugPrint('[AuthService] $message');
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      _log('Starting sign up for email: $email');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      _log('Sign up successful for user: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      _log('Sign up failed: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _log('Sign up error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  /// May throw FirebaseAuthMultiFactorException if MFA is required
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _log('Starting sign in for email: $email');

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      _log('Sign in successful for user: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      _log('Sign in failed: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _log('Sign in error: $e');
      rethrow;
    }
  }

  /// Send phone verification code
  /// Returns a Future that completes when the code is sent
  Future<String> sendPhoneVerification({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException error) onVerificationFailed,
    Function(PhoneAuthCredential credential)? onAutoVerified,
  }) async {
    _log('Sending phone verification to: $phoneNumber');

    final completer = Completer<String>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          _log('Phone auto-verified');
          if (onAutoVerified != null) {
            onAutoVerified(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _log('Phone verification failed: ${e.code} - ${e.message}');
          onVerificationFailed(e);
          if (!completer.isCompleted) {
            completer.completeError(_handleAuthException(e));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _log('Phone verification code sent. VerificationId: $verificationId');
          onCodeSent(verificationId, resendToken);
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _log('Code auto-retrieval timeout. VerificationId: $verificationId');
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        timeout: const Duration(seconds: 60),
      );

      return await completer.future;
    } catch (e) {
      _log('Send phone verification error: $e');
      rethrow;
    }
  }

  /// Verify phone number with OTP code
  Future<PhoneAuthCredential> verifyPhoneNumber({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      _log('Verifying phone number with code');

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      _log('Phone credential created successfully');
      return credential;
    } catch (e) {
      _log('Verify phone number error: $e');
      rethrow;
    }
  }

  /// Link phone credential to current user (for initial phone verification)
  Future<UserCredential> linkPhoneToUser({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      _log('Linking phone to current user');

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await user.linkWithCredential(credential);
      _log('Phone linked successfully to user: ${user.uid}');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      _log('Link phone failed: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _log('Link phone error: $e');
      rethrow;
    }
  }

  /// Enroll phone number in Multi-Factor Authentication
  Future<void> enrollPhoneInMFA({
    required String verificationId,
    required String smsCode,
    String displayName = 'Phone Number',
  }) async {
    try {
      _log('Enrolling phone in MFA');

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final multiFactorAssertion = PhoneMultiFactorGenerator.getAssertion(
        credential,
      );

      await user.multiFactor.enroll(
        multiFactorAssertion,
        displayName: displayName,
      );

      _log('Phone enrolled in MFA successfully');
    } on FirebaseAuthException catch (e) {
      _log('MFA enrollment failed: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _log('MFA enrollment error: $e');
      rethrow;
    }
  }

  /// Send MFA verification code during sign-in
  Future<String> sendMFAVerification({
    required MultiFactorResolver resolver,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException error) onVerificationFailed,
  }) async {
    _log('Sending MFA verification code');

    final completer = Completer<String>();

    try {
      final hint = resolver.hints.first;
      final session = resolver.session;

      await _auth.verifyPhoneNumber(
        multiFactorSession: session,
        multiFactorInfo: hint as PhoneMultiFactorInfo,
        verificationCompleted: (PhoneAuthCredential credential) {
          _log('MFA auto-verified');
        },
        verificationFailed: (FirebaseAuthException e) {
          _log('MFA verification failed: ${e.code} - ${e.message}');
          onVerificationFailed(e);
          if (!completer.isCompleted) {
            completer.completeError(_handleAuthException(e));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _log('MFA code sent. VerificationId: $verificationId');
          onCodeSent(verificationId, resendToken);
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _log('MFA code auto-retrieval timeout');
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        timeout: const Duration(seconds: 60),
      );

      return await completer.future;
    } catch (e) {
      _log('Send MFA verification error: $e');
      rethrow;
    }
  }

  /// Resolve MFA challenge during sign-in
  Future<UserCredential> resolveMFAChallenge({
    required MultiFactorResolver resolver,
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      _log('Resolving MFA challenge');

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final multiFactorAssertion = PhoneMultiFactorGenerator.getAssertion(
        credential,
      );

      final userCredential = await resolver.resolveSignIn(multiFactorAssertion);
      _log('MFA challenge resolved successfully');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      _log('Resolve MFA failed: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _log('Resolve MFA error: $e');
      rethrow;
    }
  }

  /// Check if current user has MFA enabled
  Future<bool> isMFAEnabled() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();
    final freshUser = _auth.currentUser;
    if (freshUser == null) return false;

    final enrolledFactors = await freshUser.multiFactor.getEnrolledFactors();
    final mfaEnabled = enrolledFactors.isNotEmpty;
    _log('MFA enabled: $mfaEnabled');
    return mfaEnabled;
  }

  /// Get enrolled MFA factors
  Future<List<MultiFactorInfo>> getEnrolledMFAFactors() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    return await user.multiFactor.getEnrolledFactors();
  }

  /// Send password reset email
  Future<void> resetPassword({required String email}) async {
    try {
      _log('Sending password reset email to: $email');

      await _auth.sendPasswordResetEmail(email: email.trim());
      _log('Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      _log('Password reset failed: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _log('Password reset error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _log('Signing out user: ${_auth.currentUser?.uid}');
      await _auth.signOut();
      _log('Sign out successful');
    } catch (e) {
      _log('Sign out error: $e');
      rethrow;
    }
  }

  /// Handle Firebase Auth exceptions and return user-friendly error messages
  Exception _handleAuthException(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'email-already-in-use':
        message = 'This email is already registered. Please sign in instead.';
        break;
      case 'weak-password':
        message = 'Password is too weak. Please use at least 6 characters.';
        break;
      case 'invalid-email':
        message = 'Invalid email address. Please check and try again.';
        break;
      case 'user-not-found':
        message = 'No account found with this email. Please sign up.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'invalid-credential':
        message = 'Incorrect email or password. Please try again.';
        break;
      case 'invalid-verification-code':
        message = 'Invalid verification code. Please check and try again.';
        break;
      case 'invalid-verification-id':
        message = 'Verification session expired. Please request a new code.';
        break;
      case 'code-expired':
        message = 'Verification code expired. Please request a new code.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your internet connection.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled. Contact support.';
        break;
      case 'operation-not-allowed':
        message = 'This operation is not allowed. Contact support.';
        break;
      case 'requires-recent-login':
        message = 'Please sign in again to continue.';
        break;
      case 'credential-already-in-use':
        message = 'This phone number is already linked to another account.';
        break;
      case 'provider-already-linked':
        message = 'This phone number is already linked to your account.';
        break;
      case 'invalid-phone-number':
        message = 'Invalid phone number format. Please check and try again.';
        break;
      case 'missing-phone-number':
        message = 'Phone number is required.';
        break;
      case 'quota-exceeded':
        message = 'SMS quota exceeded. Please try again later.';
        break;
      case 'captcha-check-failed':
        message = 'reCAPTCHA verification failed. Please try again.';
        break;
      case 'session-expired':
        message = 'Session expired. Please start over.';
        break;
      default:
        message = e.message ?? 'An error occurred. Please try again.';
    }

    return Exception(message);
  }
}
