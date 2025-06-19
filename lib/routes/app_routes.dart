import 'package:flutter/material.dart';
import '../presentation/travel_exploration_screen/travel_exploration_screen.dart';

import '../presentation/app_navigation_screen/app_navigation_screen.dart';

class AppRoutes {
  static const String travelExplorationScreen = '/travel_exploration_screen';

  static const String appNavigationScreen = '/app_navigation_screen';
  static const String initialRoute = '/initialRoute';

  static Map<String, WidgetBuilder> get routes => {
        travelExplorationScreen: (context) => TravelExplorationScreen(),
        appNavigationScreen: (context) => AppNavigationScreen(),
        initialRoute: (context) => TravelExplorationScreen(),
      };
}
