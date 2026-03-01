import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import 'login_screen_new.dart';
import 'phone_verification_screen.dart';
import '../home/dashboard_screen.dart';

/// Wrapper widget that handles navigation based on authentication state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Check auth state when app starts
    context.read<AuthBloc>().add(const AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Show loading screen while checking auth state
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // User is authenticated and fully verified
        if (state is AuthAuthenticated) {
          return const DashboardScreen();
        }

        // // User needs to verify phone number
        // if (state is AuthPhoneVerificationRequired) {
        //   return const PhoneVerificationScreen();
        // }

        // User is not authenticated
        if (state is AuthUnauthenticated) {
          return const LoginScreenNew();
        }

        // Handle error state
        if (state is AuthError) {
          // Show error and return to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
          return const LoginScreenNew();
        }

        // Default: show login screen
        return const LoginScreenNew();
      },
    );
  }
}
