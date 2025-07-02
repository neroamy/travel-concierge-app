import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_models.dart';
import 'api_config.dart';

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
      final success = await _fetchProfileFromAPI();
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
      final url = '${ApiConfig.baseUrl}/profile/update';
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      final apiResponse =
          ProfileApiResponse.fromJson(jsonDecode(response.body));

      if (apiResponse.success && apiResponse.data != null) {
        _currentProfile = apiResponse.data!;
        await _saveProfileToStorage();

        print('✅ Profile updated successfully: ${_currentProfile!.username}');
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
      final url = '${ApiConfig.baseUrl}/profile/change-password';
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      final apiResponse =
          ProfileApiResponse.fromJson(jsonDecode(response.body));

      if (apiResponse.success) {
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

  /// Get avatar URL for UI
  String? getAvatarUrl() {
    return _currentProfile?.avatarUrl;
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
  Future<bool> _fetchProfileFromAPI() async {
    try {
      final url = '${ApiConfig.baseUrl}/profile';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final apiResponse =
            ProfileApiResponse.fromJson(jsonDecode(response.body));
        if (apiResponse.success && apiResponse.data != null) {
          _currentProfile = apiResponse.data!;
          return true;
        }
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

  /// Get user scenario data for AI agent
  Map<String, dynamic> getUserScenarioData() {
    if (_currentProfile == null) return {};

    return {
      'user_name': _currentProfile!.username,
      'user_email': _currentProfile!.email,
      'user_location': _currentProfile!.address,
      'user_interests': _currentProfile!.interests,
      'user_preferences': {
        'travel_style': 'Explorer',
        'budget_range': 'Mid-range',
        'accommodation': 'Hotel & Resort',
      },
    };
  }
}
