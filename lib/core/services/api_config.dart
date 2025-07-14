/// API Configuration for Travel Concierge Client
class ApiConfig {
  // Server Configuration
  // NOTE: Update this URL to match your server setup
  // For local development: http://localhost:8001/api
  // For testing with real device: http://[PC_IP]:8001/api
  static const String baseUrl = 'http://192.168.1.7:8001/api';
  static const String appName = 'travel_concierge';

  // Chat/AI Agent Endpoints (different server)
  static const String chatBaseUrl = 'http://192.168.1.7:8002';
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

  // Google Maps API Key
  static const String googleMapsApiKey =
      'AIzaSyC6CKHUDCkbDcukn3-U8sG0xkoWGsKv9Xg';

  // Build full session URL (for chat service)
  static String getSessionUrl(String userId, String sessionId) {
    return '$chatBaseUrl$sessionEndpoint/$userId/sessions/$sessionId';
  }

  // Build message URL (for chat service)
  static String getMessageUrl() {
    return '$chatBaseUrl$messageEndpoint';
  }

  // Build API docs URL (for chat service)
  static String getDocsUrl() {
    return '$chatBaseUrl$docsEndpoint';
  }

  // Helper method to test connection
  static String getHealthCheckUrl() {
    return '$baseUrl/health';
  }

  static String getExtractorUrl() {
    // Cập nhật endpoint này cho đúng server extractor thực tế
    return '$chatBaseUrl/extract_itinerary';
  }
}
