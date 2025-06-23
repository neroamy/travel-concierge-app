import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../travel_exploration_screen.dart';

/// Demo widget để test navigation từ travel destinations
/// Bạn có thể thêm widget này vào bất kỳ screen nào để test
class DemoTravelDestination extends StatelessWidget {
  const DemoTravelDestination({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.h),
      child: Column(
        children: [
          Text(
            'Demo Travel Destination Navigation',
            style: TextStyleHelper.instance.title16Medium,
          ),
          SizedBox(height: 16.h),

          // Test với Switzerland
          ElevatedButton(
            onPressed: () => _testDestinationNavigation(
              context,
              'Switzerland',
              'from \$699',
              '4.9',
              ImageConstant.imgRectangle462,
            ),
            child: const Text('Test Switzerland'),
          ),
          SizedBox(height: 8.h),

          // Test với Ilulissat Icefjord
          ElevatedButton(
            onPressed: () => _testDestinationNavigation(
              context,
              'Ilulissat Icefjord',
              'from \$726',
              '5.0',
              ImageConstant.imgRectangle463,
            ),
            child: const Text('Test Ilulissat Icefjord'),
          ),
          SizedBox(height: 8.h),

          // Test với custom destination
          ElevatedButton(
            onPressed: () => _testDestinationNavigation(
              context,
              'Custom Paradise',
              'from \$999',
              '4.7',
              ImageConstant.imgNordicCottage,
            ),
            child: const Text('Test Custom Destination'),
          ),
        ],
      ),
    );
  }

  void _testDestinationNavigation(
    BuildContext context,
    String name,
    String price,
    String rating,
    String imagePath,
  ) {
    final destination = TravelDestinationModel(
      name: name,
      price: price,
      rating: rating,
      image: imagePath,
      ratingColor: Colors.white,
      ratingIcon: ImageConstant.imgGroup128,
    );

    Navigator.pushNamed(
      context,
      AppRoutes.attractionDetailsScreen,
      arguments: {
        'attractionName': destination.name ?? 'Amazing Destination',
        'description':
            'Experience the breathtaking beauty of ${destination.name ?? 'this incredible destination'}. From stunning landscapes to rich culture, this destination offers unforgettable adventures and memories that will last a lifetime.',
        'rating': double.tryParse(destination.rating ?? '4.8') ?? 4.8,
        'reviews': 120 + ((destination.name?.hashCode.abs() ?? 0) % 180),
        'imagePath': destination.image ?? ImageConstant.imgNordicCottage,
      },
    );
  }
}
