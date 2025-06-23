# Google Maps Integration Setup Guide

## 🗺️ **Overview**

This guide helps you set up Google Maps integration for the Travel Concierge app with real interactive maps, location search, and place discovery features.

## 🔑 **Required Google APIs**

### **1. Google Maps SDK for Flutter**
- **Purpose:** Display interactive maps with markers
- **Features:** Zoom, pan, marker placement, camera control

### **2. Google Places API**
- **Purpose:** Search places and get location suggestions
- **Features:** Text search, autocomplete, place details

### **3. Google Geocoding API**
- **Purpose:** Convert addresses to coordinates and vice versa
- **Features:** Address validation, location lookup

## 📋 **Setup Steps**

### **Step 1: Get Google Cloud Project**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable billing for the project

### **Step 2: Enable Required APIs**
Enable these APIs in Google Cloud Console:
```
- Maps SDK for Android
- Maps SDK for iOS
- Places API
- Geocoding API
- Geolocation API
```

### **Step 3: Create API Key**
1. Go to **Credentials** → **Create Credentials** → **API Key**
2. Copy the generated API key
3. **Restrict the API key** for security:
   - Add Android app restriction
   - Add iOS app restriction
   - Limit to required APIs only

### **Step 4: Configure Android**
1. Open `android/app/src/main/AndroidManifest.xml`
2. Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key:
```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="AIzaSyBvOkBmK1234567890abcdefghijklmnop"/>
```

### **Step 5: Configure Service**
1. Open `lib/core/services/google_maps_service.dart`
2. Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key:
```dart
static const String _apiKey = 'AIzaSyBvOkBmK1234567890abcdefghijklmnop';
```

### **Step 6: Install Dependencies**
Run the following command:
```bash
flutter pub get
```

## 🧪 **Testing**

### **Test Basic Map Display**
1. Run the app: `flutter run`
2. Navigate to Travel Exploration Screen
3. Tap the **Map button** (FloatingActionButton)
4. Verify Google Maps loads correctly

### **Test Search Functionality**
1. Open Location Targeting Screen
2. Type in search bar (e.g., "restaurants near me")
3. Verify autocomplete suggestions appear
4. Tap a suggestion and verify markers appear on map

### **Test Location Permissions**
1. Grant location permissions when prompted
2. Tap "My Location" button
3. Verify map centers on your current location

## 🚀 **Features Implemented**

### **Interactive Map**
- ✅ Real Google Maps instead of static image
- ✅ Pan, zoom, and camera controls
- ✅ Custom markers for locations
- ✅ Current location detection

### **Search & Discovery**
- ✅ Real-time place search
- ✅ Autocomplete suggestions
- ✅ Place details integration
- ✅ Search result markers

### **User Experience**
- ✅ Smooth animations
- ✅ Loading indicators
- ✅ Error handling
- ✅ Permission management

## 💰 **API Pricing (Google Cloud)**

### **Free Tier Limits**
- **Maps:** 28,000 map loads per month
- **Places:** 17,000 requests per month
- **Geocoding:** 40,000 requests per month

### **Cost After Free Tier**
- **Maps:** $7 per 1,000 loads
- **Places:** $32 per 1,000 requests
- **Geocoding:** $5 per 1,000 requests

## 🔐 **Security Best Practices**

### **API Key Restrictions**
1. **Application restrictions:** Limit to your app package
2. **API restrictions:** Enable only required APIs
3. **Usage monitoring:** Set up alerts for unusual usage

### **Environment Variables**
Consider using environment variables for API keys:
```dart
static const String _apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
```

## 🐛 **Troubleshooting**

### **Common Issues**

**Maps not loading:**
- Check API key is correct
- Verify Maps SDK for Android is enabled
- Check internet connection

**Search not working:**
- Verify Places API is enabled
- Check API key has Places API access
- Monitor API quotas

**Location not detected:**
- Grant location permissions
- Check device GPS is enabled
- Verify in actual device (not simulator)

## 📚 **Additional Resources**

- [Google Maps Flutter Documentation](https://pub.dev/packages/google_maps_flutter)
- [Google Places API Documentation](https://developers.google.com/maps/documentation/places/web-service)
- [Google Cloud Console](https://console.cloud.google.com/)

---

**🎯 Once setup is complete, the app will have a fully functional Google Maps integration with real-time location search and interactive map features!**