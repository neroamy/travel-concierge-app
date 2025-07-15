import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import './widgets/location_card.dart';
import './widgets/map_pin.dart';

class LocationTargetingScreen extends StatefulWidget {
  const LocationTargetingScreen({super.key});

  @override
  State<LocationTargetingScreen> createState() =>
      _LocationTargetingScreenState();
}

class _LocationTargetingScreenState extends State<LocationTargetingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  int _currentCardIndex = 0;
  String? _searchQuery;
  List<LocationCardModel> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check if we have search arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['searchQuery'] != null) {
        _searchQuery = args['searchQuery'];
        _searchController.text = _searchQuery!;
        _performSearch(_searchQuery!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _isLoading = true;
      _searchResults.clear();
    });

    // Simulate search results based on query
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      List<LocationCardModel> mockResults = _generateSearchResults(query);

      setState(() {
        _searchResults = mockResults;
        _isLoading = false;
      });
    });
  }

  List<LocationCardModel> _generateSearchResults(String query) {
    // Mock search results based on query
    final allLocations = [
      LocationCardModel.legacy(
        title: "Sunset evening avenue",
        image: ImageConstant.imgRectangle465,
        price: "\$299 / night",
        rating: 4,
        isFavorited: false,
      ),
      LocationCardModel.legacy(
        title: "Hanging bridge resort",
        image: ImageConstant.imgRectangle464,
        price: "\$199 / night",
        rating: 4,
        isFavorited: true,
      ),
      LocationCardModel.legacy(
        title: "Mountain view lodge",
        image: ImageConstant.imgRectangle463,
        price: "\$399 / night",
        rating: 5,
        isFavorited: false,
      ),
      LocationCardModel.legacy(
        title: "Beach paradise resort",
        image: ImageConstant.imgRectangle462,
        price: "\$459 / night",
        rating: 5,
        isFavorited: false,
      ),
      LocationCardModel.legacy(
        title: "Nordic winter cabin",
        image: ImageConstant.imgRectangle465,
        price: "\$199 / night",
        rating: 4,
        isFavorited: false,
      ),
    ];

    // Filter based on search query
    if (query.toLowerCase().contains('beach')) {
      return [allLocations[3], allLocations[0]];
    } else if (query.toLowerCase().contains('mountain')) {
      return [allLocations[2], allLocations[4]];
    } else if (query.toLowerCase().contains('resort')) {
      return [allLocations[1], allLocations[3]];
    } else {
      return allLocations.take(3).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.maxFinite,
        height: double.maxFinite,
        child: Stack(
          children: [
            // Background Map
            _buildMapBackground(),

            // Map Pins
            _buildMapPins(),

            // Header Section
            _buildHeaderSection(),

            // Bottom Section with Location Cards
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  /// Builds the map background
  Widget _buildMapBackground() {
    return Positioned.fill(
      child: CustomImageView(
        // Using map background from Figma
        // In production, this would be replaced with actual map implementation
        imagePath:
            ImageConstant.imgMapBackground, // Placeholder for map background
        fit: BoxFit.cover,
      ),
    );
  }

  /// Builds the map pins scattered across the map
  Widget _buildMapPins() {
    final List<MapPin> pins = [
      MapPin(top: 211.h, left: 53.h),
      MapPin(top: 213.h, left: 148.h),
      MapPin(top: 300.h, left: 181.h),
      MapPin(top: 316.h, left: 243.h),
      MapPin(top: 329.h, left: 337.h),
      MapPin(top: 367.h, left: 121.h),
      MapPin(top: 448.h, left: 195.h),
      MapPin(top: 450.h, left: 318.h),
    ];

    return Stack(
      children: pins.map((pin) => pin).toList(),
    );
  }

  /// Builds the header section with back button, search bar and menu
  Widget _buildHeaderSection() {
    return Positioned(
      top: 60.h,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.h),
        child: Row(
          children: [
            // Back Button
            _buildBackButton(),

            SizedBox(width: 16.h),

            // Search Bar
            Expanded(child: _buildSearchBar()),

            SizedBox(width: 16.h),

            // Filter/Menu Button
            _buildFilterButton(),
          ],
        ),
      ),
    );
  }

  /// Builds the back button
  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 48.h,
        height: 48.h,
        decoration: BoxDecoration(
          color: appTheme.whiteCustom,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: appTheme.blackCustom.withOpacity(0.05),
              blurRadius: 4.h,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          color: appTheme.blackCustom,
          size: 20.h,
        ),
      ),
    );
  }

  /// Builds the search bar
  Widget _buildSearchBar() {
    return Container(
      height: 46.h,
      decoration: BoxDecoration(
        color: appTheme.whiteCustom,
        borderRadius: BorderRadius.circular(23.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.blackCustom.withOpacity(0.05),
            blurRadius: 4.h,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 16.h),
          Icon(
            Icons.search,
            color: appTheme.colorFFBCBC,
            size: 22.h,
          ),
          SizedBox(width: 8.h),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search locations...",
                hintStyle: TextStyle(
                  fontSize: 16.fSize,
                  color: const Color(0xFFAEAEAE),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
              ),
              style: TextStyle(
                fontSize: 16.fSize,
                color: appTheme.blackCustom,
                fontFamily: 'Poppins',
              ),
              onSubmitted: (query) {
                if (query.trim().isNotEmpty) {
                  _performSearch(query);
                }
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              final query = _searchController.text.trim();
              if (query.isNotEmpty) {
                _performSearch(query);
              }
            },
            child: Container(
              margin: EdgeInsets.only(right: 8.h),
              padding: EdgeInsets.all(8.h),
              child: Icon(
                Icons.search,
                color: appTheme.colorFF0373,
                size: 20.h,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the filter button
  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: () {
        // Handle filter tap
        _showSnackBar("Filter options coming soon!");
      },
      child: Container(
        width: 48.h,
        height: 48.h,
        decoration: BoxDecoration(
          color: appTheme.colorFF0373,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.tune,
          color: appTheme.whiteCustom,
          size: 24.h,
        ),
      ),
    );
  }

  /// Builds the bottom section with title and location cards
  Widget _buildBottomSection() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        constraints: BoxConstraints(
          minHeight: 250.h,
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.h),
              child: Text(
                _searchQuery != null
                    ? "Search Results for \"$_searchQuery\""
                    : "Location targeting",
                style: TextStyle(
                  fontSize: 24.fSize,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: appTheme.blackCustom,
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Location Cards Horizontal Scroll
            _buildLocationCards(),
          ],
        ),
      ),
    );
  }

  /// Builds the horizontal scrollable location cards
  Widget _buildLocationCards() {
    if (_isLoading) {
      return SizedBox(
        height: 166.h,
        child: Center(
          child: CircularProgressIndicator(
            color: appTheme.colorFF0373,
          ),
        ),
      );
    }

    final List<LocationCardModel> locations = _searchResults.isNotEmpty
        ? _searchResults
        : [
            LocationCardModel.legacy(
              title: "Sunset evening avenue",
              image: ImageConstant.imgRectangle465,
              price: "\$299 / night",
              rating: 4,
              isFavorited: false,
            ),
            LocationCardModel.legacy(
              title: "Hanging bridge resort",
              image: ImageConstant.imgRectangle464,
              price: "\$199 / night",
              rating: 4,
              isFavorited: true,
            ),
            LocationCardModel.legacy(
              title: "Mountain view lodge",
              image: ImageConstant.imgRectangle463,
              price: "\$399 / night",
              rating: 5,
              isFavorited: false,
            ),
          ];

    if (locations.isEmpty) {
      return SizedBox(
        height: 166.h,
        child: Center(
          child: Text(
            "No locations found for \"$_searchQuery\"",
            style: TextStyle(
              fontSize: 16.fSize,
              color: Colors.grey,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 320.h, // Tăng chiều cao để khớp với LocationCard + padding
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentCardIndex = index;
          });
        },
        itemCount: locations.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 25.h : 8.h,
              right: index == locations.length - 1 ? 25.h : 8.h,
            ),
            child: LocationCard(
              location: locations[index],
              onTap: () => _navigateToLocationDetails(locations[index]),
              onFavoriteToggle: () => _toggleFavorite(index),
            ),
          );
        },
      ),
    );
  }

  /// Navigate to itinerary screen when location is selected
  void _navigateToLocationDetails(LocationCardModel location) {
    // Navigate to plan view screen as specified in requirements
    Navigator.pushNamed(
      context,
      AppRoutes.planViewScreen,
      arguments: {
        'selectedLocation': location.title,
        'locationImage': location.image,
        'locationPrice':
            location.address, // address contains the price for legacy data
        'locationRating': location.rating,
        'highlights': (location.highlights != null &&
                location.highlights.trim().isNotEmpty)
            ? location.highlights
            : '', // Truyền empty nếu không có dữ liệu
      },
    );
  }

  /// Toggle favorite status
  void _toggleFavorite(int index) {
    setState(() {
      // This would update the favorite status in the data model
      _showSnackBar("Added to favorites!");
    });
  }

  /// Helper method to show snackbar messages
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: appTheme.colorFF0373,
      ),
    );
  }
}
