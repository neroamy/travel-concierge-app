# AI Agent Configuration Guide

## 🤖 Overview

This guide covers the AI Agent configuration for the Travel Concierge app, including ADK Agent server setup, chat integration, and testing procedures.

## 🌐 AI Agent Server Configuration

### ADK Agent Server
- **Production URL**: `https://adk-agent-server-277713629269.us-central1.run.app`
- **Web UI**: `https://adk-agent-server-277713629269.us-central1.run.app/dev-ui?app=travel_concierge`
- **Health Check**: `https://adk-agent-server-277713629269.us-central1.run.app/health/`

### Local Development
- **Local URL**: `http://localhost:8000`
- **Web UI**: `http://localhost:8000/dev-ui?app=travel_concierge`

## 🔧 Flutter App Integration

### Environment Configuration
File: `lib/core/services/environment_config.dart`
```dart
// Chat/AI Agent Base URLs for different environments
static const Map<String, String> chatBaseUrls = {
  local: 'http://localhost:8000', // ADK Agent server for local development
  production: 'https://adk-agent-server-277713629269.us-central1.run.app', // ADK Agent server for production
};
```

### Production Configuration
File: `lib/core/services/production_config.dart`
```dart
// ADK Agent Server
static const String adkAgentServerUrl = 'https://adk-agent-server-277713629269.us-central1.run.app';

// AI Agent Endpoints
static const String agentChatEndpoint = '$agentBaseUrl/chat/';
static const String agentStatusEndpoint = '$agentBaseUrl/status/';
static const String agentSubAgentsEndpoint = '$agentBaseUrl/sub-agents/';
static const String agentHealthEndpoint = '$agentBaseUrl/health/';
```

### API Configuration
File: `lib/core/services/api_config.dart`
```dart
// Chat/AI Agent Endpoints Configuration
static String get chatBaseUrl => EnvironmentConfig.currentChatBaseUrl;

// Build full session URL (for chat service)
static String getSessionUrl(String userId, String sessionId) {
  if (isProduction) {
    // Production: Use Django API endpoint
    return '$baseUrl/agent/chat/';
  } else {
    // Local: Use ADK Agent server endpoint
    return '$chatBaseUrl$sessionEndpoint/$userId/sessions/$sessionId';
  }
}
```

## 🧪 Testing AI Agent

### 1. Test ADK Agent Server Health
```bash
curl -X GET https://adk-agent-server-277713629269.us-central1.run.app/health/
```

### 2. Test ADK Web UI
Mở trình duyệt và truy cập:
```
https://adk-agent-server-277713629269.us-central1.run.app/dev-ui?app=travel_concierge
```

### 3. Test Chat via Django API
```bash
curl -X POST https://django-server-277713629269.us-central1.run.app/api/agent/chat/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"message": "Hello, can you help me plan a trip?", "user_id": "test_user"}'
```

### 4. Test Agent Status
```bash
curl -X GET https://django-server-277713629269.us-central1.run.app/api/agent/status/
```

### 5. Test Sub-Agents
```bash
curl -X GET https://django-server-277713629269.us-central1.run.app/api/agent/sub-agents/
```

## 🔄 Recent Updates (July 24, 2025)

### ✅ Server Configuration Updates
1. **ADK Agent Server**: Confirmed working on `adk-agent-server`
2. **Django Integration**: AI Agent endpoints integrated with Django API
3. **Health Checks**: Added proper health check endpoints
4. **Web UI**: ADK Web UI accessible and functional

### ✅ Confirmed Working Features
- ADK Agent Server: ✅ Running and responding
- Web UI: ✅ Accessible and functional
- Chat Integration: ✅ Working via Django API
- Health Checks: ✅ Responding with 200 OK
- Sub-Agents: ✅ Available and listed

## 📱 Flutter App AI Features

### Chat Integration
The Flutter app integrates with the AI Agent through:

1. **Production Mode**: Uses Django API endpoints (`/api/agent/chat/`)
2. **Local Mode**: Uses direct ADK Agent server endpoints
3. **Session Management**: Handles chat sessions and user context
4. **Message Streaming**: Supports real-time chat responses

### AI Agent Capabilities
- **Travel Planning**: Destination recommendations and itinerary creation
- **Booking Assistance**: Flight and hotel booking support
- **Travel Information**: Real-time travel updates and information
- **Personalized Recommendations**: Based on user preferences and history

## 🐛 Troubleshooting

### Common AI Agent Issues

#### 1. ADK Agent Server Not Responding
- Check if ADK Agent server is running
- Verify URL: `https://adk-agent-server-277713629269.us-central1.run.app`
- Check Cloud Run logs for errors

#### 2. Chat Not Working in Flutter App
- Verify environment configuration (`isProduction = true`)
- Check API endpoints in `production_config.dart`
- Test with ADK Web UI first

#### 3. Authentication Issues
- Ensure valid JWT token for API calls
- Check token expiration
- Verify user permissions

### Debug Commands

#### Check ADK Agent Logs
```bash
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=adk-agent-server" --limit=10
```

#### Test ADK Agent Directly
```bash
# Test health
curl -X GET https://adk-agent-server-277713629269.us-central1.run.app/health/

# Test Web UI accessibility
curl -X GET https://adk-agent-server-277713629269.us-central1.run.app/dev-ui?app=travel_concierge
```

## 📊 Monitoring

### Health Check URLs
- ADK Agent: `https://adk-agent-server-277713629269.us-central1.run.app/health/`
- Django Agent API: `https://django-server-277713629269.us-central1.run.app/api/agent/status/`

### Service Status
- ADK Agent Server: ✅ Running
- Django Agent Integration: ✅ Working
- Web UI: ✅ Accessible

## 🎯 Success Criteria

AI Agent được coi là hoạt động tốt khi:

1. ✅ ADK Agent server responding to health checks
2. ✅ Web UI accessible and functional
3. ✅ Chat integration working via Django API
4. ✅ Sub-agents available and listed
5. ✅ Flutter app can send/receive chat messages
6. ✅ Travel recommendations working

## 🔧 Configuration Files

### Key Files to Update
- `lib/core/services/environment_config.dart` - Environment switching
- `lib/core/services/production_config.dart` - Production URLs
- `lib/core/services/api_config.dart` - API endpoint configuration
- `lib/core/services/connection_test.dart` - Testing utilities

### Environment Variables
- `GOOGLE_CLOUD_API_KEY` - Required for AI Agent functionality
- `GOOGLE_CLOUD_PROJECT` - Google Cloud project ID
- `GOOGLE_CLOUD_LOCATION` - Google Cloud region
- `GOOGLE_PLACES_API_KEY` - Google Places API for travel data

---

**Last Updated**: July 24, 2025
**Version**: 2.0
**Environment**: Production
**Status**: AI Agent Running ✅