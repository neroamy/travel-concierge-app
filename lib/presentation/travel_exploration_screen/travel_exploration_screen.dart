import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import './widgets/bottom_nav_item.dart';
import './widgets/location_category_card.dart';
import './widgets/travel_destination_card.dart';

class TravelExplorationScreen extends StatefulWidget {
  const TravelExplorationScreen({super.key});

  @override
  State<TravelExplorationScreen> createState() =>
      _TravelExplorationScreenState();
}

class _TravelExplorationScreenState extends State<TravelExplorationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TravelConciergeService _travelService = TravelConciergeService();

  bool _sessionInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeSession() async {
    final success = await _travelService.initializeSession();
    setState(() {
      _sessionInitialized = success;
    });

    if (!success && mounted) {
      // Use WidgetsBinding to ensure the frame is complete before showing snackbar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Failed to connect to Travel Concierge. Please check if the server is running.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;

    print('🚀 Navigating to AI Chat with query: "$query"');

    // Navigate to AI Chat Screen instead of direct search
    Navigator.pushNamed(
      context,
      AppRoutes.aiChatScreen,
      arguments: {
        'initialQuery': query.trim(),
      },
    );
  }

  void _showSearchingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: appTheme.colorFF0373),
            SizedBox(width: 16.h),
            const Text('Searching locations...'),
          ],
        ),
      ),
    );
  }

  void _performSearch(String query) async {
    try {
      // Use the AI service to search
      final searchResults = <PlaceSearchResult>[];

      print('🔍 Starting search for: "$query"');

      await for (final result in _travelService.searchTravel(query)) {
        print('📡 Received result from API:');
        print('   Author: ${result.author}');
        print('   Text length: ${result.text.length}');
        print('   Content: ${result.text}');
        print('---');

        if (result.author != 'system' && result.author != 'user') {
          // This is the AI response with place data
          print('🎯 Processing AI response...');
          final places = ResponseParser.parseAIResponse(result.text);
          print('✅ Parsed ${places.length} places from response');

          for (int i = 0; i < places.length; i++) {
            final place = places[i];
            print('📍 Place $i:');
            print('   Title: ${place.title}');
            print('   Address: ${place.address}');
            print('   Highlights: ${place.highlights}');
            print('   Rating: ${place.rating}');
            print('   Coordinates: ${place.latitude}, ${place.longitude}');
            print('   Google Maps URL: ${place.googleMapsUrl}');
          }

          searchResults.addAll(places);
          break; // Take the first AI response
        }
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        if (searchResults.isNotEmpty) {
          // Navigate to maps screen with search results
          Navigator.pushNamed(
            context,
            AppRoutes.locationTargetingScreenWithMaps,
            arguments: {
              'searchQuery': query,
              'searchResults': searchResults,
            },
          );
        } else {
          // No results found
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No locations found for "$query"'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog and show error
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: Could not get information from Google Maps API'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Search error: $e');
    }
  }

  void _navigateToAttractionDetails(LocationCategoryModel category) {
    Navigator.pushNamed(
      context,
      AppRoutes.attractionDetailsScreen,
      arguments: {
        'attractionName': category.name ?? 'Unknown Location',
        'description':
            'Discover the beauty of ${category.name ?? 'this amazing location'}. With ${category.locationCount ?? 'multiple locations'} to explore, you\'ll find endless opportunities for adventure and relaxation.',
        'rating': 4.5 +
            ((category.name?.hashCode.abs() ?? 0) % 10) /
                20, // Dynamic rating based on name
        'reviews': 50 +
            ((category.name?.hashCode.abs() ?? 0) %
                200), // Dynamic review count
        'imagePath': category.image ?? ImageConstant.imgNordicCottage,
      },
    );
  }

  void _navigateToDestinationDetails(TravelDestinationModel destination) {
    Navigator.pushNamed(
      context,
      AppRoutes.attractionDetailsScreen,
      arguments: {
        'attractionName': destination.name ?? 'Amazing Destination',
        'description':
            'Experience the breathtaking beauty of ${destination.name ?? 'this incredible destination'}. From stunning landscapes to rich culture, this destination offers unforgettable adventures and memories that will last a lifetime.',
        'rating': double.tryParse(destination.rating ?? '4.8') ?? 4.8,
        'reviews': 120 +
            ((destination.name?.hashCode.abs() ?? 0) %
                180), // Dynamic review count
        'imagePath': destination.image ?? ImageConstant.imgNordicCottage,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.maxFinite,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [const Color(0xFFFFFFFF), appTheme.colorFFFAFA],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(),
                      _buildSearchSection(),
                      _buildHorizontalLocationSection(),
                      _buildGridLocationSection(),
                      SizedBox(height: 100.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: EdgeInsets.only(left: 24.h, right: 24.h, top: 80.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Find your next trip",
                style: TextStyleHelper.instance.title16Medium,
              ),
              const Spacer(),
              if (_sessionInitialized)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.h),
                  ),
                  child: const Text(
                    'AI Connected',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            "Nordic scenery",
            style: TextStyleHelper.instance.headline26SemiBold,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: EdgeInsets.only(left: 24.h, right: 24.h, top: 24.h),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50.h,
              decoration: BoxDecoration(
                color: appTheme.whiteCustom,
                borderRadius: BorderRadius.circular(25.h),
                border: Border.all(color: appTheme.colorFFE9E9),
              ),
              child: Row(
                children: [
                  SizedBox(width: 16.h),
                  Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 24.h,
                  ),
                  SizedBox(width: 12.h),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search destinations, places, activities...",
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15.h),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        color: Colors.black,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _onSearchSubmitted,
                      onTap: () {
                        // Debug: Show snackbar when tapped
                        print('TextField tapped!');
                      },
                      onChanged: (value) {
                        // Debug: Print when text changes
                        print('Text changed: $value');
                        setState(() {}); // Update UI for clear button
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        print('Clear button tapped!');
                        _searchController.clear();
                        setState(() {});
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.h),
                        child: Icon(
                          Icons.clear,
                          size: 20.h,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.h),
          // Search Button
          GestureDetector(
            onTap: () {
              print('Search button tapped! Query: ${_searchController.text}');
              final query = _searchController.text.trim();
              if (query.isNotEmpty) {
                _onSearchSubmitted(query);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter search text')),
                );
              }
            },
            child: Container(
              width: 52.h,
              height: 52.h,
              decoration: BoxDecoration(
                color: appTheme.colorFF0373,
                borderRadius: BorderRadius.circular(26.h),
              ),
              child: Icon(
                Icons.search,
                color: Colors.white,
                size: 24.h,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalLocationSection() {
    List<TravelDestinationModel> destinations = [
      TravelDestinationModel(
        name: "Switzerland",
        price: "from \$699",
        rating: "4.9",
        image: ImageConstant.imgRectangle462,
        ratingColor: appTheme.whiteCustom,
        ratingIcon: ImageConstant.imgGroup128,
      ),
      TravelDestinationModel(
        name: "Ilulissat Icefjord",
        price: "from \$726",
        rating: "5.0",
        image: ImageConstant.imgRectangle463,
        ratingColor: appTheme.blackCustom,
        ratingIcon: ImageConstant.imgGroup129,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 24.h, right: 24.h, top: 40.h),
          child: Text(
            "Popular locations",
            style: TextStyleHelper.instance.title18SemiBold,
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 138.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 24.h),
            scrollDirection: Axis.horizontal,
            itemCount: destinations.length,
            separatorBuilder: (context, index) => SizedBox(width: 20.h),
            itemBuilder: (context, index) {
              return TravelDestinationCard(
                destination: destinations[index],
                width: 230.h,
                onTap: () => _navigateToDestinationDetails(destinations[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGridLocationSection() {
    List<LocationCategoryModel> categories = [
      LocationCategoryModel(
        name: "Western Strait",
        locationCount: "16 locations",
        image: ImageConstant.imgRectangle464,
      ),
      LocationCategoryModel(
        name: "Beach House",
        locationCount: "22 locations",
        image: ImageConstant.imgRectangle465,
      ),
      LocationCategoryModel(
        name: "Mountain range",
        locationCount: "36 locations",
        image: ImageConstant.imgRectangle465200x142,
        isFullWidth: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 24.h, right: 24.h, top: 32.h),
          child: Text(
            "Popular locations",
            style: TextStyleHelper.instance.title18SemiBold,
          ),
        ),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.h),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16.h,
              crossAxisSpacing: 16.h,
              childAspectRatio: 1.0,
            ),
            itemCount: 2,
            itemBuilder: (context, index) {
              return LocationCategoryCard(
                category: categories[index],
                onTap: () => _navigateToAttractionDetails(categories[index]),
              );
            },
          ),
        ),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.h),
          child: LocationCategoryCard(
            category: categories[2],
            onTap: () => _navigateToAttractionDetails(categories[2]),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    List<BottomNavItemModel> items = [
      BottomNavItemModel(
        icon: ImageConstant.imgGroup125,
        label: "Home",
        isSelected: true,
      ),
      BottomNavItemModel(
        icon: ImageConstant.imgGroup120,
        label: "Wallet",
        isSelected: false,
      ),
      BottomNavItemModel(
        icon: ImageConstant.imgGroup123,
        label: "Guide",
        isSelected: false,
      ),
      BottomNavItemModel(
        icon: ImageConstant.imgGroup140,
        label: "Chart",
        isSelected: false,
      ),
    ];

    return Container(
      height: 100.h,
      decoration: BoxDecoration(
        color: appTheme.whiteCustom,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.h),
          topRight: Radius.circular(24.h),
        ),
        boxShadow: [
          BoxShadow(
            color: appTheme.blackCustom.withAlpha(13),
            blurRadius: 10.h,
            offset: Offset(0, -5.h),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          items.length,
          (index) => BottomNavItem(item: items[index]),
        ),
      ),
    );
  }
}

class TravelDestinationModel {
  String? name;
  String? price;
  String? rating;
  String? image;
  Color? ratingColor;
  String? ratingIcon;

  TravelDestinationModel({
    this.name,
    this.price,
    this.rating,
    this.image,
    this.ratingColor,
    this.ratingIcon,
  });
}

class LocationCategoryModel {
  String? name;
  String? locationCount;
  String? image;
  bool? isFullWidth;

  LocationCategoryModel({
    this.name,
    this.locationCount,
    this.image,
    this.isFullWidth = false,
  });
}

class BottomNavItemModel {
  String? icon;
  String? label;
  bool? isSelected;

  BottomNavItemModel({this.icon, this.label, this.isSelected});
}
