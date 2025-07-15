import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/app_export.dart';
import '../../core/services/google_maps_service.dart';
import '../../core/services/travel_concierge_service.dart';
import '../../widgets/floating_chat_button.dart';
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
  final TravelConciergeService _travelService = TravelConciergeService();

  // Map and location data
  LatLng? _userPosition; // nullable, only set if user location is available
  LatLng _currentPosition =
      const LatLng(37.7749, -122.4194); // San Francisco default
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {}; // <-- add this
  List<PlaceSearchResult> _searchResults = [];
  List<LocationCardModel> _locationCards = [];
  bool _isLoading = false;
  int _currentCardIndex = 0;
  String? _currentSearchQuery;

  @override
  void initState() {
    super.initState();
    _initializeLocation();

    // Check if we have search arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final searchQuery = args['searchQuery'] as String?;
        final searchResults = args['searchResults'] as List<PlaceSearchResult>?;
        final focusedPlace = args['focusedPlace'] as PlaceSearchResult?;
        final centerOnPlace = args['centerOnPlace'] as bool? ?? false;

        if (searchQuery != null) {
          _searchController.text = searchQuery;
          _currentSearchQuery = searchQuery;
        }

        if (searchResults != null && searchResults.isNotEmpty) {
          _processSearchResults(searchResults);

          // If we have a focused place and should center on it
          if (focusedPlace != null && centerOnPlace) {
            _centerOnPlace(focusedPlace);
          }
        } else if (searchQuery != null) {
          // Fallback to API call if no results provided
          _performSearch(searchQuery);
        }
      }
    });
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
        if (mounted) {
          setState(() {
            _userPosition = LatLng(position.latitude, position.longitude);
            _currentPosition = _userPosition!;
          });
        }
        _moveCamera(_currentPosition);
        _updateRoutePolyline();
      } else {
        _updateRoutePolyline();
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
      _updateRoutePolyline();
    }
  }

  /// Process search results and create markers
  void _processSearchResults(List<PlaceSearchResult> results) {
    final Set<Marker> newMarkers = {};
    final List<LocationCardModel> cards = [];

    for (int i = 0; i < results.length; i++) {
      final place = results[i];

      // Create marker
      newMarkers.add(
        Marker(
          markerId: MarkerId('place_$i'),
          position: LatLng(place.latitude, place.longitude),
          infoWindow: InfoWindow(
            title: place.title,
            snippet: place.address,
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          onTap: () => _onMarkerTapped(i),
        ),
      );

      // Create location card
      cards.add(LocationCardModel.fromPlaceSearchResult(place));
    }

    setState(() {
      _searchResults = results;
      _locationCards = cards;
      _markers = newMarkers;
    });
    _updateRoutePolyline();
    // Move camera to first result
    if (results.isNotEmpty) {
      _moveCamera(LatLng(results.first.latitude, results.first.longitude));
    }
  }

  /// Update route polyline between user and destination
  void _updateRoutePolyline() async {
    List<LatLng> points = [];
    LatLng? origin = _userPosition;
    if (_searchResults.isEmpty) {
      if (mounted) {
        setState(() {
          _polylines = {};
        });
      }
      return;
    }
    if (origin == null) {
      origin =
          LatLng(_searchResults.first.latitude, _searchResults.first.longitude);
    }
    // Make the route a loop: destination is the first waypoint
    LatLng destination =
        LatLng(_searchResults.first.latitude, _searchResults.first.longitude);
    List<LatLng> waypoints = [];
    if (_searchResults.length > 2) {
      waypoints = _searchResults
          .sublist(1)
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
    }
    try {
      final routePoints = await GoogleMapsService.getTurnByTurnRoute(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
      );
      debugPrint('Route points count: \'${routePoints.length}\'');
      if (routePoints.isNotEmpty) {
        if (mounted) {
          setState(() {
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                color: Colors.blue,
                width: 5,
                points: routePoints,
              ),
            };
          });
        }
        if (mounted) {
          await _fitMapToPolylineAndMarkers(routePoints);
        }
      } else {
        debugPrint('No route points returned from Directions API.');
        if (mounted) {
          setState(() {
            _polylines = {};
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching turn-by-turn route: $e');
      if (mounted) {
        setState(() {
          _polylines = {};
        });
      }
    }
  }

  /// Center map on a specific place and show its location card
  Future<void> _centerOnPlace(PlaceSearchResult place) async {
    try {
      final placeLocation = LatLng(place.latitude, place.longitude);

      // Move camera to the place
      _moveCamera(placeLocation);

      // Find the index of this place in the location cards
      final placeIndex = _locationCards.indexWhere((card) =>
          card.title == place.title &&
          card.latitude == place.latitude &&
          card.longitude == place.longitude);

      if (placeIndex != -1) {
        // Update current card index and scroll to it
        if (mounted) {
          setState(() {
            _currentCardIndex = placeIndex;
          });
        }

        // Scroll to the corresponding card with animation
        if (_pageController.hasClients && mounted) {
          await _pageController.animateToPage(
            placeIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }

      // Update route polyline to this destination
      _updateRoutePolyline();
    } catch (e) {
      debugPrint('Error centering on place: $e');
    }
  }

  Future<void> _fitMapToPolylineAndMarkers(List<LatLng> routePoints) async {
    if (routePoints.isEmpty && _markers.isEmpty) return;
    LatLngBounds bounds;
    List<LatLng> allPoints = [
      ...routePoints,
      ..._markers.map((m) => m.position),
    ];
    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;
    for (final p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  /// Perform search using AI API
  Future<void> _performSearch(String query) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final searchResults = <PlaceSearchResult>[];

      await for (final result in _travelService.searchTravel(query)) {
        if (result.author != 'system' && result.author != 'user') {
          // This is the AI response with place data
          final places = await ResponseParser.parseAIResponse(result.text);
          searchResults.addAll(places);
          break; // Take the first AI response
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (searchResults.isNotEmpty) {
        _processSearchResults(searchResults);
        _showSnackBarSafe('Found ${searchResults.length} results for "$query"');
      } else {
        _showSnackBarSafe('No locations found for "$query"');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _showSnackBarSafe(
          'Error: Could not get information from Google Maps API');
      debugPrint('Search error: $e');
    }
  }

  /// Handle marker tap - zoom to location and scroll to corresponding card
  void _onMarkerTapped(int index) {
    if (index < _searchResults.length) {
      final place = _searchResults[index];
      _moveCamera(LatLng(place.latitude, place.longitude), zoom: 16.0);

      // Scroll to corresponding card
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      if (mounted) {
        setState(() {
          _currentCardIndex = index;
        });
      }
    }
  }

  /// Handle card tap - zoom to marker
  void _onCardTapped(int index) {
    if (index < _searchResults.length) {
      final place = _searchResults[index];
      _moveCamera(LatLng(place.latitude, place.longitude), zoom: 16.0);

      if (mounted) {
        setState(() {
          _currentCardIndex = index;
        });
      }
    }
  }

  /// Move camera to specific position
  Future<void> _moveCamera(LatLng position, {double zoom = 14.0}) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: zoom),
      ),
    );
  }

  /// Handle search functionality
  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) return;

    _currentSearchQuery = query.trim();
    await _performSearch(_currentSearchQuery!);
  }

  /// Safe snackbar display
  void _showSnackBarSafe(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
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

          // Bottom Section with Location Cards
          if (_locationCards.isNotEmpty) _buildBottomSection(),

          // No results message
          if (!_isLoading &&
              _locationCards.isEmpty &&
              _currentSearchQuery != null)
            _buildNoResultsMessage(),

          // Floating Chat Button
          const FloatingChatButton(),
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
      polylines: _polylines, // <-- add this
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapType: MapType.normal,
    );
  }

  /// Builds the header section with back button and search bar
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

            // My Location Button
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
                if (mounted) {
                  setState(() {
                    _locationCards.clear();
                    _markers.clear();
                    _searchResults.clear();
                    _currentSearchQuery = null;
                  });
                }
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

  /// Builds the my location button
  Widget _buildLocationButton() {
    return GestureDetector(
      onTap: () async {
        try {
          Position? position = await GoogleMapsService.getCurrentLocation();
          if (position != null) {
            final currentPos = LatLng(position.latitude, position.longitude);
            if (mounted) {
              setState(() {
                _userPosition = currentPos;
                _currentPosition = currentPos;
              });
            }
            _moveCamera(currentPos);
            _updateRoutePolyline();
          }
        } catch (e) {
          _showSnackBarSafe('Could not get current location');
        }
      },
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
          Icons.my_location,
          color: appTheme.colorFF0373,
          size: 20.h,
        ),
      ),
    );
  }

  /// Builds the bottom section with location cards
  Widget _buildBottomSection() {
    return Positioned(
      bottom: 30.h,
      left: 0,
      right: 0,
      child: SizedBox(
        height:
            180.h, // Tăng height để phù hợp với LocationCard 300.h + padding
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            if (mounted) {
              setState(() {
                _currentCardIndex = index;
              });
            }
            // Auto-zoom to marker when swiping cards
            if (index < _searchResults.length) {
              final place = _searchResults[index];
              _moveCamera(LatLng(place.latitude, place.longitude), zoom: 16.0);
            }
          },
          itemCount: _locationCards.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 52.h),
              child: LocationCard(
                location: _locationCards[index],
                onTap: () => _onCardTapped(index),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds no results message
  Widget _buildNoResultsMessage() {
    return Positioned(
      bottom: 100.h,
      left: 24.h,
      right: 24.h,
      child: Container(
        padding: EdgeInsets.all(20.h),
        decoration: BoxDecoration(
          color: appTheme.whiteCustom,
          borderRadius: BorderRadius.circular(15.h),
          boxShadow: [
            BoxShadow(
              color: appTheme.blackCustom.withOpacity(0.1),
              blurRadius: 8.h,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48.h,
              color: Colors.grey,
            ),
            SizedBox(height: 12.h),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 16.fSize,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: appTheme.blackCustom,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Try searching for a different location',
              style: TextStyle(
                fontSize: 14.fSize,
                fontWeight: FontWeight.w400,
                fontFamily: 'Poppins',
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
