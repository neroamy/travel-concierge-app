import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/floating_chat_button.dart';
import '../travel_exploration_screen/widgets/shared_bottom_nav_bar.dart';
import '../../core/services/travel_concierge_service.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/custom_image_view.dart';

class PlaceListScreen extends StatefulWidget {
  const PlaceListScreen({super.key});

  @override
  State<PlaceListScreen> createState() => _PlaceListScreenState();
}

class _PlaceListScreenState extends State<PlaceListScreen> {
  final TravelConciergeService _travelService = TravelConciergeService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _userPlaces = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUserPlaces();
  }

  /// Fetch user places from API
  Future<void> _fetchUserPlaces() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final userUuid = _authService.currentUser?.id;
      if (userUuid != null && userUuid.isNotEmpty) {
        final places = await _travelService.getUserPlaces(userUuid);
        setState(() {
          _userPlaces = places;
          _isLoading = false;
        });
      } else {
        setState(() {
          _userPlaces = [];
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'User not logged in';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load places: ${e.toString()}';
      });
    }
  }

  /// Pull to refresh
  Future<void> _onRefresh() async {
    await _fetchUserPlaces();
  }

  /// Navigate to attraction details
  void _navigateToAttractionDetails(Map<String, dynamic> place) {
    Navigator.pushNamed(
      context,
      AppRoutes.attractionDetailsScreen,
      arguments: {
        'attractionName': place['place_name'] ?? '',
        'description': place['highlights'] ?? '',
        'rating': double.tryParse(place['review_ratings'] ?? '0') ?? 0.0,
        'reviews': 0,
        'imagePath': (place['image_url'] == null ||
                place['image_url'].toString().isEmpty ||
                place['image_url'].toString().contains('example.com'))
            ? ImageConstant.imgImageNotFound
            : place['image_url'],
        'address': place['address'] ?? '',
        'mapUrl': place['map_url'] ?? '',
        'place_uuid': place['place_uuid'] ?? '',
        'highlights': place['highlights'] ?? '',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteCustom,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SharedBottomNavBar(selectedIndex: 2),
      floatingActionButton: const FloatingChatButton(),
    );
  }

  /// Header section
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.arrow_back_ios,
              size: 24.h,
              color: appTheme.blackCustom,
            ),
          ),
          // Title
          Text(
            "Your Places",
            style: TextStyle(
              fontSize: 18.fSize,
              fontWeight: FontWeight.w600,
              color: appTheme.blackCustom,
              fontFamily: 'Poppins',
            ),
          ),
          // Refresh button
          GestureDetector(
            onTap: _onRefresh,
            child: Icon(
              Icons.refresh,
              size: 24.h,
              color: appTheme.blackCustom,
            ),
          ),
        ],
      ),
    );
  }

  /// Content section
  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_userPlaces.isEmpty) {
      return _buildEmptyState();
    }

    return _buildPlacesList();
  }

  /// Loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: appTheme.colorFF0373),
          SizedBox(height: 16.h),
          Text(
            'Loading your places...',
            style: TextStyle(
              fontSize: 16.fSize,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  /// Error state
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.h,
              color: Colors.red[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'Failed to Load Places',
              style: TextStyle(
                fontSize: 18.fSize,
                fontWeight: FontWeight.w600,
                color: appTheme.blackCustom,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 14.fSize,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.colorFF0373,
                foregroundColor: appTheme.whiteCustom,
                padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.h),
                ),
              ),
              child: Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 16.fSize,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64.h,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'No Places Found',
              style: TextStyle(
                fontSize: 18.fSize,
                fontWeight: FontWeight.w600,
                color: appTheme.blackCustom,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'You haven\'t saved any places yet. Start exploring and save your favorite locations!',
              style: TextStyle(
                fontSize: 14.fSize,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                // Navigate to travel exploration to search places
                Navigator.pushNamed(context, AppRoutes.travelExplorationScreen);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.colorFF0373,
                foregroundColor: appTheme.whiteCustom,
                padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.h),
                ),
              ),
              child: Text(
                'Explore Places',
                style: TextStyle(
                  fontSize: 16.fSize,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Places list with grid layout (similar to plan list)
  Widget _buildPlacesList() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: appTheme.colorFF0373,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Saved Places',
                    style: TextStyle(
                      fontSize: 18.fSize,
                      fontWeight: FontWeight.w600,
                      color: appTheme.blackCustom,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    '${_userPlaces.length} places',
                    style: TextStyle(
                      fontSize: 14.fSize,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Places grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16.h,
                crossAxisSpacing: 16.h,
                childAspectRatio: 0.85, // Adjust for proper card proportions
              ),
              itemCount: _userPlaces.length,
              itemBuilder: (context, index) {
                final place = _userPlaces[index];
                return _buildPlaceCard(place);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Individual place card
  Widget _buildPlaceCard(Map<String, dynamic> place) {
    return GestureDetector(
      onTap: () => _navigateToAttractionDetails(place),
      child: Container(
        decoration: BoxDecoration(
          color: appTheme.whiteCustom,
          borderRadius: BorderRadius.circular(15.h),
          boxShadow: [
            BoxShadow(
              color: appTheme.blackCustom.withOpacity(0.08),
              blurRadius: 8.h,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Place image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15.h),
                    topRight: Radius.circular(15.h),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: CustomImageView(
                  imagePath: (place['image_url'] == null ||
                          place['image_url'].toString().isEmpty ||
                          place['image_url'].toString().contains('example.com'))
                      ? ImageConstant.imgImageNotFound
                      : place['image_url'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),

            // Place details
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Place name
                    Flexible(
                      child: Text(
                        place['place_name'] ?? '',
                        style: TextStyle(
                          fontSize: 13.fSize,
                          fontWeight: FontWeight.w600,
                          color: appTheme.blackCustom,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Address
                    Flexible(
                      child: Text(
                        place['address'] ?? '',
                        style: TextStyle(
                          fontSize: 11.fSize,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const Spacer(),

                    // Rating
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 12.h,
                          color: const Color(0xFFFFB800),
                        ),
                        SizedBox(width: 2.h),
                        Text(
                          double.tryParse(place['review_ratings'] ?? '0')
                                  ?.toStringAsFixed(1) ??
                              '0.0',
                          style: TextStyle(
                            fontSize: 11.fSize,
                            fontWeight: FontWeight.w600,
                            color: appTheme.blackCustom,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 10.h,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
