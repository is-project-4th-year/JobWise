import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../../utils/phone_number_utils.dart';

class MFAChallengeScreen extends StatefulWidget {
  final MultiFactorResolver? resolver;

  const MFAChallengeScreen({super.key, this.resolver});

  @override
  State<MFAChallengeScreen> createState() => _MFAChallengeScreenState();
}

class _MFAChallengeScreenState extends State<MFAChallengeScreen> {
  final _otpController = TextEditingController();

  String? _verificationId;
  String? _phoneNumber;
  bool _codeSent = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _checkCurrentState();
    _sendMFACode();
  }

  void _checkCurrentState() {
    final state = context.read<AuthBloc>().state;
    if (state is AuthMFACodeSent) {
      setState(() {
        _verificationId = state.verificationId;
        _phoneNumber = state.phoneNumber;
        _codeSent = true;
      });
      _startResendTimer();
    } else if (state is AuthMFARequired) {
      if (state.verificationId != null) {
        setState(() {
          _verificationId = state.verificationId;
          _phoneNumber = state.phoneNumber;
          _codeSent = true;
        });
        _startResendTimer();
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _sendMFACode() {
    final state = context.read<AuthBloc>().state;
    MultiFactorResolver? resolver;

    if (widget.resolver != null) {
      resolver = widget.resolver;
    } else if (state is AuthMFARequired) {
      resolver = state.resolver;
    } else if (state is AuthMFACodeSent) {
      resolver = state.resolver;
    }

    if (resolver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('MFA resolver not found. Please try logging in again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    context.read<AuthBloc>().add(SendMFAVerificationRequested(
      resolver: resolver,
    ));
  }

  void _verifyCode() {
    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification session expired. Please try again.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit code'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final state = context.read<AuthBloc>().state;
    MultiFactorResolver? resolver;

    if (widget.resolver != null) {
      resolver = widget.resolver;
    } else if (state is AuthMFARequired) {
      resolver = state.resolver;
    } else if (state is AuthMFACodeSent) {
      resolver = state.resolver;
    }

    if (resolver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please try logging in again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    context.read<AuthBloc>().add(VerifyMFARequested(
      resolver: resolver,
      verificationId: _verificationId!,
      smsCode: _otpController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is AuthMFACodeSent) {
            setState(() {
              _verificationId = state.verificationId;
              _phoneNumber = state.phoneNumber;
              _codeSent = true;
            });
            _startResendTimer();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Verification code sent to ${PhoneNumberUtils.maskNumber(state.phoneNumber)}'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Authentication successful!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icon
                      Icon(
                        Icons.security,
                        size: 64,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Verify Your Identity',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _phoneNumber != null
                            ? 'Enter the code sent to ${PhoneNumberUtils.maskNumber(_phoneNumber!)}'
                            : 'Enter the verification code sent to your phone',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      if (_codeSent) ...[
                        // OTP Input using Pinput
                        Pinput(
                          controller: _otpController,
                          length: 6,
                          defaultPinTheme: defaultPinTheme,
                          focusedPinTheme: defaultPinTheme.copyWith(
                            decoration: defaultPinTheme.decoration?.copyWith(
                              border: Border.all(color: theme.primaryColor, width: 2),
                            ),
                          ),
                          submittedPinTheme: defaultPinTheme.copyWith(
                            decoration: defaultPinTheme.decoration?.copyWith(
                              border: Border.all(color: Colors.green, width: 2),
                              color: Colors.green[50],
                            ),
                          ),
                          errorPinTheme: defaultPinTheme.copyWith(
                            decoration: defaultPinTheme.decoration?.copyWith(
                              border: Border.all(color: Colors.red, width: 2),
                            ),
                          ),
                          onCompleted: (pin) => _verifyCode(),
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 24),

                        // Verify Button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _verifyCode,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Verify',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Resend Code Button
                        SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: (isLoading || _resendCountdown > 0)
                                ? null
                                : _sendMFACode,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _resendCountdown > 0
                                  ? 'Resend Code ($_resendCountdown s)'
                                  : 'Resend Code',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const Center(
                          child: CircularProgressIndicator(),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sending verification code...',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Help Text
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'This is an additional security step to protect your account.',
                                style: TextStyle(
                                  color: Colors.blue[900],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Loading Message
                      if (state is AuthLoading && state.message != null) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            state.message!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
