import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';

/// Model class for location cards with new format
class LocationCardModel {
  final String title;
  final String address;
  final String highlights;
  final double rating;
  final String? image;
  final double? latitude;
  final double? longitude;

  LocationCardModel({
    required this.title,
    required this.address,
    required this.highlights,
    required this.rating,
    this.image,
    this.latitude,
    this.longitude,
  });

  // Factory constructor for API data
  factory LocationCardModel.fromPlaceSearchResult(PlaceSearchResult place) {
    return LocationCardModel(
      title: place.title,
      address: place.address,
      highlights: place.highlights,
      rating: place.rating,
      latitude: place.latitude,
      longitude: place.longitude,
      image: null, // Will use default placeholder
    );
  }

  // Factory constructor for legacy data (backward compatibility)
  factory LocationCardModel.legacy({
    required String title,
    required String image,
    required String price,
    required int rating,
    required bool isFavorited,
  }) {
    return LocationCardModel(
      title: title,
      address: price, // Use price as address for legacy
      highlights: 'Legacy location',
      rating: rating.toDouble(),
      image: image,
    );
  }
}

/// Widget for displaying location card with new format
class LocationCard extends StatelessWidget {
  final LocationCardModel location;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const LocationCard({
    super.key,
    required this.location,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 271.h,
        height: 166.h,
        decoration: BoxDecoration(
          color: appTheme.whiteCustom,
          borderRadius: BorderRadius.circular(15.h),
          boxShadow: [
            BoxShadow(
              color: appTheme.blackCustom.withOpacity(0.05),
              blurRadius: 8.h,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Image
              _buildLocationImage(),

              SizedBox(width: 14.h),

              // Location Details
              Expanded(
                child: _buildLocationDetails(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the location image section
  Widget _buildLocationImage() {
    return Container(
      width: 80.h,
      height: 140.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.blackCustom.withOpacity(0.1),
            blurRadius: 4.h,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.h),
        child: CustomImageView(
          imagePath: location.image ??
              ImageConstant.imgRectangle464, // Default placeholder
          fit: BoxFit.cover,
          width: 80.h,
          height: 140.h,
        ),
      ),
    );
  }

  /// Builds the location details section
  Widget _buildLocationDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 6.h),

        // Location Title
        _buildLocationTitle(),

        SizedBox(height: 8.h),

        // Address
        _buildAddressSection(),

        SizedBox(height: 8.h),

        // Highlights
        _buildHighlightsSection(),

        const Spacer(),

        // Rating Section
        _buildRatingSection(),
      ],
    );
  }

  /// Builds the location title
  Widget _buildLocationTitle() {
    return Text(
      location.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 15.fSize,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
        color: appTheme.blackCustom,
        height: 1.2,
      ),
    );
  }

  /// Builds the address section
  Widget _buildAddressSection() {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 12.h,
          color: Colors.grey,
        ),
        SizedBox(width: 4.h),
        Expanded(
          child: Text(
            location.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.fSize,
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins',
              color: Colors.grey[600],
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the highlights section
  Widget _buildHighlightsSection() {
    return Text(
      location.highlights,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12.fSize,
        fontWeight: FontWeight.w400,
        fontFamily: 'Poppins',
        color: Colors.grey[700],
        height: 1.3,
      ),
    );
  }

  /// Builds the rating section with number
  Widget _buildRatingSection() {
    return Row(
      children: [
        Icon(
          Icons.star,
          size: 16.h,
          color: const Color(0xFFFFB800),
        ),
        SizedBox(width: 4.h),
        Text(
          location.rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 14.fSize,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            color: appTheme.blackCustom,
          ),
        ),
        const Spacer(),
        // Optional favorite button (can be removed if not needed)
        if (onFavoriteToggle != null) _buildFavoriteButton(),
      ],
    );
  }

  /// Builds the favorite button (optional)
  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: onFavoriteToggle,
      child: Container(
        width: 28.h,
        height: 28.h,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.favorite_border,
          size: 14.h,
          color: const Color(0xFFAEAEAE),
        ),
      ),
    );
  }
}
