import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// API Test Service for Travel Concierge
class ApiTestService {
  static const String _tag = 'ApiTestService';

  /// Test basic connectivity to the API server
  static Future<bool> testServerConnectivity() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.getHealthCheckUrl()),
            headers: ApiConfig.jsonHeaders,
          )
          .timeout(ApiConfig.connectionTimeout);

      print('$_tag: Health check response: ${response.statusCode}');
      print('$_tag: Response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('$_tag: Connectivity test failed: $e');
      return false;
    }
  }

  /// Test authentication endpoint
  static Future<bool> testAuthentication() async {
    try {
      final testCredentials = {
        'username': 'nero',
        'password': '1234@pass',
      };

      final response = await http
          .post(
            Uri.parse(ApiConfig.getLoginUrl()),
            headers: ApiConfig.jsonHeaders,
            body: jsonEncode(testCredentials),
          )
          .timeout(ApiConfig.connectionTimeout);

      print('$_tag: Login test response: ${response.statusCode}');
      print('$_tag: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 200 && data['data'] != null;
      }

      return false;
    } catch (e) {
      print('$_tag: Authentication test failed: $e');
      return false;
    }
  }

  /// Test AI agent endpoints
  static Future<bool> testAgentEndpoints() async {
    try {
      // Test agent status
      final statusResponse = await http
          .get(
            Uri.parse(ApiConfig.getAgentStatusUrl()),
            headers: ApiConfig.jsonHeaders,
          )
          .timeout(ApiConfig.connectionTimeout);

      print('$_tag: Agent status response: ${statusResponse.statusCode}');

      // Test sub-agents
      final subAgentsResponse = await http
          .get(
            Uri.parse(ApiConfig.getAgentSubAgentsUrl()),
            headers: ApiConfig.jsonHeaders,
          )
          .timeout(ApiConfig.connectionTimeout);

      print('$_tag: Sub-agents response: ${subAgentsResponse.statusCode}');

      return statusResponse.statusCode == 200 &&
          subAgentsResponse.statusCode == 200;
    } catch (e) {
      print('$_tag: Agent endpoints test failed: $e');
      return false;
    }
  }

  /// Test travel service endpoints
  static Future<bool> testTravelEndpoints() async {
    try {
      // Test travel recommendations
      final recommendationsResponse = await http
          .get(
            Uri.parse(ApiConfig.getTravelRecommendationsUrl()),
            headers: ApiConfig.jsonHeaders,
          )
          .timeout(ApiConfig.connectionTimeout);

      print(
          '$_tag: Travel recommendations response: ${recommendationsResponse.statusCode}');

      // Test tools status
      final toolsStatusResponse = await http
          .get(
            Uri.parse(ApiConfig.getTravelToolsStatusUrl()),
            headers: ApiConfig.jsonHeaders,
          )
          .timeout(ApiConfig.connectionTimeout);

      print('$_tag: Tools status response: ${toolsStatusResponse.statusCode}');

      return recommendationsResponse.statusCode == 200 &&
          toolsStatusResponse.statusCode == 200;
    } catch (e) {
      print('$_tag: Travel endpoints test failed: $e');
      return false;
    }
  }

  /// Run comprehensive API tests
  static Future<Map<String, bool>> runAllTests() async {
    print('$_tag: Starting API connectivity tests...');
    print('$_tag: Server URL: ${ApiConfig.baseUrl}');

    final results = <String, bool>{};

    // Test 1: Server connectivity
    results['server_connectivity'] = await testServerConnectivity();

    // Test 2: Authentication
    results['authentication'] = await testAuthentication();

    // Test 3: AI Agent endpoints
    results['agent_endpoints'] = await testAgentEndpoints();

    // Test 4: Travel service endpoints
    results['travel_endpoints'] = await testTravelEndpoints();

    // Print summary
    print('$_tag: Test Results Summary:');
    results.forEach((test, result) {
      final status = result ? '✅ PASS' : '❌ FAIL';
      print('$_tag: $test: $status');
    });

    return results;
  }

  /// Get server information
  static void printServerInfo() {
    print('$_tag: Server Information:');
    print('$_tag: Base URL: ${ApiConfig.baseUrl}');
    print('$_tag: Chat Base URL: ${ApiConfig.chatBaseUrl}');
    print('$_tag: Health Check URL: ${ApiConfig.getHealthCheckUrl()}');
    print('$_tag: Login URL: ${ApiConfig.getLoginUrl()}');
    print('$_tag: Agent Chat URL: ${ApiConfig.getAgentChatUrl()}');
    print('$_tag: Travel Health URL: ${ApiConfig.getHealthCheckUrl()}');
  }
}
