import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/travel_concierge_service.dart';
import '../../../core/services/auth_service.dart';

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
    print('🏗️ Creating LocationCardModel from PlaceSearchResult:');
    print('   - Title: ${place.title}');
    print('   - Image URL: ${place.imageUrl ?? "NULL"}');

    return LocationCardModel(
      title: place.title,
      address: place.address,
      highlights: place.highlights,
      rating: place.rating,
      latitude: place.latitude,
      longitude: place.longitude,
      image: place.imageUrl, // Use API image URL
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
class LocationCard extends StatefulWidget {
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
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  bool _isSaved = false;
  bool _isSaving = false;

  Future<void> _handleSavePlace(BuildContext context) async {
    if (_isSaved || _isSaving) return;
    setState(() {
      _isSaving = true;
    });
    final userUuid = AuthService().currentUser?.id;
    if (userUuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Bạn cần đăng nhập để lưu địa điểm!'),
            backgroundColor: Colors.red),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }
    final place = {
      'place_name': widget.location.title,
      'address': widget.location.address,
      'lat': widget.location.latitude?.toString() ?? '',
      'long': widget.location.longitude?.toString() ?? '',
      'review_ratings': widget.location.rating.toString(),
      'highlights': widget.location.highlights,
      'image_url': widget.location.image ?? '',
      'map_url': '', // Add if available
      'place_id': '', // Add if available
    };
    final (success, message) =
        await TravelConciergeService().savePlace(userUuid, place);
    if (success) {
      setState(() {
        _isSaved = true;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Đã lưu địa điểm!'), backgroundColor: Colors.green),
      );
    } else {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Lưu thất bại: $message'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 271.h,
        height: 300.h, // Tăng chiều cao card thêm
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
              _buildLocationImage(),
              SizedBox(width: 14.h),
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 6.h),
                      _buildLocationTitle(),
                      SizedBox(height: 8.h),
                      _buildAddressSection(),
                      SizedBox(height: 8.h),
                      _buildHighlightsSection(),
                      SizedBox(height: 8.h),
                      _buildRatingSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the location image section
  Widget _buildLocationImage() {
    // Fallback logic for image
    String? imagePath = widget.location.image;

    // Log the image path for debugging
    print('🖼️ Location Card Image Debug:');
    print('   Location: ${widget.location.title}');
    print('   Raw image path: $imagePath');

    // Only use fallback if truly empty or invalid
    bool shouldUseFallback = false;
    if (imagePath == null ||
        imagePath.isEmpty ||
        imagePath == 'null' ||
        imagePath.trim().isEmpty) {
      shouldUseFallback = true;
      print('   ❌ Using fallback: Empty or null image path');
    } else {
      print('   ✅ Using provided image URL: $imagePath');
    }

    if (shouldUseFallback) {
      imagePath = ImageConstant.imgImageNotFound;
    }

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
          imagePath: imagePath,
          fit: BoxFit.cover,
          width: 80.h,
          height: 140.h,
          placeHolder:
              ImageConstant.imgImageNotFound, // Ensure fallback is passed
        ),
      ),
    );
  }

  /// Builds the location details section
  // _buildLocationDetails không còn cần thiết, có thể xóa hoặc để trống nếu còn dùng nơi khác

  /// Builds the location title
  Widget _buildLocationTitle() {
    return Text(
      widget.location.title,
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
          child: GestureDetector(
            onTap: () async {
              final encoded = Uri.encodeComponent(widget.location.address);
              final url =
                  'https://www.google.com/maps/search/?api=1&query=$encoded';
              if (await canLaunch(url)) {
                await launch(url);
              }
            },
            child: Text(
              widget.location.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.fSize,
                fontWeight: FontWeight.w400,
                fontFamily: 'Poppins',
                color: Colors.blue, // Keep blue for clickable
                // Remove underline
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the highlights section
  Widget _buildHighlightsSection() {
    return Text(
      widget.location.highlights,
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
          widget.location.rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 14.fSize,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            color: appTheme.blackCustom,
          ),
        ),
        const Spacer(),
        // Save (bookmark) icon at the end of the row
        _isSaved
            ? Icon(Icons.check_circle, color: Colors.green)
            : _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: Icon(Icons.save_alt, color: Colors.grey),
                    tooltip: 'Lưu địa điểm',
                    onPressed: () => _handleSavePlace(context),
                  ),
      ],
    );
  }

  /// Builds the favorite button (optional)
  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: widget.onFavoriteToggle,
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
