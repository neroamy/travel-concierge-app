import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_models.dart';
import 'api_config.dart';
import 'profile_service.dart';
import 'global_chat_service.dart';
import 'plan_storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Authentication state
  bool _isLoggedIn = false;
  UserData? _currentUser;
  String? _authToken;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  UserData? get currentUser => _currentUser;
  String? get authToken => _authToken;

  // SharedPreferences keys
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserData = 'user_data';
  static const String _keyAuthToken = 'auth_token';

  /// Initialize authentication state from stored data
  Future<void> initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      _authToken = prefs.getString(_keyAuthToken);

      final userDataString = prefs.getString(_keyUserData);
      if (userDataString != null) {
        final userDataJson = jsonDecode(userDataString);
        _currentUser = UserData.fromJson(userDataJson);
      }

      print(
          '🔐 Auth initialized - Logged in: $_isLoggedIn, User: ${_currentUser?.username}');
    } catch (e) {
      print('❌ Error initializing auth: $e');
      await _clearAuthData();
    }
  }

  /// Login with username and password
  Future<LoginResponse> login(String username, String password) async {
    try {
      print('🚀 Attempting login for username: $username');

      final loginRequest = LoginRequest(
        username: username,
        password: password,
      );

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(loginRequest.toJson()),
      );

      print('📡 Login response status: ${response.statusCode}');
      print('📡 Login response body: ${response.body}');

      final responseData = jsonDecode(response.body);
      // Sửa lại để lấy đúng dữ liệu user từ response['data']['user'] và token từ response['data']['token']
      final data = responseData['data'];
      final userJson = data != null ? data['user'] : null;
      final token = data != null ? data['token'] : null;
      if (response.statusCode == 200 &&
          userJson != null &&
          userJson['user_profile_uuid'] != null) {
        final loginResponse = LoginResponse(
          success: true,
          message: responseData['msg'] ?? '',
          user: UserData.fromJson(userJson),
          token: token,
        );
        if (loginResponse.user == null ||
            loginResponse.user!.userProfileUuid.isEmpty) {
          throw Exception('user_profile_uuid missing in login response');
        }
        // Store authentication data
        await _storeAuthData(loginResponse);
        // Sync with ProfileService
        await _syncWithProfileService();
        // Sync with GlobalChatService
        await _syncWithGlobalChatService();
        print('✅ Login successful for user: ${_currentUser?.username}');
        return loginResponse;
      } else {
        // Lấy thông báo lỗi từ msg nếu có
        final errorMsg = responseData['msg'] ??
            'Login failed: user_profile_uuid missing in response.';
        print('❌ Login failed: $errorMsg');
        return LoginResponse(
          success: false,
          message: errorMsg,
        );
      }
    } catch (e) {
      print('❌ Login error: $e');
      return LoginResponse(
        success: false,
        message: 'Network error. Please check your connection and try again.',
      );
    }
  }

  /// Store authentication data locally
  Future<void> _storeAuthData(LoginResponse loginResponse) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isLoggedIn = true;
      _currentUser = loginResponse.user;
      _authToken = loginResponse.token;

      await prefs.setBool(_keyIsLoggedIn, _isLoggedIn);
      await prefs.setString(_keyAuthToken, _authToken ?? '');

      if (_currentUser != null) {
        await prefs.setString(_keyUserData, jsonEncode(_currentUser!.toJson()));
      }

      print('💾 Auth data stored successfully');
    } catch (e) {
      print('❌ Error storing auth data: $e');
      throw e;
    }
  }

  /// Sync user data with ProfileService
  Future<void> _syncWithProfileService() async {
    try {
      if (_currentUser != null) {
        final profileService = ProfileService();

        // Update profile with login data
        await profileService.updateProfileFromAuth(
          username: _currentUser!.username,
          email: _currentUser!.email,
          fullName: _currentUser!.fullName,
          avatarUrl: _currentUser!.avatarUrl,
          address: _currentUser!.address,
          interests: _currentUser!.interests,
        );

        print('🔄 Profile synced with auth data');
      }
    } catch (e) {
      print('❌ Error syncing with ProfileService: $e');
    }
  }

  /// Sync user data with GlobalChatService
  Future<void> _syncWithGlobalChatService() async {
    try {
      if (_currentUser != null) {
        final globalChatService = GlobalChatService();

        // Update chat service with user info
        await globalChatService.updateUserInfo(
          displayName: _currentUser!.fullName ?? _currentUser!.username,
          avatarUrl: _currentUser!.avatarUrl,
        );

        print('🔄 GlobalChatService synced with auth data');
      }
    } catch (e) {
      print('❌ Error syncing with GlobalChatService: $e');
    }
  }

  /// Logout user (with server call)
  Future<void> logout() async {
    try {
      print('🔓 Logging out user: ${_currentUser?.username}');

      // Call server logout endpoint if we have a token
      if (_authToken != null) {
        try {
          final response = await http.post(
            Uri.parse('${ApiConfig.baseUrl}/auth/logout/'),
            headers: getAuthHeaders(),
          );

          print('📡 Logout response status: ${response.statusCode}');
          if (response.statusCode == 200) {
            print('✅ Server logout successful');
          } else {
            print('⚠️ Server logout failed, continuing with local logout');
          }
        } catch (e) {
          print('⚠️ Server logout error: $e, continuing with local logout');
        }
      }

      await _clearAuthData();

      // Clear ProfileService data
      final profileService = ProfileService();
      await profileService.clearProfile();

      // Clear GlobalChatService session
      final globalChatService = GlobalChatService();
      await globalChatService.clearSession();

      // Clear local plan nếu chưa lưu DB
      final planStorage = PlanStorageService();
      final isSaved = await planStorage.isPlanSaved();
      if (!isSaved) {
        await planStorage.clearCurrentPlan();
        print('🗑️ Local plan cleared on logout (not saved to DB)');
      } else {
        print('✅ Plan already saved to DB, no need to clear local');
      }

      print('✅ Logout completed');
    } catch (e) {
      print('❌ Error during logout: $e');
    }
  }

  /// Clear all authentication data
  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isLoggedIn = false;
      _currentUser = null;
      _authToken = null;

      await prefs.remove(_keyIsLoggedIn);
      await prefs.remove(_keyUserData);
      await prefs.remove(_keyAuthToken);

      print('🗑️ Auth data cleared');
    } catch (e) {
      print('❌ Error clearing auth data: $e');
    }
  }

  /// Get authorization header for API calls
  Map<String, String> getAuthHeaders() {
    if (_authToken != null) {
      return {
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Check if user session is valid (with server verification)
  Future<bool> isSessionValid() async {
    if (!_isLoggedIn || _authToken == null) {
      return false;
    }

    try {
      // Call server verify endpoint
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify/'),
        headers: getAuthHeaders(),
      );

      print('📡 Token verification status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          print('✅ Token verification successful');
          return true;
        }
      }

      // Token is invalid, clear auth data
      print('❌ Token verification failed, clearing auth data');
      await _clearAuthData();
      return false;
    } catch (e) {
      print('❌ Error verifying session: $e');
      // On network error, assume session is still valid
      return true;
    }
  }
}
