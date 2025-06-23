import 'package:flutter/material.dart';
import '../../core/app_export.dart';

/// Demo widget để test navigation đến attraction details screen
/// Bạn có thể thêm widget này vào bất kỳ screen nào để test
class TestNavigationWidget extends StatelessWidget {
  const TestNavigationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.h),
      child: Column(
        children: [
          Text(
            'Test Navigation to Attraction Details',
            style: TextStyleHelper.instance.title16Medium,
          ),
          SizedBox(height: 16.h),

          // Test với Western Strait
          ElevatedButton(
            onPressed: () => _testNavigation(context, 'Western Strait'),
            child: const Text('Test Western Strait'),
          ),
          SizedBox(height: 8.h),

          // Test với Beach House
          ElevatedButton(
            onPressed: () => _testNavigation(context, 'Beach House'),
            child: const Text('Test Beach House'),
          ),
          SizedBox(height: 8.h),

          // Test với Mountain range
          ElevatedButton(
            onPressed: () => _testNavigation(context, 'Mountain range'),
            child: const Text('Test Mountain range'),
          ),
        ],
      ),
    );
  }

  void _testNavigation(BuildContext context, String locationName) {
    Navigator.pushNamed(
      context,
      AppRoutes.attractionDetailsScreen,
      arguments: {
        'attractionName': locationName,
        'description':
            'Discover the beauty of $locationName. A wonderful destination with breathtaking views and unforgettable experiences waiting for you.',
        'rating': 4.5 + (locationName.hashCode.abs() % 10) / 20,
        'reviews': 50 + (locationName.hashCode.abs() % 200),
        'imagePath': ImageConstant.imgNordicCottage,
      },
    );
  }
}
