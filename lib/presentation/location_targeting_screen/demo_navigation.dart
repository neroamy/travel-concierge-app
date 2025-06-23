import 'package:flutter/material.dart';

import '../../core/app_export.dart';

/// Demo navigation screen for testing LocationTargetingScreen
class DemoLocationNavigation extends StatelessWidget {
  const DemoLocationNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Screen Demo'),
        backgroundColor: appTheme.colorFF0373,
        foregroundColor: appTheme.whiteCustom,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: 80.h,
                color: appTheme.colorFF0373,
              ),
              SizedBox(height: 32.h),
              Text(
                'Location Targeting Screen',
                style: TextStyle(
                  fontSize: 24.fSize,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: appTheme.blackCustom,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                'Discover amazing locations around you with interactive map and detailed location cards.',
                style: TextStyle(
                  fontSize: 16.fSize,
                  fontFamily: 'Poppins',
                  color: appTheme.blackCustom.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.locationTargetingScreen,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appTheme.colorFF0373,
                  foregroundColor: appTheme.whiteCustom,
                  padding: EdgeInsets.symmetric(
                    horizontal: 32.h,
                    vertical: 16.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.h),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'Open Location Screen',
                  style: TextStyle(
                    fontSize: 16.fSize,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: appTheme.colorFF0373,
                  side: BorderSide(
                    color: appTheme.colorFF0373,
                    width: 2,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 32.h,
                    vertical: 16.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.h),
                  ),
                ),
                child: Text(
                  'Back to Main',
                  style: TextStyle(
                    fontSize: 16.fSize,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
