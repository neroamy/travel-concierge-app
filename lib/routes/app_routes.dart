import 'package:flutter/material.dart';
import '../presentation/travel_exploration_screen/travel_exploration_screen.dart';
import '../presentation/itinerary_screen/itinerary_screen.dart';

class AppRoutes {
  static const String travelExplorationScreen = '/travel_exploration_screen';
  static const String itineraryScreen = '/itinerary_screen';
  static const String initialRoute = '/initialRoute';

  static Map<String, WidgetBuilder> routes = {
    itineraryScreen: (context) => const ItineraryScreen(),
    travelExplorationScreen: (context) => const TravelExplorationScreen(),
    initialRoute: (context) => const TravelExplorationScreen(),
  };
}
