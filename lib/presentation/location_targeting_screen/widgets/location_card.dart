import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';

/// Model class for location cards
class LocationCardModel {
  final String title;
  final String image;
  final String price;
  final int rating;
  final bool isFavorited;

  LocationCardModel({
    required this.title,
    required this.image,
    required this.price,
    required this.rating,
    required this.isFavorited,
  });
}

/// Widget for displaying location card with image, title, rating, and price
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
          imagePath: location.image,
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

        SizedBox(height: 16.h),

        // Rating Section
        _buildRatingSection(),

        SizedBox(height: 12.h),

        // Price Section with Favorite Button
        _buildPriceSection(),
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
        fontSize: 16.fSize,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
        color: appTheme.blackCustom,
        height: 1.2,
      ),
    );
  }

  /// Builds the rating section with stars
  Widget _buildRatingSection() {
    return Row(
      children: [
        // Star Rating
        ...List.generate(5, (index) {
          return Padding(
            padding: EdgeInsets.only(right: 3.h),
            child: Icon(
              index < location.rating ? Icons.star : Icons.star_border,
              size: 14.h,
              color: index < location.rating
                  ? const Color(0xFFFFB800)
                  : const Color(0xFFE0E0E0),
            ),
          );
        }),
      ],
    );
  }

  /// Builds the price section with favorite button
  Widget _buildPriceSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "from" label
              Text(
                "from",
                style: TextStyle(
                  fontSize: 12.fSize,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Poppins',
                  color: const Color(0xFFAEAEAE),
                ),
              ),

              SizedBox(height: 4.h),

              // Price
              Text(
                location.price,
                style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                  color: appTheme.blackCustom,
                ),
              ),
            ],
          ),
        ),

        // Favorite Button
        _buildFavoriteButton(),
      ],
    );
  }

  /// Builds the favorite button
  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: onFavoriteToggle,
      child: Container(
        width: 34.h,
        height: 34.h,
        decoration: BoxDecoration(
          color: location.isFavorited
              ? appTheme.colorFF0373.withOpacity(0.1)
              : const Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          location.isFavorited ? Icons.favorite : Icons.favorite_border,
          size: 16.h,
          color: location.isFavorited
              ? appTheme.colorFF0373
              : const Color(0xFFAEAEAE),
        ),
      ),
    );
  }
}
