import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiTestHelper {
  /// Test server connection
  static Future<Map<String, dynamic>> testConnection() async {
    final results = <String, dynamic>{};

    // Test main API server
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      results['main_api'] = {
        'status': response.statusCode,
        'reachable': response.statusCode == 200,
        'url': '${ApiConfig.baseUrl}/health',
      };
    } catch (e) {
      results['main_api'] = {
        'status': 'error',
        'reachable': false,
        'error': e.toString(),
        'url': '${ApiConfig.baseUrl}/health',
      };
    }

    // Test chat API server
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.chatBaseUrl}/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      results['chat_api'] = {
        'status': response.statusCode,
        'reachable': response.statusCode == 200,
        'url': '${ApiConfig.chatBaseUrl}/health',
      };
    } catch (e) {
      results['chat_api'] = {
        'status': 'error',
        'reachable': false,
        'error': e.toString(),
        'url': '${ApiConfig.chatBaseUrl}/health',
      };
    }

    return results;
  }

  /// Test authentication endpoints
  static Future<Map<String, dynamic>> testAuthEndpoints() async {
    final results = <String, dynamic>{};

    // Test login endpoint (should return 400 for missing credentials)
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/login/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({}),
          )
          .timeout(Duration(seconds: 5));

      results['login_endpoint'] = {
        'status': response.statusCode,
        'available': response.statusCode == 400, // Expecting validation error
        'url': '${ApiConfig.baseUrl}/auth/login/',
        'response': response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body,
      };
    } catch (e) {
      results['login_endpoint'] = {
        'status': 'error',
        'available': false,
        'error': e.toString(),
        'url': '${ApiConfig.baseUrl}/auth/login/',
      };
    }

    // Test verify endpoint (should return 401 for missing token)
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      results['verify_endpoint'] = {
        'status': response.statusCode,
        'available': response.statusCode == 401, // Expecting unauthorized
        'url': '${ApiConfig.baseUrl}/auth/verify/',
      };
    } catch (e) {
      results['verify_endpoint'] = {
        'status': 'error',
        'available': false,
        'error': e.toString(),
        'url': '${ApiConfig.baseUrl}/auth/verify/',
      };
    }

    return results;
  }

  /// Test profile endpoints
  static Future<Map<String, dynamic>> testProfileEndpoints() async {
    final results = <String, dynamic>{};

    // Test profile endpoint (should return 401 for missing token)
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      results['profile_endpoint'] = {
        'status': response.statusCode,
        'available': true, // Any response means endpoint exists
        'url': '${ApiConfig.baseUrl}/profile',
      };
    } catch (e) {
      results['profile_endpoint'] = {
        'status': 'error',
        'available': false,
        'error': e.toString(),
        'url': '${ApiConfig.baseUrl}/profile',
      };
    }

    return results;
  }

  /// Test with sample credentials (if provided in documentation)
  static Future<Map<String, dynamic>> testWithSampleCredentials() async {
    final results = <String, dynamic>{};

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/login/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': 'alan_love',
              'password': 'SecurePassword123!',
            }),
          )
          .timeout(Duration(seconds: 10));

      results['sample_login'] = {
        'status': response.statusCode,
        'success': response.statusCode == 200,
        'url': '${ApiConfig.baseUrl}/auth/login/',
        'response_preview': response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body,
      };

      // If login successful, try to get profile
      if (response.statusCode == 200) {
        final loginData = jsonDecode(response.body);
        final token = loginData['token'];

        if (token != null) {
          final profileResponse = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ).timeout(Duration(seconds: 5));

          results['sample_profile'] = {
            'status': profileResponse.statusCode,
            'success': profileResponse.statusCode == 200,
            'url': '${ApiConfig.baseUrl}/profile',
            'response_preview': profileResponse.body.length > 200
                ? '${profileResponse.body.substring(0, 200)}...'
                : profileResponse.body,
          };
        }
      }
    } catch (e) {
      results['sample_login'] = {
        'status': 'error',
        'success': false,
        'error': e.toString(),
        'url': '${ApiConfig.baseUrl}/auth/login/',
      };
    }

    return results;
  }

  /// Print comprehensive API test results
  static Future<void> runAllTests() async {
    print('\n🧪 === API CONNECTION TESTS ===\n');

    print('📡 Testing server connections...');
    final connectionResults = await testConnection();
    _printResults('CONNECTION', connectionResults);

    print('\n🔐 Testing authentication endpoints...');
    final authResults = await testAuthEndpoints();
    _printResults('AUTHENTICATION', authResults);

    print('\n👤 Testing profile endpoints...');
    final profileResults = await testProfileEndpoints();
    _printResults('PROFILE', profileResults);

    print('\n🔑 Testing with sample credentials...');
    final sampleResults = await testWithSampleCredentials();
    _printResults('SAMPLE LOGIN', sampleResults);

    print('\n✅ === TEST COMPLETED ===\n');
  }

  static void _printResults(String category, Map<String, dynamic> results) {
    results.forEach((key, value) {
      final status = value['status'] ?? 'unknown';
      final available =
          value['available'] ?? value['reachable'] ?? value['success'] ?? false;
      final icon = available ? '✅' : '❌';

      print('$icon $category - $key: $status');
      if (value['url'] != null) {
        print('   URL: ${value['url']}');
      }
      if (value['error'] != null) {
        print('   Error: ${value['error']}');
      }
      if (value['response_preview'] != null) {
        print('   Response: ${value['response_preview']}');
      }
      print('');
    });
  }
}
