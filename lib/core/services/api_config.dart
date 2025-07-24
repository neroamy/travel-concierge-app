import 'environment_config.dart';
import 'production_config.dart';

/// API Configuration for Travel Concierge Client
class ApiConfig {
  // Import environment configuration
  static bool get isProduction => EnvironmentConfig.isProduction;

  // Server Configuration
  // NOTE: Update this URL to match your server setup
  // For local development: http://localhost:8001/api
  // For testing with real device: http://[PC_IP]:8001/api
  // Production: Google Cloud Run service
  static String get baseUrl => EnvironmentConfig.currentBaseUrl;

  static const String appName = 'travel_concierge';

  // Chat/AI Agent Endpoints Configuration
  // For local development: Separate ADK Agent server on port 8000
  // For production: Integrated with Django API
  static String get chatBaseUrl => EnvironmentConfig.currentChatBaseUrl;

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
  // Local: Uses ADK Agent server endpoints
  // Production: Uses Django API endpoints
  static String getSessionUrl(String userId, String sessionId) {
    if (isProduction) {
      // Production: Use Django API endpoint
      return '$baseUrl/agent/chat/';
    } else {
      // Local: Use ADK Agent server endpoint
      return '$chatBaseUrl$sessionEndpoint/$userId/sessions/$sessionId';
    }
  }

  // Build message URL (for chat service)
  // Local: Uses ADK Agent server SSE endpoint
  // Production: Uses Django API endpoint
  static String getMessageUrl() {
    if (isProduction) {
      // Production: Use Django API endpoint
      return '$baseUrl/agent/chat/';
    } else {
      // Local: Use ADK Agent server SSE endpoint
      return '$chatBaseUrl$messageEndpoint';
    }
  }

  // Build API docs URL (for chat service)
  static String getDocsUrl() {
    return '$chatBaseUrl$docsEndpoint';
  }

  // Authentication Endpoints
  static String getLoginUrl() {
    return isProduction
        ? ProductionConfig.loginEndpoint
        : '$baseUrl/auth/login';
  }

  static String getVerifyTokenUrl() {
    return isProduction
        ? ProductionConfig.verifyTokenEndpoint
        : '$baseUrl/auth/verify';
  }

  static String getLogoutUrl() {
    return isProduction
        ? ProductionConfig.logoutEndpoint
        : '$baseUrl/auth/logout';
  }

  // User Management Endpoints
  static String getUserProfileUrl() {
    return isProduction
        ? ProductionConfig.userProfileEndpoint
        : '$baseUrl/user_manager/profiles';
  }

  // AI Agent Endpoints
  static String getAgentChatUrl() {
    return isProduction
        ? ProductionConfig.agentChatEndpoint
        : '$baseUrl/agent/chat';
  }

  static String getAgentStatusUrl() {
    return isProduction
        ? ProductionConfig.agentStatusEndpoint
        : '$baseUrl/agent/status';
  }

  static String getAgentSubAgentsUrl() {
    return isProduction
        ? ProductionConfig.agentSubAgentsEndpoint
        : '$baseUrl/agent/sub-agents';
  }

  // Travel Service Endpoints
  static String getTravelRecommendationsUrl() {
    return isProduction ? ProductionConfig.travelRecommendationsEndpoint : '$baseUrl/travel/recommendations';
  }

  static String getTravelToolsStatusUrl() {
    return isProduction ? ProductionConfig.travelToolsStatusEndpoint : '$baseUrl/travel/tools/status';
  }

  // Helper method to test connection
  static String getHealthCheckUrl() {
    return isProduction ? ProductionConfig.djangoHealthEndpoint : '$baseUrl/health';
  }

  static String getExtractorUrl() {
    // Cập nhật endpoint này cho đúng server extractor thực tế
    return '$baseUrl/travel/extract_itinerary';
  }
}
