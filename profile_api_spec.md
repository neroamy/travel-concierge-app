# Profile Settings API Specification

## 📋 Overview

This document outlines the API requirements for the Profile Settings functionality in the Travel Concierge App. These APIs enable user profile management, password changes, and integration with the AI chat system.

## 🔧 Base Configuration

```yaml
Base URL: http://localhost:3000/api
Content-Type: application/json
Accept: application/json
```

## 🚀 API Endpoints

### 1. Get User Profile

**Endpoint**: `GET /profile`
**Purpose**: Retrieve current user profile information
**Authentication**: Required (future implementation)

#### Request
```http
GET /api/profile
Content-Type: application/json
```

#### Response - Success (200)
```json
{
  "success": true,
  "message": "Profile retrieved successfully",
  "data": {
    "id": "user_1751435225000",
    "username": "Alan love",
    "email": "alanlovelq@gmail.com",
    "address": "Ha Noi, Viet Nam",
    "interests": "Travel, Photography, Food",
    "avatar_url": null,
    "created_at": "2024-01-01T00:00:00.000Z",
    "updated_at": "2024-01-01T00:00:00.000Z"
  }
}
```

#### Response - Error (404)
```json
{
  "success": false,
  "message": "Profile not found",
  "data": null
}
```

#### Response - Error (500)
```json
{
  "success": false,
  "message": "Internal server error",
  "data": null
}
```

---

### 2. Update User Profile

**Endpoint**: `PUT /profile/update`
**Purpose**: Update user profile information
**Authentication**: Required (future implementation)

#### Request
```http
PUT /api/profile/update
Content-Type: application/json
```

```json
{
  "username": "Alan Smith",
  "email": "alansmith@gmail.com",
  "address": "Ho Chi Minh City, Viet Nam",
  "interests": "Travel, Photography, Food, Adventure",
  "avatar_url": "https://example.com/avatar.jpg"
}
```

#### Request Validation Rules
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `username` | string | ✅ | Min 1 character, Max 100 characters |
| `email` | string | ✅ | Valid email format, Unique |
| `address` | string | ✅ | Min 1 character, Max 500 characters |
| `interests` | string | ✅ | Min 1 character, Max 1000 characters |
| `avatar_url` | string | ❌ | Valid URL format if provided |

#### Response - Success (200)
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": "user_1751435225000",
    "username": "Alan Smith",
    "email": "alansmith@gmail.com",
    "address": "Ho Chi Minh City, Viet Nam",
    "interests": "Travel, Photography, Food, Adventure",
    "avatar_url": "https://example.com/avatar.jpg",
    "created_at": "2024-01-01T00:00:00.000Z",
    "updated_at": "2024-01-15T10:30:00.000Z"
  }
}
```

#### Response - Error (400)
```json
{
  "success": false,
  "message": "Validation failed",
  "data": {
    "errors": {
      "email": "Invalid email format",
      "username": "Username is required"
    }
  }
}
```

#### Response - Error (409)
```json
{
  "success": false,
  "message": "Email already exists",
  "data": null
}
```

---

### 3. Change Password

**Endpoint**: `PUT /profile/change-password`
**Purpose**: Change user password with current password verification
**Authentication**: Required (future implementation)

#### Request
```http
PUT /api/profile/change-password
Content-Type: application/json
```

```json
{
  "current_password": "oldpassword123",
  "new_password": "newpassword456",
  "confirm_password": "newpassword456"
}
```

#### Request Validation Rules
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `current_password` | string | ✅ | Must match current password |
| `new_password` | string | ✅ | Min 8 characters, Max 128 characters |
| `confirm_password` | string | ✅ | Must match new_password |

#### Response - Success (200)
```json
{
  "success": true,
  "message": "Password changed successfully",
  "data": null
}
```

#### Response - Error (400)
```json
{
  "success": false,
  "message": "Current password is incorrect",
  "data": null
}
```

#### Response - Error (400)
```json
{
  "success": false,
  "message": "New password must be at least 8 characters",
  "data": null
}
```

#### Response - Error (400)
```json
{
  "success": false,
  "message": "New password and confirm password do not match",
  "data": null
}
```

---

## 🔄 AI Chat Integration

### User Context Data

When profile is updated, the following data structure should be available for AI Agent context:

```json
{
  "user_scenario": {
    "user_name": "Alan Smith",
    "user_email": "alansmith@gmail.com",
    "user_location": "Ho Chi Minh City, Viet Nam",
    "user_interests": "Travel, Photography, Food, Adventure",
    "user_preferences": {
      "travel_style": "Explorer",
      "budget_range": "Mid-range",
      "accommodation": "Hotel & Resort"
    }
  }
}
```

This data can be used to:
- Personalize AI recommendations
- Provide location-specific suggestions
- Tailor responses based on user interests
- Enhance travel planning accuracy

---

## 🗄️ Database Schema

### Recommended Table Structure

```sql
CREATE TABLE user_profiles (
    id VARCHAR(50) PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    interests TEXT NOT NULL,
    avatar_url VARCHAR(500) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Indexes for performance
    INDEX idx_user_profiles_email (email),
    INDEX idx_user_profiles_username (username)
);
```

### Additional Considerations

1. **Password Storage**: Use bcrypt with salt rounds >= 12
2. **Email Verification**: Consider email verification flow
3. **Profile Pictures**: Implement file upload service for avatars
4. **Audit Trail**: Log profile changes for security

---

## 🔐 Security Requirements

### 1. Input Validation
- Sanitize all input data to prevent SQL injection
- Validate email format and uniqueness
- Enforce password complexity rules
- Limit input lengths to prevent buffer overflow

### 2. Password Security
- Hash passwords using bcrypt with appropriate salt rounds
- Never return password hashes in API responses
- Implement rate limiting for password change attempts
- Consider password history to prevent reuse

### 3. Data Protection
- Use HTTPS for all API communications
- Implement proper CORS configuration
- Validate content-type headers
- Add request size limits

### 4. Error Handling
- Don't expose sensitive information in error messages
- Use consistent error response format
- Log security events for monitoring
- Implement proper HTTP status codes

---

## 🚦 Rate Limiting

### Recommended Limits

| Endpoint | Rate Limit | Window |
|----------|------------|--------|
| `GET /profile` | 100 requests | 15 minutes |
| `PUT /profile/update` | 10 requests | 15 minutes |
| `PUT /profile/change-password` | 5 requests | 15 minutes |

### Implementation Notes
- Use user identification (IP or user ID) for rate limiting
- Return appropriate HTTP 429 status for rate limit exceeded
- Include rate limit headers in responses

---

## 📝 Testing Guidelines

### Unit Tests Required

1. **Profile Retrieval**
   - Valid profile exists
   - Profile not found
   - Database connection error

2. **Profile Update**
   - Valid data update
   - Invalid email format
   - Duplicate email
   - Missing required fields
   - Field length validation

3. **Password Change**
   - Successful password change
   - Incorrect current password
   - Weak new password
   - Password mismatch
   - Rate limiting

### Integration Tests

1. **End-to-End Profile Management**
   - Create → Read → Update → Change Password flow
   - Error scenarios and recovery
   - Data persistence verification

2. **Security Tests**
   - SQL injection attempts
   - XSS prevention
   - Rate limiting enforcement
   - Password security validation

---

## 🚀 Implementation Priority

### Phase 1 (High Priority)
1. `PUT /profile/update` - Core functionality
2. `GET /profile` - Data retrieval
3. Basic validation and error handling

### Phase 2 (Medium Priority)
1. `PUT /profile/change-password` - Security feature
2. Enhanced validation rules
3. Rate limiting implementation

### Phase 3 (Future Enhancements)
1. Avatar upload functionality
2. Email verification system
3. Advanced security features
4. Audit logging

---

## 📞 Support Information

### Development Team Contacts
- **Frontend**: Flutter Team
- **Backend**: Node.js/Express Team
- **Database**: Database Administration Team

### Documentation Updates
This document should be updated whenever:
- New endpoints are added
- Validation rules change
- Security requirements are modified
- Database schema is updated

---

**Last Updated**: January 2024
**Version**: 1.0
**Author**: Travel Concierge Development Team