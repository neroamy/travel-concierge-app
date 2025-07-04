import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/api_test_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  /// Check authentication status and navigate accordingly
  Future<void> _checkAuthenticationStatus() async {
    try {
      // Initialize authentication system
      await _authService.initializeAuth();

      // Run API tests in debug mode
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        print('🧪 Running API connection tests...');
        await ApiTestHelper.runAllTests();
      }

      // Small delay for splash effect
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      if (_authService.isLoggedIn) {
        // Check if session is still valid
        final isValid = await _authService.isSessionValid();

        if (isValid) {
          // User is logged in and session is valid
          print('✅ Valid session found, navigating to main screen');
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.travelExplorationScreen,
          );
        } else {
          // Session expired, go to login
          print('⚠️ Session expired, navigating to login');
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.signInScreen,
          );
        }
      } else {
        // User not logged in
        print('🔐 No authentication found, navigating to login');
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.signInScreen,
        );
      }
    } catch (e) {
      print('❌ Error during authentication check: $e');
      // On error, navigate to login screen
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.signInScreen,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteCustom,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  appTheme.colorFF0373.withOpacity(0.1),
                  appTheme.whiteCustom,
                ],
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo/icon
                Container(
                  width: 120.h,
                  height: 120.h,
                  decoration: BoxDecoration(
                    color: appTheme.colorFF0373,
                    borderRadius: BorderRadius.circular(30.h),
                    boxShadow: [
                      BoxShadow(
                        color: appTheme.colorFF0373.withOpacity(0.3),
                        blurRadius: 20.h,
                        offset: Offset(0, 10.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.flight_takeoff,
                    size: 60.h,
                    color: appTheme.whiteCustom,
                  ),
                ),

                SizedBox(height: 32.h),

                // App name
                Text(
                  'Travel Concierge',
                  style: TextStyle(
                    fontSize: 32.fSize,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'PoppinsSemiBold',
                    color: appTheme.blackCustom,
                  ),
                ),

                SizedBox(height: 8.h),

                // App tagline
                Text(
                  'Your AI-powered travel companion',
                  style: TextStyle(
                    fontSize: 16.fSize,
                    fontFamily: 'PoppinsRegular',
                    color: appTheme.blackCustom.withOpacity(0.6),
                  ),
                ),

                SizedBox(height: 60.h),

                // Loading indicator
                SizedBox(
                  width: 32.h,
                  height: 32.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      appTheme.colorFF0373,
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Loading text
                Text(
                  'Initializing...',
                  style: TextStyle(
                    fontSize: 14.fSize,
                    fontFamily: 'PoppinsRegular',
                    color: appTheme.blackCustom.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
