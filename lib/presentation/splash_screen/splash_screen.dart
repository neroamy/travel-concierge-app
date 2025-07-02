import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../core/services/auth_service.dart';

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
    _initializeApp();
  }

  /// Initialize app and check authentication state
  Future<void> _initializeApp() async {
    try {
      // Show splash for at least 2 seconds for better UX
      await Future.delayed(const Duration(seconds: 2));

      // Initialize authentication service
      await _authService.initializeAuth();

      // Check if user is logged in and session is valid
      if (_authService.isLoggedIn) {
        final isSessionValid = await _authService.isSessionValid();

        if (isSessionValid) {
          // User is logged in and session is valid - go to main app
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.travelExplorationScreen,
            );
          }
          return;
        }
      }

      // User is not logged in or session is invalid - go to sign in
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.signInScreen,
        );
      }
    } catch (e) {
      print('❌ Error during app initialization: $e');

      // On error, default to sign in screen
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
