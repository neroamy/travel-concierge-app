import 'package:flutter/material.dart';

import '../../core/app_export.dart';

/// Demo class showing how to navigate to the AttractionDetailsScreen
/// You can use this as a reference for navigation from other screens
class NavigationDemo {
  /// Navigate to attraction details screen from any context
  static void navigateToAttractionDetails(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.attractionDetailsScreen,
    );
  }

  /// Navigate with parameters (for future enhancement)
  static void navigateToAttractionDetailsWithData(
    BuildContext context, {
    String? attractionName,
    String? description,
    double? rating,
    int? reviews,
    String? imagePath,
  }) {
    Navigator.pushNamed(
      context,
      AppRoutes.attractionDetailsScreen,
      arguments: {
        'attractionName': attractionName ?? 'Nordic Cottage',
        'description': description ??
            'Blue Lagoon Drive from Reykjavík, the capital of Iceland, to the southeast for about an hour, you can reach Blue Lagoon, the famous',
        'rating': rating ?? 4.79,
        'reviews': reviews ?? 78,
        'imagePath': imagePath ?? ImageConstant.imgNordicCottage,
      },
    );
  }

  /// Example of how to add navigation from a card widget
  static Widget buildNavigationCard(BuildContext context) {
    return GestureDetector(
      onTap: () => navigateToAttractionDetails(context),
      child: Card(
        margin: EdgeInsets.all(16.h),
        child: Padding(
          padding: EdgeInsets.all(16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nordic Cottage',
                style: TextStyleHelper.instance.title18SemiBold,
              ),
              SizedBox(height: 8.h),
              Text(
                'Tap to view details →',
                style: TextStyleHelper.instance.body14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
