import 'package:flutter/material.dart';
import '../presentation/travel_exploration_screen/travel_exploration_screen.dart';
import '../presentation/itinerary_screen/itinerary_screen.dart';
import '../presentation/attraction_details_screen/attraction_details_screen.dart';
import '../presentation/location_targeting_screen/location_targeting_screen.dart';
import '../presentation/location_targeting_screen/location_targeting_screen_with_maps.dart';
import '../presentation/plan_view_screen/plan_view_screen.dart';
import '../presentation/ai_chat_screen/ai_chat_screen.dart';
import '../presentation/profile_settings_screen/profile_settings_screen.dart';
import '../presentation/sign_in_screen/sign_in_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/test_mockup_screen/test_mockup_screen.dart';
import '../presentation/voice_chat_screen/voice_chat_screen.dart';

class AppRoutes {
  static const String splashScreen = '/splash_screen';
  static const String signInScreen = '/sign_in_screen';
  static const String travelExplorationScreen = '/travel_exploration_screen';
  static const String itineraryScreen = '/itinerary_screen';
  static const String attractionDetailsScreen = '/attraction_details_screen';
  static const String locationTargetingScreen = '/location_targeting_screen';
  static const String locationTargetingScreenWithMaps =
      '/location_targeting_screen_with_maps';
  static const String planViewScreen = '/plan_view_screen';
  static const String aiChatScreen = '/ai_chat_screen';
  static const String profileSettingsScreen = '/profile_settings_screen';
  static const String testMockupScreen = '/test_mockup_screen';
  static const String voiceChatScreen = '/voice_chat_screen';
  static const String initialRoute = '/initialRoute';

  static Map<String, WidgetBuilder> routes = {
    splashScreen: (context) => const SplashScreen(),
    signInScreen: (context) => const SignInScreen(),
    itineraryScreen: (context) => const ItineraryScreen(),
    travelExplorationScreen: (context) => const TravelExplorationScreen(),
    attractionDetailsScreen: (context) => const AttractionDetailsScreen(),
    locationTargetingScreen: (context) => const LocationTargetingScreen(),
    locationTargetingScreenWithMaps: (context) =>
        const LocationTargetingScreenWithMaps(),
    planViewScreen: (context) => const PlanViewScreen(),
    aiChatScreen: (context) => const AIChatScreen(),
    profileSettingsScreen: (context) => const ProfileSettingsScreen(),
    testMockupScreen: (context) => const TestMockupScreen(),
    voiceChatScreen: (context) => const VoiceChatScreen(),
    initialRoute: (context) => const SplashScreen(),
  };
}
