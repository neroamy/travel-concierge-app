import 'package:flutter/material.dart';
import '../../../core/app_export.dart';

class ChangePasswordModal extends StatefulWidget {
  final Function(PasswordChangeRequest) onPasswordChange;

  const ChangePasswordModal({
    super.key,
    required this.onPasswordChange,
  });

  @override
  State<ChangePasswordModal> createState() => _ChangePasswordModalState();
}

class _ChangePasswordModalState extends State<ChangePasswordModal> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final request = PasswordChangeRequest(
      currentPassword: _currentPasswordController.text.trim(),
      newPassword: _newPasswordController.text.trim(),
      confirmPassword: _confirmPasswordController.text.trim(),
    );

    await widget.onPasswordChange(request);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24.h),
        decoration: BoxDecoration(
          color: appTheme.whiteCustom,
          borderRadius: BorderRadius.circular(16.h),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            SizedBox(height: 24.h),

            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Current Password
                  _buildPasswordField(
                    controller: _currentPasswordController,
                    label: 'Current Password',
                    hintText: 'Enter your current password',
                    isVisible: _isCurrentPasswordVisible,
                    onVisibilityToggle: () => setState(() {
                      _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                    }),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Current password is required';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16.h),

                  // New Password
                  _buildPasswordField(
                    controller: _newPasswordController,
                    label: 'New Password',
                    hintText: 'Enter your new password',
                    isVisible: _isNewPasswordVisible,
                    onVisibilityToggle: () => setState(() {
                      _isNewPasswordVisible = !_isNewPasswordVisible;
                    }),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'New password is required';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16.h),

                  // Confirm Password
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hintText: 'Confirm your new password',
                    isVisible: _isConfirmPasswordVisible,
                    onVisibilityToggle: () => setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    }),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // Buttons
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Change Password',
          style: TextStyle(
            fontSize: 20.fSize,
            fontWeight: FontWeight.w600,
            color: appTheme.blackCustom,
            fontFamily: 'Poppins',
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(
            Icons.close,
            size: 24.h,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.fSize,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          validator: validator,
          style: TextStyle(
            fontSize: 16.fSize,
            color: appTheme.blackCustom,
            fontFamily: 'Poppins',
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 16.fSize,
              color: Colors.grey[500],
              fontFamily: 'Poppins',
            ),
            suffixIcon: GestureDetector(
              onTap: onVisibilityToggle,
              child: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey[600],
                size: 20.h,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.h),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.h),
              borderSide: BorderSide(color: appTheme.colorFF0373, width: 2.h),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.h),
              borderSide: BorderSide(color: Colors.red, width: 1.h),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.h),
              borderSide: BorderSide(color: Colors.red, width: 2.h),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.h,
              vertical: 16.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        // Cancel Button
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12.h),
              ),
              child: Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16.fSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        ),

        SizedBox(width: 16.h),

        // Save Button
        Expanded(
          child: GestureDetector(
            onTap: _isLoading ? null : _handleSubmit,
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey[400] : appTheme.colorFF0373,
                borderRadius: BorderRadius.circular(12.h),
              ),
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        width: 20.h,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: appTheme.whiteCustom,
                        ),
                      )
                    : Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 16.fSize,
                          fontWeight: FontWeight.w600,
                          color: appTheme.whiteCustom,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
