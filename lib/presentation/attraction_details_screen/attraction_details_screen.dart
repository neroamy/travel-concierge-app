import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';

class AttractionDetailsScreen extends StatefulWidget {
  const AttractionDetailsScreen({super.key});

  @override
  State<AttractionDetailsScreen> createState() =>
      _AttractionDetailsScreenState();
}

class _AttractionDetailsScreenState extends State<AttractionDetailsScreen> {
  Map<String, dynamic> attractionData = {
    'attractionName': 'Nordic Cottage',
    'description':
        'Blue Lagoon Drive from Reykjavík, the capital of Iceland, to the southeast for about an hour, you can reach Blue Lagoon, the famous',
    'rating': 4.79,
    'reviews': 78,
    'imagePath': ImageConstant.imgNordicCottage,
  };

  @override
  void initState() {
    super.initState();
    // Get data passed from navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          attractionData = args;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.maxFinite,
        height: double.maxFinite,
        child: Stack(
          children: [
            // Background Image
            _buildBackgroundImage(),

            // Content Overlay
            _buildContentOverlay(),

            // Back Button
            _buildBackButton(),
          ],
        ),
      ),
    );
  }

  /// Builds the full-screen background image
  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: CustomImageView(
        imagePath:
            attractionData['imagePath'] ?? ImageConstant.imgNordicCottage,
        fit: BoxFit.cover,
      ),
    );
  }

  /// Builds the content overlay with gradient background
  Widget _buildContentOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        constraints: BoxConstraints(
          minHeight: 350.h,
          maxHeight: MediaQuery.of(context).size.height *
              0.6, // Max 60% of screen height
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAttractionTitle(),
              SizedBox(height: 12.h),
              Flexible(child: _buildDescription()),
              SizedBox(height: 16.h),
              _buildRatingSection(),
              SizedBox(height: 24.h),
              _buildActionButtons(),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the back button positioned at top-left
  Widget _buildBackButton() {
    return Positioned(
      top: 60.h,
      left: 24.h,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: 40.h,
          height: 40.h,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20.h),
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: appTheme.whiteCustom,
            size: 20.h,
          ),
        ),
      ),
    );
  }

  /// Builds the attraction title
  Widget _buildAttractionTitle() {
    return Text(
      attractionData['attractionName'] ?? "Nordic Cottage",
      style: TextStyle(
        fontSize: 42.fSize,
        fontWeight: FontWeight.w400,
        fontFamily: 'Andika',
        color: appTheme.whiteCustom,
        height: 1.0,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Builds the description text
  Widget _buildDescription() {
    return Text(
      attractionData['description'] ??
          "Blue Lagoon Drive from Reykjavík, the capital of Iceland, to the southeast for about an hour, you can reach Blue Lagoon, the famous",
      style: TextStyle(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w400,
        fontFamily: 'Poppins',
        color: appTheme.whiteCustom.withOpacity(0.8),
        height: 1.4,
      ),
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Builds the rating section with stars and reviews
  Widget _buildRatingSection() {
    return Row(
      children: [
        // Star rating - Fixed size
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Container(
              margin: EdgeInsets.only(right: 4.h),
              child: Icon(
                Icons.star,
                color: const Color(0xFFFFD700), // Gold color for stars
                size: 20.h,
              ),
            );
          }),
        ),
        SizedBox(width: 8.h),

        // Rating score - Fixed size
        Text(
          "${attractionData['rating'] ?? 4.79}",
          style: TextStyle(
            fontSize: 14.fSize,
            fontWeight: FontWeight.w400,
            fontFamily: 'Poppins',
            color: appTheme.whiteCustom,
          ),
        ),
        SizedBox(width: 8.h),

        // Review count - Flexible to prevent overflow
        Flexible(
          child: Text(
            "(${attractionData['reviews'] ?? 78} reviews)",
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins',
              color: appTheme.whiteCustom.withOpacity(0.8),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        SizedBox(width: 16.h),

        // See reviews link - Fixed size
        GestureDetector(
          onTap: () {
            // Handle see reviews tap
            _showSnackBar("Reviews feature coming soon!");
          },
          child: Text(
            "See reviews",
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins',
              color: appTheme.whiteCustom,
              decoration: TextDecoration.underline,
              decorationColor: appTheme.whiteCustom,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the action buttons at the bottom
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Enter the plan button (transparent with white border)
        Expanded(
          child: GestureDetector(
            onTap: () {
              _showSnackBar("Entering the plan...");
            },
            child: Container(
              height: 54.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(27.h),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  "Enter the plan",
                  style: TextStyle(
                    fontSize: 16.fSize,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    color: appTheme.whiteCustom,
                  ),
                ),
              ),
            ),
          ),
        ),

        SizedBox(width: 16.h),

        // View other button (white background)
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                  context, AppRoutes.locationTargetingScreenWithMaps);
            },
            child: Container(
              height: 54.h,
              decoration: BoxDecoration(
                color: appTheme.whiteCustom,
                borderRadius: BorderRadius.circular(27.h),
              ),
              child: Center(
                child: Text(
                  "Explore Map",
                  style: TextStyle(
                    fontSize: 16.fSize,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    color: appTheme.blackCustom,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Helper method to show snackbar messages
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.black.withOpacity(0.8),
      ),
    );
  }
}
