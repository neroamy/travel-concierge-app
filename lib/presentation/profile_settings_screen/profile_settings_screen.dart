import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/services/profile_service.dart';
import './widgets/change_password_modal.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();

  // Form controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _interestsController = TextEditingController();

  bool _isLoading = false;
  UserProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  /// Load user profile data
  void _loadProfile() async {
    final profile = _profileService.currentProfile;
    if (profile != null) {
      setState(() {
        _currentProfile = profile;
        _usernameController.text = profile.username;
        _emailController.text = profile.email;
        _addressController.text = profile.address;
        _interestsController.text = profile.interests;
      });
    }
  }

  /// Handle save settings
  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final request = ProfileUpdateRequest(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      interests: _interestsController.text.trim(),
    );

    final response = await _profileService.updateProfile(request);

    setState(() {
      _isLoading = false;
    });

    if (response.success) {
      // Show success message
      _showSuccessMessage('Profile updated successfully');
      // Update current profile
      _loadProfile();
    } else {
      // Show error message
      _showErrorMessage(response.message);
    }
  }

  /// Handle password change
  void _handlePasswordChange() {
    showDialog(
      context: context,
      builder: (context) => ChangePasswordModal(
        onPasswordChange: (request) async {
          final response = await _profileService.changePassword(request);
          Navigator.of(context).pop();

          if (response.success) {
            _showSuccessMessage('Password changed successfully');
          } else {
            _showErrorMessage(response.message);
          }
        },
      ),
    );
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error message
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteCustom,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 32.h),

                      // Username Field
                      _buildInputField(
                        controller: _usernameController,
                        label: 'Username',
                        hintText: 'Enter your username',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Username is required';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 24.h),

                      // Email Field
                      _buildInputField(
                        controller: _emailController,
                        label: 'E-mail address',
                        hintText: 'Enter your email address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!ProfileService.isValidEmail(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 24.h),

                      // Password Field
                      _buildPasswordField(),

                      SizedBox(height: 24.h),

                      // Address Field
                      _buildInputField(
                        controller: _addressController,
                        label: 'Address',
                        hintText: 'Enter your address',
                        icon: Icons.location_on_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Address is required';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 24.h),

                      // Interests Field
                      _buildInputField(
                        controller: _interestsController,
                        label: 'Interests',
                        hintText: 'Enter your travel interests',
                        icon: Icons.favorite_outline,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Interests are required';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 40.h),

                      // Save Button
                      _buildSaveButton(),

                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build header with back button and title
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 16.h),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.arrow_back_ios,
              size: 24.h,
              color: appTheme.blackCustom,
            ),
          ),

          SizedBox(width: 16.h),

          // Title
          Text(
            _currentProfile?.username ?? 'Profile Settings',
            style: TextStyle(
              fontSize: 20.fSize,
              fontWeight: FontWeight.w600,
              color: appTheme.blackCustom,
              fontFamily: 'Poppins',
            ),
          ),

          const Spacer(),

          // User Avatar
          Container(
            width: 48.h,
            height: 48.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: appTheme.colorFF0373.withOpacity(0.1),
              image: _currentProfile?.avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_currentProfile!.avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _currentProfile?.avatarUrl == null
                ? Icon(
                    Icons.person,
                    color: appTheme.colorFF0373,
                    size: 24.h,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  /// Build input field
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
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
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12.h),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              // Icon
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.h),
                child: Icon(
                  icon,
                  color: Colors.grey[600],
                  size: 20.h,
                ),
              ),

              // Input Field
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
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
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16.h,
                      horizontal: 8.h,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build password field with change button
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontSize: 14.fSize,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12.h),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              // Lock Icon
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.h),
                child: Icon(
                  Icons.lock_outline,
                  color: Colors.grey[600],
                  size: 20.h,
                ),
              ),

              // Masked Password
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.h),
                  child: Text(
                    '••••••••••••••',
                    style: TextStyle(
                      fontSize: 16.fSize,
                      color: appTheme.blackCustom,
                      fontFamily: 'Poppins',
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),

              // Change Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.h),
                child: GestureDetector(
                  onTap: _handlePasswordChange,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.h,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: appTheme.colorFF0373,
                      borderRadius: BorderRadius.circular(8.h),
                    ),
                    child: Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 12.fSize,
                        fontWeight: FontWeight.w600,
                        color: appTheme.whiteCustom,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build save button
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleSave,
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          color: _isLoading ? Colors.grey[400] : appTheme.colorFF0373,
          borderRadius: BorderRadius.circular(16.h),
        ),
        child: Center(
          child: _isLoading
              ? SizedBox(
                  width: 24.h,
                  height: 24.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: appTheme.whiteCustom,
                  ),
                )
              : Text(
                  'Save Settings',
                  style: TextStyle(
                    fontSize: 18.fSize,
                    fontWeight: FontWeight.w600,
                    color: appTheme.whiteCustom,
                    fontFamily: 'Poppins',
                  ),
                ),
        ),
      ),
    );
  }
}
