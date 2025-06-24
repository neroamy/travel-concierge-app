/// API Configuration for Travel Concierge Client
class ApiConfig {
  // Server Configuration
  // NOTE: Use PC's IP address when testing on real device
  // To find PC IP: run 'ipconfig' in cmd and look for Wi-Fi adapter IPv4 Address
  // Make sure PC and mobile device are on the same Wi-Fi network
  static const String baseUrl = 'http://192.168.1.7:8002';
  static const String appName = 'travel_concierge';

  // Endpoints
  static const String sessionEndpoint = '/apps/$appName/users';
  static const String messageEndpoint = '/run_sse';
  static const String docsEndpoint = '/docs';

  // HTTP Headers
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  static const Map<String, String> sseHeaders = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'text/event-stream',
  };

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Build full session URL
  static String getSessionUrl(String userId, String sessionId) {
    return '$baseUrl$sessionEndpoint/$userId/sessions/$sessionId';
  }

  // Build message URL
  static String getMessageUrl() {
    return '$baseUrl$messageEndpoint';
  }

  // Build API docs URL
  static String getDocsUrl() {
    return '$baseUrl$docsEndpoint';
  }

  // Helper method to test connection
  static String getHealthCheckUrl() {
    return '$baseUrl/health';
  }
}
