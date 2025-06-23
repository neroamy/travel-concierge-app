import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/app_export.dart';
import '../../core/services/google_maps_service.dart';
import './widgets/location_card.dart';

class LocationTargetingScreenWithMaps extends StatefulWidget {
  const LocationTargetingScreenWithMaps({super.key});

  @override
  State<LocationTargetingScreenWithMaps> createState() =>
      _LocationTargetingScreenWithMapsState();
}

class _LocationTargetingScreenWithMapsState
    extends State<LocationTargetingScreenWithMaps> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();

  // Map and location data
  LatLng _currentPosition =
      const LatLng(37.7749, -122.4194); // San Francisco default
  Set<Marker> _markers = {};
  List<PlaceModel> _searchResults = [];
  List<AutocompletePrediction> _suggestions = [];
  bool _isSearching = false;
  bool _isLoading = false;
  int _currentCardIndex = 0;

  // Sample location data for demo
  final List<LocationCardModel> _sampleLocations = [
    LocationCardModel(
      title: "Sunset evening avenue",
      image: ImageConstant.imgRectangle465,
      price: "\$299 / night",
      rating: 4,
      isFavorited: false,
    ),
    LocationCardModel(
      title: "Hanging bridge resort",
      image: ImageConstant.imgRectangle464,
      price: "\$199 / night",
      rating: 4,
      isFavorited: true,
    ),
    LocationCardModel(
      title: "Mountain view lodge",
      image: ImageConstant.imgRectangle463,
      price: "\$399 / night",
      rating: 5,
      isFavorited: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _addSampleMarkers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Initialize user location
  Future<void> _initializeLocation() async {
    try {
      Position? position = await GoogleMapsService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        _moveCamera(_currentPosition);
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
    }
  }

  /// Add sample markers to the map
  void _addSampleMarkers() {
    final sampleMarkers = <Marker>{
      Marker(
        markerId: const MarkerId('sample1'),
        position: const LatLng(37.7849, -122.4094),
        infoWindow: const InfoWindow(title: 'Hotel California'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: const MarkerId('sample2'),
        position: const LatLng(37.7649, -122.4294),
        infoWindow: const InfoWindow(title: 'Golden Gate View'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: const MarkerId('sample3'),
        position: const LatLng(37.7549, -122.4394),
        infoWindow: const InfoWindow(title: 'Ocean Breeze Lodge'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };

    setState(() {
      _markers = sampleMarkers;
    });
  }

  /// Move camera to specific position
  Future<void> _moveCamera(LatLng position) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 14.0),
      ),
    );
  }

  /// Handle search functionality
  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
        _suggestions.clear();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    try {
      // Get search results from Google Places API
      final results = await GoogleMapsService.searchPlaces(query);

      if (results.isNotEmpty) {
        // Clear existing markers and add new ones
        Set<Marker> newMarkers = {};

        for (int i = 0; i < results.length; i++) {
          final place = results[i];
          newMarkers.add(
            Marker(
              markerId: MarkerId(place.placeId),
              position: LatLng(place.latitude, place.longitude),
              infoWindow: InfoWindow(
                title: place.name,
                snippet: place.address,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
            ),
          );
        }

        setState(() {
          _searchResults = results;
          _markers = newMarkers;
          _isLoading = false;
        });

        // Move camera to first result
        if (results.isNotEmpty) {
          _moveCamera(LatLng(results.first.latitude, results.first.longitude));
        }

        // Show success message
        if (mounted) {
          _showSnackBarSafe('Found ${results.length} results for "$query"');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          _showSnackBarSafe('No results found for "$query"');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        String errorMessage = 'Error searching places';
        if (e.toString().contains('Google API Error')) {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        } else if (e.toString().contains('HTTP Error')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        _showSnackBarSafe(errorMessage);
      }
      debugPrint('Search error: $e');
    }
  }

  /// Handle search autocomplete
  Future<void> _onSearchChanged(String value) async {
    if (value.length > 2) {
      try {
        final suggestions =
            await GoogleMapsService.getAutocompletePredictions(value);
        setState(() {
          _suggestions = suggestions;
        });
      } catch (e) {
        debugPrint('Error getting autocomplete: $e');
        // Don't show error for autocomplete failures, just clear suggestions
        setState(() {
          _suggestions.clear();
        });
      }
    } else {
      setState(() {
        _suggestions.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          _buildGoogleMap(),

          // Header Section
          _buildHeaderSection(),

          // Search Suggestions Overlay
          if (_suggestions.isNotEmpty) _buildSearchSuggestions(),

          // Bottom Section with Location Cards
          _buildBottomSection(),
        ],
      ),
    );
  }

  /// Builds Google Map
  Widget _buildGoogleMap() {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController.complete(controller);
      },
      initialCameraPosition: CameraPosition(
        target: _currentPosition,
        zoom: 14.0,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapType: MapType.normal,
      onTap: (LatLng position) {
        // Clear suggestions when tapping on map
        setState(() {
          _suggestions.clear();
        });
      },
    );
  }

  /// Builds the header section with back button, search bar and filter
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

            // Filter/My Location Button
            _buildLocationButton(),
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
              color: appTheme.blackCustom.withOpacity(0.1),
              blurRadius: 8.h,
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
      height: 48.h,
      decoration: BoxDecoration(
        color: appTheme.whiteCustom,
        borderRadius: BorderRadius.circular(24.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.blackCustom.withOpacity(0.1),
            blurRadius: 8.h,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 16.h),
          Icon(
            Icons.search,
            color: Colors.grey[600],
            size: 22.h,
          ),
          SizedBox(width: 8.h),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search places...",
                hintStyle: TextStyle(
                  fontSize: 16.fSize,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
                border: InputBorder.none,
              ),
              style: TextStyle(
                fontSize: 16.fSize,
                color: appTheme.blackCustom,
                fontFamily: 'Poppins',
              ),
              onChanged: _onSearchChanged,
              onSubmitted: _onSearch,
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.h),
              child: SizedBox(
                width: 20.h,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: appTheme.colorFF0373,
                ),
              ),
            )
          else if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _suggestions.clear();
                  _isSearching = false;
                });
                _addSampleMarkers();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.h),
                child: Icon(
                  Icons.clear,
                  color: Colors.grey[600],
                  size: 20.h,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the location button
  Widget _buildLocationButton() {
    return GestureDetector(
      onTap: () async {
        // Get current location and move camera
        Position? position = await GoogleMapsService.getCurrentLocation();
        if (position != null) {
          LatLng newPosition = LatLng(position.latitude, position.longitude);
          setState(() {
            _currentPosition = newPosition;
          });
          _moveCamera(newPosition);
        }
      },
      child: Container(
        width: 48.h,
        height: 48.h,
        decoration: BoxDecoration(
          color: appTheme.colorFF0373,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: appTheme.colorFF0373.withOpacity(0.3),
              blurRadius: 8.h,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Icon(
          Icons.my_location,
          color: appTheme.whiteCustom,
          size: 24.h,
        ),
      ),
    );
  }

  /// Builds search suggestions overlay
  Widget _buildSearchSuggestions() {
    return Positioned(
      top: 120.h,
      left: 24.h,
      right: 24.h,
      child: Container(
        constraints: BoxConstraints(maxHeight: 200.h),
        decoration: BoxDecoration(
          color: appTheme.whiteCustom,
          borderRadius: BorderRadius.circular(12.h),
          boxShadow: [
            BoxShadow(
              color: appTheme.blackCustom.withOpacity(0.1),
              blurRadius: 8.h,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = _suggestions[index];
            return ListTile(
              leading: Icon(
                Icons.location_on,
                color: appTheme.colorFF0373,
                size: 20.h,
              ),
              title: Text(
                suggestion.mainText,
                style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
              subtitle: suggestion.secondaryText != null
                  ? Text(
                      suggestion.secondaryText!,
                      style: TextStyle(
                        fontSize: 12.fSize,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    )
                  : null,
              onTap: () {
                _searchController.text = suggestion.mainText;
                setState(() {
                  _suggestions.clear();
                });
                _onSearch(suggestion.mainText);
              },
            );
          },
        ),
      ),
    );
  }

  /// Builds the bottom section with title and location cards
  Widget _buildBottomSection() {
    final locations = _isSearching && _searchResults.isNotEmpty
        ? _convertSearchResultsToLocationCards()
        : _sampleLocations;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Container(
          margin: EdgeInsets.only(top: 60.h),
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
                  "Location targeting",
                  style: TextStyle(
                    fontSize: 24.fSize,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: appTheme.whiteCustom,
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Location Cards
              SizedBox(
                height: 166.h,
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
                        onTap: () =>
                            _navigateToLocationDetails(locations[index]),
                        onFavoriteToggle: () => _toggleFavorite(index),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Convert search results to location cards
  List<LocationCardModel> _convertSearchResultsToLocationCards() {
    return _searchResults.map((place) {
      return LocationCardModel(
        title: place.name,
        image: ImageConstant.imgRectangle465, // Default image
        price: "\$${(place.rating ?? 4.0) * 100} / night", // Mock pricing
        rating: (place.rating ?? 4.0).round(),
        isFavorited: false,
      );
    }).toList();
  }

  /// Navigate to location details screen
  void _navigateToLocationDetails(LocationCardModel location) {
    Navigator.pushNamed(
      context,
      AppRoutes.attractionDetailsScreen,
      arguments: {
        'attractionName': location.title,
        'description':
            'Discover the beauty of ${location.title}. Experience luxury accommodation with stunning views and world-class amenities.',
        'rating': location.rating.toDouble(),
        'reviews': 120 + (location.title.hashCode.abs() % 180),
        'imagePath': location.image,
      },
    );
  }

  /// Toggle favorite status
  void _toggleFavorite(int index) {
    setState(() {
      _showSnackBar("Added to favorites!");
    });
  }

  /// Helper method to show snackbar messages safely
  void _showSnackBarSafe(String message) {
    if (!mounted) return;

    try {
      ScaffoldMessenger.of(context)
          .clearSnackBars(); // Clear existing snackbars first
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: appTheme.colorFF0373,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.h),
        ),
      );
    } catch (e) {
      debugPrint('Error showing snackbar: $e');
    }
  }

  /// Legacy method for compatibility
  void _showSnackBar(String message) => _showSnackBarSafe(message);
}
