# Flutter App Production Configuration Guide

## 🚀 Overview

This guide covers the production configuration for the Travel Concierge Flutter app, including all service URLs, API endpoints, and testing procedures.

## 🌐 Production Service URLs

### Main Services
- **Django Server**: `https://django-server-277713629269.us-central1.run.app`
- **ADK Agent Server**: `https://adk-agent-server-277713629269.us-central1.run.app`
- **Voice Chat Server**: `https://voice-chat-server-277713629269.us-central1.run.app`

### API Base URLs
- **API Base**: `https://django-server-277713629269.us-central1.run.app/api`
- **Auth Base**: `https://django-server-277713629269.us-central1.run.app/api/auth`
- **User Manager**: `https://django-server-277713629269.us-central1.run.app/api/user_manager`
- **Agent Base**: `https://django-server-277713629269.us-central1.run.app/api/agent`
- **Travel Base**: `https://django-server-277713629269.us-central1.run.app/api/travel`

## 📱 Flutter App Configuration

### Environment Configuration
The app uses `environment_config.dart` to switch between local and production environments:

```dart
// lib/core/services/environment_config.dart
class EnvironmentConfig {
  // Set this to true for production, false for local development
  static const bool isProduction = true;

  // Base URLs for different environments
  static const Map<String, String> baseUrls = {
    local: 'http://localhost:8001/api',
    production: 'https://django-server-277713629269.us-central1.run.app/api',
  };

  // Chat/AI Agent Base URLs for different environments
  static const Map<String, String> chatBaseUrls = {
    local: 'http://localhost:8000', // ADK Agent server for local development
    production: 'https://adk-agent-server-277713629269.us-central1.run.app', // ADK Agent server for production
  };
}
```

### Production Configuration
All production URLs are centralized in `production_config.dart`:

```dart
// lib/core/services/production_config.dart
class ProductionConfig {
  // Main Django API Server
  static const String djangoServerUrl = 'https://django-server-277713629269.us-central1.run.app';

  // ADK Agent Server
  static const String adkAgentServerUrl = 'https://adk-agent-server-277713629269.us-central1.run.app';

  // Voice Chat Server
  static const String voiceChatServerUrl = 'https://voice-chat-server-277713629269.us-central1.run.app';

  // API Base URLs
  static const String apiBaseUrl = '$djangoServerUrl/api';
  static const String authBaseUrl = '$apiBaseUrl/auth';
  static const String userManagerBaseUrl = '$apiBaseUrl/user_manager';
  static const String agentBaseUrl = '$apiBaseUrl/agent';
  static const String travelBaseUrl = '$apiBaseUrl/travel';
}
```

### Connection Testing
A new connection test service has been added for debugging:

```dart
// lib/core/services/connection_test.dart
class ConnectionTestService {
  // Test all endpoints
  static Future<Map<String, dynamic>> testAllEndpoints() async;

  // Print all URLs for debugging
  static void printAllUrls();
}
```

## 🔧 API Endpoints

### Authentication Endpoints
- **Login**: `POST /api/auth/login/`
- **Verify Token**: `GET /api/auth/verify/`
- **Logout**: `POST /api/auth/logout/`

### User Management Endpoints
- **User Profiles**: `GET /api/user_manager/profiles`
- **User Profile Detail**: `GET /api/user_manager/profile/{uuid}`

### AI Agent Endpoints
- **Chat**: `POST /api/agent/chat/`
- **Status**: `GET /api/agent/status/`
- **Sub-Agents**: `GET /api/agent/sub-agents/`
- **Health**: `GET /api/agent/health/`

### Travel Service Endpoints
- **Recommendations**: `POST /api/travel/recommendations/`
- **Tools Status**: `GET /api/travel/tools/status/`

### Health Check Endpoints
- **Django Health**: `GET /health/`
- **ADK Agent Health**: `GET /health/`
- **Voice Chat Health**: `GET /health/`

## 🧪 Testing

### Quick Test Commands
```bash
# Test Django Server Health
curl -X GET https://django-server-277713629269.us-central1.run.app/health/

# Test Authentication
curl -X POST https://django-server-277713629269.us-central1.run.app/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"nero","password":"1234@pass"}'

# Test ADK Web UI
open https://adk-agent-server-277713629269.us-central1.run.app/dev-ui?app=travel_concierge
```

### Flutter App Testing
```bash
# Build app for production
cd App/travel_concierge_app
flutter build apk --release

# Install and test on device
flutter install
```

### Connection Test Results
- **Django Server**: ✅ Running (200 OK)
- **ADK Agent Server**: ✅ Running (200 OK)
- **Authentication**: ✅ Working (200 OK with valid credentials)
- **Voice Chat Server**: ✅ Running (200 OK)

## 🔄 Recent Updates

### Server Configuration Changes (July 24, 2025)
1. **Django Server**: Updated from `travel-server-staging` to `django-server`
2. **ADK Agent Server**: Confirmed working on `adk-agent-server`
3. **Voice Chat Server**: Confirmed working on `voice-chat-server`
4. **API Endpoints**: All endpoints updated with correct base URLs
5. **Health Checks**: Added proper health check endpoints

### Flutter App Updates
1. **Environment Config**: Updated production URLs
2. **Production Config**: Centralized all production endpoints
3. **Connection Test**: Added comprehensive testing service
4. **Gitignore**: Added logs directory to ignore list

## 🐛 Troubleshooting

### Common Issues
1. **Connection Timeout**: Check internet connection and verify URLs
2. **Authentication Failed**: Verify username/password and check Django logs
3. **AI Chat Not Working**: Check ADK Agent server status and API keys

### Debug Commands
```bash
# Check service status
gcloud run services list --region=us-central1

# Check Django logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=django-server" --limit=10

# Check ADK logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=adk-agent-server" --limit=10
```

## 📊 Service Status

### Current Status (July 24, 2025)
- **Django Server**: ✅ Running - `https://django-server-277713629269.us-central1.run.app`
- **ADK Agent Server**: ✅ Running - `https://adk-agent-server-277713629269.us-central1.run.app`
- **Voice Chat Server**: ✅ Running - `https://voice-chat-server-277713629269.us-central1.run.app`

### Health Check URLs
- Django: `https://django-server-277713629269.us-central1.run.app/health/`
- ADK Agent: `https://adk-agent-server-277713629269.us-central1.run.app/health/`
- Voice Chat: `https://voice-chat-server-277713629269.us-central1.run.app/health/`

## 🎯 Success Criteria

App được coi là hoạt động tốt trên production khi:

1. ✅ Có thể login thành công
2. ✅ Có thể chat với AI agent
3. ✅ Có thể get travel recommendations
4. ✅ Tất cả API endpoints trả về 200 OK
5. ✅ Không có lỗi connection timeout
6. ✅ UI responsive và smooth

---

**Last Updated**: July 24, 2025
**Version**: 2.0
**Environment**: Production
**Status**: All Services Running ✅