import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_models.dart';
import 'api_config.dart';
import 'auth_service.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  UserProfile? _currentProfile;

  /// Get current user profile
  UserProfile? get currentProfile => _currentProfile;

  /// Check if user has profile
  bool get hasProfile => _currentProfile != null;

  /// Initialize profile from storage or API
  Future<bool> initializeProfile() async {
    try {
      // Try to load from local storage first
      await _loadProfileFromStorage();

      if (_currentProfile != null) {
        print('✅ Profile loaded from storage: ${_currentProfile!.username}');
        return true;
      }

      // If no local profile, try to fetch from API
      final success = await fetchProfileFromAPI();
      if (success) {
        await _saveProfileToStorage();
        print('✅ Profile fetched from API: ${_currentProfile!.username}');
        return true;
      }

      // Create default profile if none exists
      _createDefaultProfile();
      await _saveProfileToStorage();
      print('✅ Created default profile: ${_currentProfile!.username}');
      return true;
    } catch (e) {
      print('❌ Error initializing profile: $e');
      return false;
    }
  }

  /// Update user profile
  Future<ProfileApiResponse> updateProfile(ProfileUpdateRequest request) async {
    try {
      final authService = AuthService();
      final user = authService.currentUser;
      if (user == null || user.userProfileUuid.isEmpty) {
        return ProfileApiResponse(
          success: false,
          message: 'user_profile_uuid missing. Cannot update profile.',
        );
      }
      final url =
          '${ApiConfig.baseUrl}/user_manager/profile/${user.userProfileUuid}/update/';
      final response = await http.put(
        Uri.parse(url),
        headers: authService.getAuthHeaders(),
        body: jsonEncode(request.toJson()),
      );
      print('📡 Profile update response status: \\${response.statusCode}');
      print('📡 Profile update response body: \\${response.body}');
      final apiResponse =
          ProfileApiResponse.fromJson(jsonDecode(response.body));
      if (response.statusCode == 200 &&
          apiResponse.success &&
          apiResponse.data != null) {
        _currentProfile = apiResponse.data!;
        await _saveProfileToStorage();
        print('✅ Profile updated successfully: \\${_currentProfile!.username}');
      }
      return apiResponse;
    } catch (e) {
      print('❌ Error updating profile: $e');
      return ProfileApiResponse(
        success: false,
        message: 'Network error: Could not update profile',
      );
    }
  }

  /// Change password
  Future<ProfileApiResponse> changePassword(
      PasswordChangeRequest request) async {
    try {
      final authService = AuthService();
      final user = authService.currentUser;
      if (user == null || user.id.isEmpty) {
        return ProfileApiResponse(
          success: false,
          message: 'user_uuid missing. Cannot change password.',
        );
      }
      final url = '${ApiConfig.baseUrl}/auth/${user.id}/change-password/';
      final response = await http.put(
        Uri.parse(url),
        headers: authService.getAuthHeaders(),
        body: jsonEncode(request.toJson()),
      );

      print('📡 Password change response status: ${response.statusCode}');
      print('📡 Password change response body: ${response.body}');

      final apiResponse =
          ProfileApiResponse.fromJson(jsonDecode(response.body));

      if (response.statusCode == 200 && apiResponse.success) {
        print('✅ Password changed successfully');
      }

      return apiResponse;
    } catch (e) {
      print('❌ Error changing password: $e');
      return ProfileApiResponse(
        success: false,
        message: 'Network error: Could not change password',
      );
    }
  }

  /// Get display name for chat
  String getDisplayName() {
    return _currentProfile?.username ?? 'User';
  }

  /// Get avatar URL for UI with validation
  String? getAvatarUrl() {
    final avatarUrl = _currentProfile?.avatarUrl;

    // Return null for invalid URLs to trigger fallback
    if (avatarUrl == null ||
        avatarUrl.isEmpty ||
        avatarUrl == 'null' ||
        avatarUrl.contains('example.com') ||
        !_isValidAvatarUrl(avatarUrl)) {
      return null;
    }

    return avatarUrl;
  }

  /// Validate avatar URL
  bool _isValidAvatarUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Get safe avatar URL for display (never returns invalid URLs)
  String? getSafeAvatarUrl() {
    return getAvatarUrl(); // This already validates
  }

  /// Load profile from local storage
  Future<void> _loadProfileFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('user_profile');

      if (profileJson != null) {
        final profileData = jsonDecode(profileJson);
        _currentProfile = UserProfile.fromJson(profileData);
      }
    } catch (e) {
      print('❌ Error loading profile from storage: $e');
    }
  }

  /// Save profile to local storage
  Future<void> _saveProfileToStorage() async {
    try {
      if (_currentProfile != null) {
        final prefs = await SharedPreferences.getInstance();
        final profileJson = jsonEncode(_currentProfile!.toJson());
        await prefs.setString('user_profile', profileJson);
      }
    } catch (e) {
      print('❌ Error saving profile to storage: $e');
    }
  }

  /// Fetch profile from API
  Future<bool> fetchProfileFromAPI() async {
    try {
      final authService = AuthService();
      final user = authService.currentUser;
      if (user == null || user.userProfileUuid.isEmpty) {
        throw Exception('user_profile_uuid missing. Cannot fetch profile.');
      }
      final url =
          '${ApiConfig.baseUrl}/user_manager/profile/${user.userProfileUuid}';
      final headers = authService.getAuthHeaders();
      print('🌐 [GET] Fetching user profile: URL = $url');
      print('🌐 [GET] Headers: $headers');
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      print('🌐 [GET] Response status: ${response.statusCode}');
      print('🌐 [GET] Response body: ${response.body}');
      if (response.statusCode == 200) {
        final profileData = jsonDecode(response.body)['data'];
        _currentProfile = UserProfile.fromJson(profileData);
        await _saveProfileToStorage();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error fetching profile from API: $e');
      return false;
    }
  }

  /// Create default profile
  void _createDefaultProfile() {
    final now = DateTime.now();
    _currentProfile = UserProfile(
      id: 'user_${now.millisecondsSinceEpoch}',
      username: 'Alan love',
      email: 'alanlovelq@gmail.com',
      address: 'Ha Noi, Viet Nam',
      interests: 'Travel, Photography, Food',
      avatarUrl: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update profile from authentication data
  Future<void> updateProfileFromAuth({
    required String username,
    required String email,
    String? fullName,
    String? avatarUrl,
    String? address,
    List<String>? interests,
  }) async {
    try {
      final now = DateTime.now();
      _currentProfile = UserProfile(
        id: _currentProfile?.id ?? 'user_${now.millisecondsSinceEpoch}',
        username: username,
        email: email,
        address: address ?? _currentProfile?.address ?? 'Ha Noi, Viet Nam',
        interests: interests?.join(', ') ??
            _currentProfile?.interests ??
            'Travel, Photography, Food',
        avatarUrl: avatarUrl ?? _currentProfile?.avatarUrl,
        createdAt: _currentProfile?.createdAt ?? now,
        updatedAt: now,
      );

      await _saveProfileToStorage();
      print('✅ Profile updated from auth data: $username');
    } catch (e) {
      print('❌ Error updating profile from auth: $e');
    }
  }

  /// Clear profile (for logout)
  Future<void> clearProfile() async {
    _currentProfile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_profile');
    print('🗑️ Profile cleared');
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    return password.length >= 8;
  }

  /// Get user scenario data for AI agent with extended preferences
  Map<String, dynamic> getUserScenarioData() {
    if (_currentProfile == null) return {};

    return {
      'user_name': _currentProfile!.username,
      'user_email': _currentProfile!.email,
      'user_location': _currentProfile!.address,
      'user_interests': _currentProfile!.interests,
      'user_preferences': {
        'passport_nationality':
            _currentProfile!.passportNationality ?? 'Vietnamese',
        'seat_preference': _currentProfile!.seatPreference ?? 'window',
        'food_preference': _currentProfile!.foodPreference ??
            'Japanese cuisine - Ramen, Sushi, Sashimi',
        'allergies': _currentProfile!.allergies ?? [],
        'likes': _currentProfile!.likes ??
            ['temples', 'beaches', 'mountains', 'museums'],
        'dislikes': _currentProfile!.dislikes ??
            ['remote locations', 'dangerous areas'],
        'price_sensitivity': _currentProfile!.priceSensitivity ?? ['mid-range'],
        'home_address':
            _currentProfile!.homeAddress ?? _currentProfile!.address,
        'local_prefer_mode': _currentProfile!.localPreferMode ?? 'drive',
      },
    };
  }
}
