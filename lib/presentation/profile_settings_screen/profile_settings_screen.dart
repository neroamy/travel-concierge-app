import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/safe_avatar_image.dart';
import './widgets/change_password_modal.dart';
import 'dart:async';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();

  // Form controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _interestsController = TextEditingController();

  // Form controllers for extended fields
  final _passportNationalityController = TextEditingController();
  final _seatPreferenceController = TextEditingController();
  final _foodPreferenceController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _likesController = TextEditingController();
  final _dislikesController = TextEditingController();
  final _priceSensitivityController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _localPreferModeController = TextEditingController();

  bool _isLoading = false;
  UserProfile? _currentProfile;

  // Add completer to track logout operation
  Completer<void>? _logoutCompleter;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    // Dispose controllers
    _usernameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _interestsController.dispose();
    _passportNationalityController.dispose();
    _seatPreferenceController.dispose();
    _foodPreferenceController.dispose();
    _allergiesController.dispose();
    _likesController.dispose();
    _dislikesController.dispose();
    _priceSensitivityController.dispose();
    _homeAddressController.dispose();
    _localPreferModeController.dispose();

    // Cancel any pending logout operation
    _logoutCompleter?.complete();

    super.dispose();
  }

  /// Load user profile data
  void _loadProfile() async {
    final profile = _profileService.currentProfile;
    if (profile != null && mounted) {
      setState(() {
        _currentProfile = profile;
        _usernameController.text = profile.username;
        _emailController.text = profile.email;
        _addressController.text = profile.address;
        _interestsController.text = profile.interests;
        _passportNationalityController.text = profile.passportNationality ?? '';
        _seatPreferenceController.text = profile.seatPreference ?? '';
        _foodPreferenceController.text = profile.foodPreference ?? '';
        _allergiesController.text = (profile.allergies ?? []).join(', ');
        _likesController.text = (profile.likes ?? []).join(', ');
        _dislikesController.text = (profile.dislikes ?? []).join(', ');
        _priceSensitivityController.text =
            (profile.priceSensitivity ?? []).join(', ');
        _homeAddressController.text = profile.homeAddress ?? '';
        _localPreferModeController.text = profile.localPreferMode ?? '';
      });
    } else {
      // Show error if profile is missing
      if (mounted) {
        _showErrorMessage(
            'Không thể tải thông tin hồ sơ. Vui lòng đăng nhập lại.');
      }
    }
  }

  /// Handle save settings
  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    // Parse list fields from comma-separated input
    List<String>? parseList(String text) {
      final trimmed = text.trim();
      if (trimmed.isEmpty) return null;
      return trimmed
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final request = ProfileUpdateRequest(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      interests: _interestsController.text.trim(),
      passportNationality: _passportNationalityController.text.trim().isEmpty
          ? null
          : _passportNationalityController.text.trim(),
      seatPreference: _seatPreferenceController.text.trim().isEmpty
          ? null
          : _seatPreferenceController.text.trim(),
      foodPreference: _foodPreferenceController.text.trim().isEmpty
          ? null
          : _foodPreferenceController.text.trim(),
      allergies: parseList(_allergiesController.text),
      likes: parseList(_likesController.text),
      dislikes: parseList(_dislikesController.text),
      priceSensitivity: parseList(_priceSensitivityController.text),
      homeAddress: _homeAddressController.text.trim().isEmpty
          ? null
          : _homeAddressController.text.trim(),
      localPreferMode: _localPreferModeController.text.trim().isEmpty
          ? null
          : _localPreferModeController.text.trim(),
    );

    try {
      final response = await _profileService.updateProfile(request);

      if (!mounted) return;

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
    } catch (e) {
      print('❌ Error saving profile: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showErrorMessage('Failed to update profile. Please try again.');
    }
  }

  /// Handle password change
  void _handlePasswordChange() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => ChangePasswordModal(
        onPasswordChange: (request) async {
          try {
            final response = await _profileService.changePassword(request);

            // Close modal
            if (mounted) {
              Navigator.of(context).pop();
            }

            // Show result message only if widget is still mounted
            if (mounted) {
              if (response.success) {
                _showSuccessMessage('Password changed successfully');
              } else {
                _showErrorMessage(response.message);
              }
            }
          } catch (e) {
            print('❌ Error changing password: $e');

            // Close modal
            if (mounted) {
              Navigator.of(context).pop();
            }

            // Show error message
            if (mounted) {
              _showErrorMessage('Failed to change password. Please try again.');
            }
          }
        },
      ),
    );
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    if (!mounted) return;

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
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Handle logout with improved error handling
  void _handleLogout() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ),
          TextButton(
            onPressed: () => _performLogout(dialogContext),
            child: Text(
              'Logout',
              style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Perform logout operation with proper lifecycle management
  Future<void> _performLogout(BuildContext dialogContext) async {
    // Create completer to track operation
    _logoutCompleter = Completer<void>();

    try {
      // Close dialog first
      Navigator.of(dialogContext).pop();

      // Only proceed if widget is still mounted
      if (!mounted) return;

      // Show loading state
      setState(() {
        _isLoading = true;
      });

      // Perform logout with timeout
      await Future.any([
        _authService.logout(),
        Future.delayed(Duration(seconds: 10)), // 10 second timeout
        _logoutCompleter!.future, // Cancel if widget disposed
      ]);

      // Check if logout was cancelled (widget disposed)
      if (_logoutCompleter!.isCompleted) {
        print('🚫 Logout cancelled - widget disposed');
        return;
      }

      // Only navigate if widget is still mounted and logout wasn't cancelled
      if (mounted && !_logoutCompleter!.isCompleted) {
        // Use schedulerBinding to ensure navigation happens after frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.signInScreen,
              (route) => false,
            );
          }
        });
      }
    } catch (e) {
      print('❌ Logout error: $e');

      // Reset loading state if widget is still mounted
      if (mounted && !_logoutCompleter!.isCompleted) {
        setState(() {
          _isLoading = false;
        });

        _showErrorMessage('Logout failed. Please try again.');
      }
    } finally {
      // Complete the logout operation
      if (!_logoutCompleter!.isCompleted) {
        _logoutCompleter!.complete();
      }
    }
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

                      SizedBox(height: 24.h),

                      // Passport Nationality
                      _buildInputField(
                        controller: _passportNationalityController,
                        label: 'Passport Nationality',
                        hintText: 'Enter your passport nationality',
                        icon: Icons.flag_outlined,
                      ),

                      SizedBox(height: 24.h),

                      // Seat Preference
                      _buildInputField(
                        controller: _seatPreferenceController,
                        label: 'Seat Preference',
                        hintText: 'e.g. window, aisle',
                        icon: Icons.event_seat_outlined,
                      ),

                      SizedBox(height: 24.h),

                      // Food Preference
                      _buildInputField(
                        controller: _foodPreferenceController,
                        label: 'Food Preference',
                        hintText: 'e.g. Japanese cuisine',
                        icon: Icons.restaurant_outlined,
                      ),

                      SizedBox(height: 24.h),

                      // Allergies
                      _buildInputField(
                        controller: _allergiesController,
                        label: 'Allergies',
                        hintText: 'Comma-separated (e.g. peanuts, gluten)',
                        icon: Icons.warning_amber_outlined,
                      ),

                      SizedBox(height: 24.h),

                      // Likes
                      _buildInputField(
                        controller: _likesController,
                        label: 'Likes',
                        hintText: 'Comma-separated (e.g. beaches, museums)',
                        icon: Icons.thumb_up_outlined,
                      ),

                      SizedBox(height: 24.h),

                      // Dislikes
                      _buildInputField(
                        controller: _dislikesController,
                        label: 'Dislikes',
                        hintText: 'Comma-separated (e.g. remote locations)',
                        icon: Icons.thumb_down_outlined,
                      ),

                      SizedBox(height: 24.h),

                      // Price Sensitivity
                      _buildInputField(
                        controller: _priceSensitivityController,
                        label: 'Price Sensitivity',
                        hintText: 'Comma-separated (e.g. mid-range, luxury)',
                        icon: Icons.attach_money_outlined,
                      ),

                      SizedBox(height: 24.h),

                      // Home Address
                      _buildInputField(
                        controller: _homeAddressController,
                        label: 'Home Address',
                        hintText: 'Enter your home address',
                        icon: Icons.home_outlined,
                      ),

                      SizedBox(height: 24.h),

                      // Local Prefer Mode
                      _buildInputField(
                        controller: _localPreferModeController,
                        label: 'Local Prefer Mode',
                        hintText: 'e.g. drive, walk',
                        icon: Icons.directions_car_outlined,
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
            'Settings',
            style: TextStyle(
              fontSize: 20.fSize,
              fontWeight: FontWeight.w600,
              color: appTheme.blackCustom,
              fontFamily: 'PoppinsSemiBold',
            ),
          ),

          Spacer(),

          // User Avatar
          UserAvatarImage(
            imageUrl: _profileService.getSafeAvatarUrl(),
            username: _currentProfile?.username,
            size: 48.h,
          ),

          SizedBox(width: 16.h),

          // Logout Button
          GestureDetector(
            onTap: _handleLogout,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.h),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.logout,
                    size: 16.h,
                    color: Colors.red.shade600,
                  ),
                  SizedBox(width: 4.h),
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 12.fSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade600,
                      fontFamily: 'PoppinsSemiBold',
                    ),
                  ),
                ],
              ),
            ),
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                      appTheme.whiteCustom,
                    ),
                  ),
                )
              : Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16.fSize,
                    fontWeight: FontWeight.w600,
                    color: appTheme.whiteCustom,
                    fontFamily: 'PoppinsSemiBold',
                  ),
                ),
        ),
      ),
    );
  }
}
