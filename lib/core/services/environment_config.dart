/// Environment Configuration for Travel Concierge App
/// This file allows easy switching between local development and production
class EnvironmentConfig {
  // Set this to false for local development, true for production
  static const bool isProduction = false;

  // Environment names
  static const String local = 'local';
  static const String production = 'production';

  // Get current environment
  static String get currentEnvironment => isProduction ? production : local;

  // Base URLs for different environments
  static const Map<String, String> baseUrls = {
    local: 'http://192.168.1.8:8001/api',
    production: 'https://django-server-277713629269.us-central1.run.app/api',
  };

  // Chat/AI Agent Base URLs for different environments
  static const Map<String, String> chatBaseUrls = {
    local: 'http://192.168.1.8:8002', // ADK Agent server for local development
    production:
        'https://adk-agent-server-277713629269.us-central1.run.app', // ADK Agent server for production
  };

  // Get current base URL
  static String get currentBaseUrl => baseUrls[currentEnvironment]!;

  // Get current chat base URL
  static String get currentChatBaseUrl => chatBaseUrls[currentEnvironment]!;

  // Environment-specific settings
  static const Map<String, Map<String, dynamic>> settings = {
    local: {
      'useSSE': true,
      'createSession': true,
      'timeout': 30,
    },
    production: {
      'useSSE': true, // Enable SSE streaming for production
      'createSession': true, // Enable session creation for production
      'timeout': 60,
    },
  };

  // Get current settings
  static Map<String, dynamic> get currentSettings =>
      settings[currentEnvironment]!;

  // Helper methods
  static bool get useSSE => currentSettings['useSSE'] as bool;
  static bool get createSession => currentSettings['createSession'] as bool;
  static int get timeout => currentSettings['timeout'] as int;
}
