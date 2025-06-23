import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import './demo_navigation.dart';

/// Test navigation for quick access to LocationTargetingScreen
class TestLocationNavigation extends StatelessWidget {
  const TestLocationNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Screen Test'),
        backgroundColor: appTheme.colorFF0373,
        foregroundColor: appTheme.whiteCustom,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.locationTargetingScreen);
            },
            icon: const Icon(Icons.location_on),
            tooltip: 'Quick Launch',
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.h),
        children: [
          _buildTestCard(
            context,
            title: 'Direct Navigation',
            description: 'Navigate directly to Location Targeting Screen',
            icon: Icons.launch,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.locationTargetingScreen);
            },
          ),
          SizedBox(height: 16.h),
          _buildTestCard(
            context,
            title: 'Demo Navigation',
            description: 'Navigate through demo intro screen',
            icon: Icons.preview,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DemoLocationNavigation(),
                ),
              );
            },
          ),
          SizedBox(height: 16.h),
          _buildTestCard(
            context,
            title: 'Screen Info',
            description: 'View screen implementation details',
            icon: Icons.info,
            onTap: () => _showScreenInfo(context),
          ),
          SizedBox(height: 32.h),
          _buildFeaturesList(),
        ],
      ),
    );
  }

  /// Builds a test card widget
  Widget _buildTestCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.h),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.h),
        child: Padding(
          padding: EdgeInsets.all(16.h),
          child: Row(
            children: [
              Container(
                width: 48.h,
                height: 48.h,
                decoration: BoxDecoration(
                  color: appTheme.colorFF0373.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.h),
                ),
                child: Icon(
                  icon,
                  color: appTheme.colorFF0373,
                  size: 24.h,
                ),
              ),
              SizedBox(width: 16.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.fSize,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: appTheme.blackCustom,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14.fSize,
                        fontFamily: 'Poppins',
                        color: appTheme.blackCustom.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: appTheme.blackCustom.withOpacity(0.3),
                size: 16.h,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the features list
  Widget _buildFeaturesList() {
    final features = [
      'Interactive map background',
      'Positioned location pins',
      'Search functionality',
      'Filter options',
      'Horizontal location cards',
      'Star ratings',
      'Favorite functionality',
      'Navigation to details',
      'Responsive design',
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.h),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Screen Features',
              style: TextStyle(
                fontSize: 18.fSize,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: appTheme.blackCustom,
              ),
            ),
            SizedBox(height: 12.h),
            ...features.map((feature) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: appTheme.colorFF0373,
                        size: 16.h,
                      ),
                      SizedBox(width: 8.h),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 14.fSize,
                            fontFamily: 'Poppins',
                            color: appTheme.blackCustom.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Show screen information dialog
  void _showScreenInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Location Targeting Screen',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        content: const Text(
          'This screen implements a location targeting interface based on Figma design. '
          'It includes map background, location pins, search functionality, and '
          'horizontally scrollable location cards with detailed information.',
          style: TextStyle(
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: appTheme.colorFF0373,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
