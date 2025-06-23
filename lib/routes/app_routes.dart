import 'package:flutter/material.dart';
import '../presentation/travel_exploration_screen/travel_exploration_screen.dart';
import '../presentation/itinerary_screen/itinerary_screen.dart';
import '../presentation/attraction_details_screen/attraction_details_screen.dart';
import '../presentation/location_targeting_screen/location_targeting_screen.dart';
import '../presentation/location_targeting_screen/location_targeting_screen_with_maps.dart';

class AppRoutes {
  static const String travelExplorationScreen = '/travel_exploration_screen';
  static const String itineraryScreen = '/itinerary_screen';
  static const String attractionDetailsScreen = '/attraction_details_screen';
  static const String locationTargetingScreen = '/location_targeting_screen';
  static const String locationTargetingScreenWithMaps =
      '/location_targeting_screen_with_maps';
  static const String initialRoute = '/initialRoute';

  static Map<String, WidgetBuilder> routes = {
    itineraryScreen: (context) => const ItineraryScreen(),
    travelExplorationScreen: (context) => const TravelExplorationScreen(),
    attractionDetailsScreen: (context) => const AttractionDetailsScreen(),
    locationTargetingScreen: (context) => const LocationTargetingScreen(),
    locationTargetingScreenWithMaps: (context) =>
        const LocationTargetingScreenWithMaps(),
    initialRoute: (context) => const TravelExplorationScreen(),
  };
}
