# Authentication API Guide

## 🔐 Overview

This guide covers the authentication system for the Travel Concierge app, including login, token verification, and user management endpoints.

## 🌐 Production URLs

### Django Server (Authentication)
- **Base URL**: `https://django-server-277713629269.us-central1.run.app`
- **API Base**: `https://django-server-277713629269.us-central1.run.app/api`
- **Auth Base**: `https://django-server-277713629269.us-central1.run.app/api/auth`

### Local Development
- **Base URL**: `http://localhost:8001`
- **API Base**: `http://localhost:8001/api`
- **Auth Base**: `http://localhost:8001/api/auth`

## 🔧 API Endpoints

### Authentication Endpoints

#### 1. Login
- **URL**: `POST /api/auth/login/`
- **Description**: Authenticate user with username and password
- **Request Body**:
```json
{
  "username": "nero",
  "password": "1234@pass"
}
```
- **Response**:
```json
{
  "status": 200,
  "msg": "Login successful",
  "data": {
    "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "user": {
      "id": 1,
      "username": "nero",
      "email": "nero@example.com",
      "first_name": "Nero",
      "last_name": "User"
    }
  },
  "format_version": 1000
}
```

#### 2. Verify Token
- **URL**: `GET /api/auth/verify/`
- **Description**: Verify JWT token validity
- **Headers**: `Authorization: Bearer <token>`
- **Response**:
```json
{
  "status": 200,
  "msg": "Token is valid",
  "data": {
    "user": {
      "id": 1,
      "username": "nero",
      "email": "nero@example.com"
    }
  },
  "format_version": 1000
}
```

#### 3. Logout
- **URL**: `POST /api/auth/logout/`
- **Description**: Logout user and invalidate token
- **Headers**: `Authorization: Bearer <token>`
- **Response**:
```json
{
  "status": 200,
  "msg": "Logout successful",
  "data": {},
  "format_version": 1000
}
```

## 🧪 Testing Authentication

### 1. Test Login
```bash
curl -X POST https://django-server-277713629269.us-central1.run.app/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"nero","password":"1234@pass"}'
```

### 2. Test Token Verification
```bash
# First get token from login
TOKEN="eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."

# Then verify token
curl -X GET https://django-server-277713629269.us-central1.run.app/api/auth/verify/ \
  -H "Authorization: Bearer $TOKEN"
```

### 3. Test Logout
```bash
curl -X POST https://django-server-277713629269.us-central1.run.app/api/auth/logout/ \
  -H "Authorization: Bearer $TOKEN"
```

## 📱 Flutter App Integration

### Environment Configuration
File: `lib/core/services/environment_config.dart`
```dart
// Base URLs for different environments
static const Map<String, String> baseUrls = {
  local: 'http://localhost:8001/api',
  production: 'https://django-server-277713629269.us-central1.run.app/api',
};
```

### Production Configuration
File: `lib/core/services/production_config.dart`
```dart
// Authentication Endpoints
static const String loginEndpoint = '$authBaseUrl/login/';
static const String verifyTokenEndpoint = '$authBaseUrl/verify/';
static const String logoutEndpoint = '$authBaseUrl/logout/';
```

### API Configuration
File: `lib/core/services/api_config.dart`
```dart
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
```

## 🔄 Recent Updates (July 24, 2025)

### ✅ Server Configuration Updates
1. **Django Server URL**: Updated from `travel-server-staging` to `django-server`
2. **Database Connection**: Fixed Cloud SQL Proxy configuration
3. **Authentication**: Confirmed working with test credentials
4. **Health Checks**: Added proper health check endpoints

### ✅ Confirmed Working
- Django Server: `https://django-server-277713629269.us-central1.run.app` ✅
- Authentication: Login endpoint working with test credentials ✅
- Token Verification: Working with valid JWT tokens ✅
- Logout: Properly invalidates tokens ✅

### ✅ Test Credentials
- **Username**: `nero`
- **Password**: `1234@pass`
- **Status**: Working in production environment

## 🐛 Troubleshooting

### Common Authentication Issues

#### 1. Login Failed (400 Bad Request)
- Verify username and password are correct
- Check request format (JSON with username/password)
- Ensure Content-Type header is set to application/json

#### 2. Token Verification Failed (401 Unauthorized)
- Check if token is valid and not expired
- Verify Authorization header format: `Bearer <token>`
- Ensure token was obtained from successful login

#### 3. Server Not Responding
- Check if Django server is running
- Verify URL: `https://django-server-277713629269.us-central1.run.app`
- Check Cloud Run logs for errors

### Debug Commands

#### Check Django Server Health
```bash
curl -X GET https://django-server-277713629269.us-central1.run.app/health/
```

#### Check Django Logs
```bash
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=django-server" --limit=10
```

#### Test Authentication Flow
```bash
# 1. Login
LOGIN_RESPONSE=$(curl -s -X POST https://django-server-277713629269.us-central1.run.app/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"nero","password":"1234@pass"}')

# 2. Extract token
TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.data.token')

# 3. Verify token
curl -X GET https://django-server-277713629269.us-central1.run.app/api/auth/verify/ \
  -H "Authorization: Bearer $TOKEN"
```

## 📊 Monitoring

### Health Check URLs
- Django Server: `https://django-server-277713629269.us-central1.run.app/health/`
- Authentication API: `https://django-server-277713629269.us-central1.run.app/api/auth/`

### Service Status
- Django Server: ✅ Running
- Authentication API: ✅ Working
- Database Connection: ✅ Connected

## 🔐 Security Considerations

### JWT Token Security
- Tokens are signed with a secret key
- Tokens have expiration time
- Tokens are invalidated on logout
- HTTPS is enforced for all production endpoints

### Password Security
- Passwords are hashed using Django's password hashers
- Password validation is enforced
- Brute force protection is implemented

### Network Security
- HTTPS is enforced for all production endpoints
- CORS is properly configured
- Rate limiting is implemented

## 🎯 Success Criteria

Authentication system được coi là hoạt động tốt khi:

1. ✅ Login endpoint returns 200 OK with valid credentials
2. ✅ Token verification works with valid JWT tokens
3. ✅ Logout properly invalidates tokens
4. ✅ Invalid credentials return appropriate error codes
5. ✅ Expired tokens are properly rejected
6. ✅ HTTPS is enforced for all endpoints

## 🔧 Configuration Files

### Key Files to Update
- `lib/core/services/environment_config.dart` - Environment switching
- `lib/core/services/production_config.dart` - Production URLs
- `lib/core/services/api_config.dart` - API endpoint configuration
- `lib/core/services/connection_test.dart` - Testing utilities

### Environment Variables
- `SECRET_KEY` - Django secret key for JWT signing
- `DEBUG` - Django debug mode (False for production)
- `ALLOWED_HOSTS` - Allowed hostnames for Django

---

**Last Updated**: July 24, 2025
**Version**: 2.0
**Environment**: Production
**Status**: Authentication Working ✅