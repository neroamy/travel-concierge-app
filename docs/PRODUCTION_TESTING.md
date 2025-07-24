# 🧪 Production Testing Guide

## 📋 Tổng quan

Hướng dẫn test Travel Concierge app trên môi trường production với các URL endpoint đã được cập nhật.

## 🌐 Production URLs

### Django Server (Main API)
- **URL**: `https://django-server-277713629269.us-central1.run.app`
- **API Base**: `https://django-server-277713629269.us-central1.run.app/api`

### ADK Agent Server (AI Chat)
- **URL**: `https://adk-agent-server-277713629269.us-central1.run.app`
- **Web UI**: `https://adk-agent-server-277713629269.us-central1.run.app/dev-ui?app=travel_concierge`

### Voice Chat Server
- **URL**: `https://voice-chat-server-277713629269.us-central1.run.app`

## 🔗 API Endpoints

### Authentication
- `POST /api/auth/login/` - User login
- `GET /api/auth/verify/` - Token verification
- `POST /api/auth/logout/` - User logout

### User Management
- `GET /api/user_manager/profile/` - Get user profile
- `PUT /api/user_manager/profile/` - Update user profile

### AI Agent
- `POST /api/agent/chat/` - Chat with AI agent
- `GET /api/agent/status/` - Check agent status
- `GET /api/agent/sub-agents/` - List sub-agents

### Travel Services
- `POST /api/travel/recommendations/` - Get travel recommendations
- `GET /api/travel/tools/status/` - Check tools status

### Health Checks
- `GET /health/` - Django server health
- `GET /api/health/` - API health check

## 🧪 Testing Steps

### 1. Test Django Server Health
```bash
curl -X GET https://django-server-277713629269.us-central1.run.app/health/
```

### 2. Test Authentication
```bash
curl -X POST https://django-server-277713629269.us-central1.run.app/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"nero","password":"1234@pass"}'
```

### 3. Test ADK Web UI
Mở trình duyệt và truy cập:
```
https://adk-agent-server-277713629269.us-central1.run.app/dev-ui?app=travel_concierge
```

### 4. Test Flutter App
1. Build app với production config:
```bash
cd App/travel_concierge_app
flutter build apk --release
```

2. Install và test trên device:
```bash
flutter install
```

## 🔧 Flutter App Configuration

### Environment Settings
File: `lib/core/services/environment_config.dart`
```dart
static const bool isProduction = true; // Set to true for production
```

### Production URLs
File: `lib/core/services/production_config.dart`
- Django Server: `https://django-server-277713629269.us-central1.run.app`
- ADK Agent: `https://adk-agent-server-277713629269.us-central1.run.app`
- Voice Chat: `https://voice-chat-server-277713629269.us-central1.run.app`

### Connection Testing
File: `lib/core/services/connection_test.dart`
```dart
// Test all endpoints
final results = await ConnectionTestService.testAllEndpoints();

// Print all URLs
ConnectionTestService.printAllUrls();
```

## 📱 App Features to Test

### ✅ Authentication
- [ ] Login với username/password
- [ ] Token verification
- [ ] Logout

### ✅ User Profile
- [ ] Get user profile
- [ ] Update user profile

### ✅ AI Chat
- [ ] Chat với AI agent
- [ ] Travel recommendations
- [ ] Tools status

### ✅ Travel Services
- [ ] Get travel recommendations
- [ ] Check tools status

## 🔄 Recent Server Updates (July 24, 2025)

### ✅ Fixed Issues
1. **Django Server URL**: Updated from `travel-server-staging` to `django-server`
2. **Database Connection**: Fixed Cloud SQL Proxy configuration
3. **Authentication**: Confirmed working with test credentials
4. **Health Checks**: Added proper health check endpoints

### ✅ Confirmed Working
- Django Server: `https://django-server-277713629269.us-central1.run.app` ✅
- ADK Agent Server: `https://adk-agent-server-277713629269.us-central1.run.app` ✅
- Voice Chat Server: `https://voice-chat-server-277713629269.us-central1.run.app` ✅
- Authentication: Login endpoint working with test credentials ✅
- Health Checks: All services responding with 200 OK ✅

## 🐛 Troubleshooting

### Common Issues

#### 1. Connection Timeout
- Kiểm tra internet connection
- Verify URL endpoints
- Check Cloud Run service status

#### 2. Authentication Failed
- Verify username/password: `nero` / `1234@pass`
- Check Django server logs
- Test endpoint với curl

#### 3. AI Chat Not Working
- Check ADK Agent server status
- Verify API keys
- Test ADK Web UI

### Debug Commands

#### Check Service Status
```bash
gcloud run services list --region=us-central1
```

#### Check Django Logs
```bash
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=django-server" --limit=10
```

#### Check ADK Logs
```bash
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=adk-agent-server" --limit=10
```

## 📊 Monitoring

### Health Check URLs
- Django: `https://django-server-277713629269.us-central1.run.app/health/`
- ADK Agent: `https://adk-agent-server-277713629269.us-central1.run.app/health/`
- Voice Chat: `https://voice-chat-server-277713629269.us-central1.run.app/health/`

### Service Status
- Django Server: ✅ Running
- ADK Agent Server: ✅ Running
- Voice Chat Server: ✅ Running

## 🎯 Success Criteria

App được coi là hoạt động tốt trên production khi:

1. ✅ Có thể login thành công với credentials: `nero` / `1234@pass`
2. ✅ Có thể chat với AI agent qua ADK Web UI
3. ✅ Có thể get travel recommendations
4. ✅ Tất cả API endpoints trả về 200 OK
5. ✅ Không có lỗi connection timeout
6. ✅ UI responsive và smooth

## 🔧 Quick Test Script

Tạo file `test_production.sh` để test nhanh:

```bash
#!/bin/bash
echo "🧪 Testing Travel Concierge Production Environment..."

echo "1. Testing Django Server Health..."
curl -s -o /dev/null -w "%{http_code}" https://django-server-277713629269.us-central1.run.app/health/

echo "2. Testing Authentication..."
curl -s -X POST https://django-server-277713629269.us-central1.run.app/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"nero","password":"1234@pass"}' | jq '.status'

echo "3. Testing ADK Agent Server..."
curl -s -o /dev/null -w "%{http_code}" https://adk-agent-server-277713629269.us-central1.run.app/health/

echo "✅ Production testing completed!"
```

---

**Last Updated**: July 24, 2025
**Version**: 2.0
**Environment**: Production
**Status**: All Services Running ✅