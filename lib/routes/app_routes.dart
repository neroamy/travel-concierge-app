import 'package:flutter/material.dart';
import '../presentation/travel_exploration_screen/travel_exploration_screen.dart';
import '../presentation/itinerary_screen/itinerary_screen.dart';
import '../presentation/attraction_details_screen/attraction_details_screen.dart';

class AppRoutes {
  static const String travelExplorationScreen = '/travel_exploration_screen';
  static const String itineraryScreen = '/itinerary_screen';
  static const String attractionDetailsScreen = '/attraction_details_screen';
  static const String initialRoute = '/initialRoute';

  static Map<String, WidgetBuilder> routes = {
    itineraryScreen: (context) => const ItineraryScreen(),
    travelExplorationScreen: (context) => const TravelExplorationScreen(),
    attractionDetailsScreen: (context) => const AttractionDetailsScreen(),
    initialRoute: (context) => const TravelExplorationScreen(),
  };
}
