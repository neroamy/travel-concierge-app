/// Production Configuration for Travel Concierge App
/// This file contains all the URLs for deployed services on Google Cloud Platform
class ProductionConfig {
  // Main Django API Server
  static const String djangoServerUrl =
      'https://django-server-277713629269.us-central1.run.app';

  // ADK Agent Server
  static const String adkAgentServerUrl =
      'https://adk-agent-server-277713629269.us-central1.run.app';

  // Voice Chat Server
  static const String voiceChatServerUrl =
      'https://voice-chat-server-277713629269.us-central1.run.app';

  // API Base URLs
  static const String apiBaseUrl = '$djangoServerUrl/api';
  static const String authBaseUrl = '$apiBaseUrl/auth';
  static const String userManagerBaseUrl = '$apiBaseUrl/user_manager';
  static const String agentBaseUrl = '$apiBaseUrl/agent';
  static const String travelBaseUrl = '$apiBaseUrl/travel';

  // Authentication Endpoints
  static const String loginEndpoint = '$authBaseUrl/login/';
  static const String verifyTokenEndpoint = '$authBaseUrl/verify/';
  static const String logoutEndpoint = '$authBaseUrl/logout/';

  // User Management Endpoints
  static const String userProfileEndpoint = '$userManagerBaseUrl/profiles';
  static const String userProfileDetailEndpoint = '$userManagerBaseUrl/profile';

  // AI Agent Endpoints
  static const String agentChatEndpoint = '$agentBaseUrl/chat/';
  static const String agentStatusEndpoint = '$agentBaseUrl/status/';
  static const String agentSubAgentsEndpoint = '$agentBaseUrl/sub-agents/';
  static const String agentHealthEndpoint = '$agentBaseUrl/health/';

  // Travel Service Endpoints
  static const String travelRecommendationsEndpoint =
      '$travelBaseUrl/recommendations/';
  static const String travelToolsStatusEndpoint =
      '$travelBaseUrl/tools/status/';

  // Health Check Endpoints
  static const String djangoHealthEndpoint = '$djangoServerUrl/health/';
  static const String adkAgentHealthEndpoint = '$adkAgentServerUrl/health/';
  static const String voiceChatHealthEndpoint = '$voiceChatServerUrl/health/';

  // WebSocket Endpoints
  static const String voiceChatWebSocketUrl =
      'wss://voice-chat-server-277713629269.us-central1.run.app';

  // Service Status URLs
  static const Map<String, String> serviceUrls = {
    'django': djangoServerUrl,
    'adk_agent': adkAgentServerUrl,
    'voice_chat': voiceChatServerUrl,
  };

  // Service Health Check URLs
  static const Map<String, String> healthCheckUrls = {
    'django': djangoHealthEndpoint,
    'adk_agent': adkAgentHealthEndpoint,
    'voice_chat': voiceChatHealthEndpoint,
  };

  /// Get service URL by name
  static String getServiceUrl(String serviceName) {
    return serviceUrls[serviceName] ?? '';
  }

  /// Get health check URL by service name
  static String getHealthCheckUrl(String serviceName) {
    return healthCheckUrls[serviceName] ?? '';
  }

  /// Check if all services are available
  static List<String> getAllServiceUrls() {
    return serviceUrls.values.toList();
  }

  /// Get all health check URLs
  static List<String> getAllHealthCheckUrls() {
    return healthCheckUrls.values.toList();
  }
}
