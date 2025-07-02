import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../core/services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle login button press
  Future<void> _handleLogin() async {
    if (_usernameController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both username and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.success) {
        // Login successful - navigate to main screen
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.travelExplorationScreen,
          );
        }
      } else {
        // Login failed - show error
        setState(() {
          _errorMessage = response.message ?? 'Login failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Network error. Please check your connection and try again.';
      });
    }
  }

  /// Handle social login (mock implementation)
  void _handleSocialLogin(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider login will be implemented soon'),
        backgroundColor: appTheme.colorFF0373,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteCustom,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 55.h),
              _buildTitle(),
              SizedBox(height: 63.h),
              _buildUsernameField(),
              SizedBox(height: 16.h),
              _buildPasswordField(),
              if (_errorMessage != null) ...[
                SizedBox(height: 16.h),
                _buildErrorMessage(),
              ],
              SizedBox(height: 32.h),
              _buildSocialDivider(),
              SizedBox(height: 24.h),
              _buildSocialButtons(),
              SizedBox(height: 364.h),
              _buildLoginButton(),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Build title section
  Widget _buildTitle() {
    return Text(
      'Sign in',
      style: TextStyle(
        fontSize: 30.fSize,
        fontWeight: FontWeight.w600,
        fontFamily: 'PoppinsSemiBold',
        color: appTheme.blackCustom,
      ),
    );
  }

  /// Build username input field
  Widget _buildUsernameField() {
    return Container(
      height: 51.h,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE9E9E9),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(36.h),
      ),
      child: Row(
        children: [
          SizedBox(width: 19.h),
          Icon(
            Icons.person_outline,
            size: 22.h,
            color: const Color(0xFFADADAD),
          ),
          SizedBox(width: 11.h),
          Expanded(
            child: TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: 'Enter username',
                hintStyle: TextStyle(
                  fontSize: 16.fSize,
                  fontFamily: 'PoppinsRegular',
                  color: const Color(0xFFADADAD),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15.h),
              ),
              style: TextStyle(
                fontSize: 16.fSize,
                fontFamily: 'PoppinsRegular',
                color: appTheme.blackCustom,
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
            ),
          ),
          SizedBox(width: 19.h),
        ],
      ),
    );
  }

  /// Build password input field
  Widget _buildPasswordField() {
    return Container(
      height: 51.h,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE9E9E9),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(36.h),
      ),
      child: Row(
        children: [
          SizedBox(width: 19.h),
          Icon(
            Icons.lock_outline,
            size: 22.h,
            color: const Color(0xFFADADAD),
          ),
          SizedBox(width: 11.h),
          Expanded(
            child: TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: 'Enter password',
                hintStyle: TextStyle(
                  fontSize: 16.fSize,
                  fontFamily: 'PoppinsRegular',
                  color: const Color(0xFFADADAD),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15.h),
              ),
              style: TextStyle(
                fontSize: 16.fSize,
                fontFamily: 'PoppinsRegular',
                color: appTheme.blackCustom,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleLogin(),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
            child: Container(
              padding: EdgeInsets.all(8.h),
              child: Icon(
                _isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20.h,
                color: const Color(0xFFADADAD),
              ),
            ),
          ),
          SizedBox(width: 11.h),
        ],
      ),
    );
  }

  /// Build error message
  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8.h),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 20.h,
          ),
          SizedBox(width: 8.h),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14.fSize,
                fontFamily: 'PoppinsRegular',
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build social login divider
  Widget _buildSocialDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.h,
            color: const Color(0xFFE8E8E8),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.h),
          child: Text(
            'Or continue with',
            style: TextStyle(
              fontSize: 16.fSize,
              fontFamily: 'PoppinsRegular',
              color: appTheme.blackCustom,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1.h,
            color: const Color(0xFFE8E8E8),
          ),
        ),
      ],
    );
  }

  /// Build social login buttons
  Widget _buildSocialButtons() {
    return Column(
      children: [
        // Sign with Google
        GestureDetector(
          onTap: () => _handleSocialLogin('Google'),
          child: Container(
            width: double.infinity,
            height: 54.h,
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(36.h),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.g_mobiledata,
                  color: appTheme.whiteCustom,
                  size: 22.h,
                ),
                SizedBox(width: 8.h),
                Text(
                  'Sign with Google',
                  style: TextStyle(
                    fontSize: 16.fSize,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'PoppinsMedium',
                    color: appTheme.whiteCustom,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        // Sign with Facebook
        GestureDetector(
          onTap: () => _handleSocialLogin('Facebook'),
          child: Container(
            width: double.infinity,
            height: 54.h,
            decoration: BoxDecoration(
              color: const Color(0xFF3B5896),
              borderRadius: BorderRadius.circular(36.h),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.facebook,
                  color: appTheme.whiteCustom,
                  size: 22.h,
                ),
                SizedBox(width: 8.h),
                Text(
                  'Sign with Facebook',
                  style: TextStyle(
                    fontSize: 16.fSize,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'PoppinsMedium',
                    color: appTheme.whiteCustom,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build login button
  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
      child: Container(
        width: double.infinity,
        height: 54.h,
        decoration: BoxDecoration(
          color: _isLoading
              ? appTheme.colorFF0373.withOpacity(0.6)
              : appTheme.colorFF0373,
          borderRadius: BorderRadius.circular(36.h),
        ),
        child: Center(
          child: _isLoading
              ? SizedBox(
                  width: 24.h,
                  height: 24.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      appTheme.whiteCustom,
                    ),
                  ),
                )
              : Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 16.fSize,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'PoppinsMedium',
                    color: appTheme.whiteCustom,
                  ),
                ),
        ),
      ),
    );
  }
}
