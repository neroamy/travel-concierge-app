import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Connection Test Service for Travel Concierge App
/// This service helps test connectivity to all production endpoints
class ConnectionTestService {
  static const Duration timeout = Duration(seconds: 10);

  /// Test Django server connection
  static Future<Map<String, dynamic>> testDjangoServer() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.getHealthCheckUrl()))
          .timeout(timeout);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'url': ApiConfig.getHealthCheckUrl(),
        'response': response.body,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'url': ApiConfig.getHealthCheckUrl(),
      };
    }
  }

  /// Test authentication endpoint
  static Future<Map<String, dynamic>> testAuthEndpoint() async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.getLoginUrl()),
            headers: ApiConfig.jsonHeaders,
            body: jsonEncode({
              'username': 'nero',
              'password': '1234@pass',
            }),
          )
          .timeout(timeout);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'url': ApiConfig.getLoginUrl(),
        'response': response.body,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'url': ApiConfig.getLoginUrl(),
      };
    }
  }

  /// Test ADK Agent server connection
  static Future<Map<String, dynamic>> testAdkAgentServer() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.chatBaseUrl}/health/'))
          .timeout(timeout);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'url': '${ApiConfig.chatBaseUrl}/health/',
        'response': response.body,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'url': '${ApiConfig.chatBaseUrl}/health/',
      };
    }
  }

  /// Test all endpoints
  static Future<Map<String, dynamic>> testAllEndpoints() async {
    final results = <String, Map<String, dynamic>>{};

    // Test Django server
    results['django_server'] = await testDjangoServer();

    // Test authentication
    results['auth_endpoint'] = await testAuthEndpoint();

    // Test ADK Agent server
    results['adk_agent_server'] = await testAdkAgentServer();

    // Calculate overall success
    final allSuccessful =
        results.values.every((result) => result['success'] == true);

    return {
      'overall_success': allSuccessful,
      'results': results,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get all configured URLs for debugging
  static Map<String, String> getAllUrls() {
    return {
      'base_url': ApiConfig.baseUrl,
      'chat_base_url': ApiConfig.chatBaseUrl,
      'health_check': ApiConfig.getHealthCheckUrl(),
      'login': ApiConfig.getLoginUrl(),
      'verify_token': ApiConfig.getVerifyTokenUrl(),
      'logout': ApiConfig.getLogoutUrl(),
      'user_profile': ApiConfig.getUserProfileUrl(),
      'agent_chat': ApiConfig.getAgentChatUrl(),
      'agent_status': ApiConfig.getAgentStatusUrl(),
      'agent_sub_agents': ApiConfig.getAgentSubAgentsUrl(),
      'travel_recommendations': ApiConfig.getTravelRecommendationsUrl(),
      'travel_tools_status': ApiConfig.getTravelToolsStatusUrl(),
    };
  }

  /// Print all URLs for debugging
  static void printAllUrls() {
    print('=== Travel Concierge App URLs ===');
    print('Environment: ${ApiConfig.isProduction ? "Production" : "Local"}');
    print('');

    final urls = getAllUrls();
    urls.forEach((key, url) {
      print('$key: $url');
    });

    print('');
    print('=== End URLs ===');
  }
}
