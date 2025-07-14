import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../core/utils/suggest_label_constants.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/floating_chat_button.dart';
import '../../widgets/safe_avatar_image.dart';
import './widgets/bottom_nav_item.dart';
import './widgets/location_category_card.dart';
import './widgets/travel_destination_card.dart';
import '../../core/services/plan_storage_service.dart';
import '../../core/services/travel_concierge_service.dart';
import '../../core/services/auth_service.dart';
import './widgets/shared_bottom_nav_bar.dart';

class TravelExplorationScreen extends StatefulWidget {
  const TravelExplorationScreen({super.key});

  @override
  State<TravelExplorationScreen> createState() =>
      _TravelExplorationScreenState();
}

class _TravelExplorationScreenState extends State<TravelExplorationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TravelConciergeService _travelService = TravelConciergeService();
  final GlobalChatService _globalChatService = GlobalChatService();
  final ProfileService _profileService = ProfileService();
  final PlanStorageService _planStorageService = PlanStorageService();

  bool _sessionInitialized = false;

  // Data availability tracking
  bool _hasMapData = false;
  bool _hasPlanData = false;

  List<PlanSummaryModel> _userPlans = [];
  bool _isLoadingPlans = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _initializeProfile();
    _checkDataAvailability();
    _checkPlanDraftAvailability();
    _fetchUserPlans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPlanDraftAvailability();
  }

  Future<void> _initializeSession() async {
    final success = await _globalChatService.ensureSessionInitialized();
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

  /// Initialize user profile
  Future<void> _initializeProfile() async {
    await _profileService.initializeProfile();
    if (mounted) {
      setState(() {
        // Trigger UI refresh to show user avatar
      });
    }
  }

  /// Check if map and plan data are available
  void _checkDataAvailability() {
    setState(() {
      _hasMapData = false; // TODO: Check actual map data availability
      // _hasPlanData sẽ được cập nhật bởi _checkPlanDraftAvailability
    });
  }

  Future<void> _checkPlanDraftAvailability() async {
    final plan = await _planStorageService.getCurrentPlan();
    final planUuid = await _planStorageService.getPlanUuid();
    setState(() {
      _hasPlanData = plan != null || (planUuid != null && planUuid.isNotEmpty);
    });
  }

  Future<void> _fetchUserPlans() async {
    setState(() {
      _isLoadingPlans = true;
    });
    final authService = AuthService();
    final user = authService.currentUser;
    if (user != null && user.id.isNotEmpty) {
      final plans = await _travelService.getUserPlans(user.id);
      setState(() {
        _userPlans = plans;
        _isLoadingPlans = false;
      });
    } else {
      setState(() {
        _userPlans = [];
        _isLoadingPlans = false;
      });
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;

    print('🚀 Navigating to AI Chat with query: "$query"');

    // Navigate to AI Chat Screen with global session
    Navigator.pushNamed(
      context,
      AppRoutes.aiChatScreen,
      arguments: {
        'initialQuery': query.trim(),
        'useGlobalSession': true,
        'conversationHistory': _globalChatService.conversationHistory,
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
          final places = await ResponseParser.parseAIResponse(result.text);
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
      body: Stack(
        children: [
          SizedBox(
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
                          colors: [
                            const Color(0xFFFFFFFF),
                            appTheme.colorFFFAFA
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderSection(),
                          _buildSearchSection(),
                          _buildSuggestionLabelGrid(),
                          _buildHorizontalLocationSection(),
                          _buildUserPlansSection(),
                          SizedBox(height: 100.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating Chat Button removed - now using Quick Actions instead
        ],
      ),
      floatingActionButton: _buildQuickActionsButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SharedBottomNavBar(selectedIndex: 0),
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
              // Left side content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Find your next trip",
                      style: TextStyleHelper.instance.title16Medium,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Nordic scenery",
                      style: TextStyleHelper.instance.headline26SemiBold,
                    ),
                  ],
                ),
              ),

              // Right side content
              Column(
                children: [
                  // User Avatar - Clickable to navigate to Profile Settings
                  GestureDetector(
                    onTap: () async {
                      // Initialize profile service if needed
                      await _profileService.initializeProfile();

                      // Navigate to Profile Settings
                      Navigator.pushNamed(
                        context,
                        AppRoutes.profileSettingsScreen,
                      );
                    },
                    child: Container(
                      width: 48.h,
                      height: 48.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: appTheme.colorFF0373.withOpacity(0.3),
                          width: 2.h,
                        ),
                      ),
                      child: UserAvatarImage(
                        imageUrl: _profileService.getSafeAvatarUrl(),
                        username: _profileService.getDisplayName(),
                        size: 44.h,
                      ),
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // AI Connection Status
                  if (_sessionInitialized)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.h),
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

                  SizedBox(height: 8.h),

                  // Test Button
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: EdgeInsets.only(left: 24.h, right: 24.h, top: 12.h), // giảm top
      child: Container(
        decoration: BoxDecoration(
          color: appTheme.whiteCustom,
          borderRadius: BorderRadius.circular(16.h),
          border: Border.all(color: appTheme.colorFFE9E9),
        ),
        child: Column(
          children: [
            // Text area
            Padding(
              padding:
                  EdgeInsets.only(left: 8.h, right: 8.h, top: 6.h, bottom: 2.h),
              child: TextField(
                controller: _searchController,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "How can I help you?",
                  hintStyle: TextStyle(
                    color: Colors.grey[600], // match suggestion label color
                    fontSize: 16, // adjust if needed for consistency
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 10.h, horizontal: 8.h), // giảm vertical
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
            // Toolbar buttons giữ nguyên
            Padding(
              padding:
                  EdgeInsets.only(left: 4.h, right: 4.h, bottom: 4.h, top: 2.h),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add_a_photo_outlined,
                        color: appTheme.colorFF0373),
                    onPressed: () async {
                      // TODO: Hiển thị bottom sheet chọn: "Chụp ảnh" hoặc "Chọn từ thư viện"
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.mic, color: appTheme.colorFF0373),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.voiceChatScreen);
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.send, color: appTheme.colorFF0373),
                    onPressed: () {
                      final query = _searchController.text.trim();
                      if (query.isNotEmpty) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.aiChatScreen,
                          arguments: {
                            'initialQuery': query,
                            'useGlobalSession': true,
                            'conversationHistory':
                                _globalChatService.conversationHistory,
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionLabelGrid() {
    final labels = SuggestLabelConstants.suggestLabels;
    final isScrollable = labels.length > 4;
    return Padding(
      padding: EdgeInsets.only(
          left: 24.h,
          right: 24.h,
          top: 0,
          bottom: 0), // giảm top/bottom để giảm space với chat box
      child: SizedBox(
        height: 2 * 64.h +
            24.h, // 2 rows, each 64.h tall + 1 mainAxisSpacing (fix clipping)
        child: GridView.builder(
          physics: isScrollable
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.h,
            childAspectRatio: 2.8,
          ),
          itemCount:
              isScrollable ? labels.length : 4, // always show 4, scroll if more
          itemBuilder: (context, index) {
            final label = labels[index];
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.aiChatScreen,
                  arguments: {
                    'initialQuery': label,
                    'useGlobalSession': true,
                    'conversationHistory':
                        _globalChatService.conversationHistory,
                    'autoSend': true,
                  },
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 6.h, vertical: 8.h), // giảm padding
                decoration: BoxDecoration(
                  color: Colors.transparent, // bỏ background xám
                  borderRadius: BorderRadius.circular(14.h),
                  border: Border.all(color: appTheme.colorFFE9E9, width: 1.2),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.22,
                      color: Colors.grey[600], // màu xám giống bottom menu
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          },
        ),
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

  Widget _buildUserPlansSection() {
    if (_isLoadingPlans) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_userPlans.isEmpty) {
      return SizedBox();
    }
    final plansToShow = _userPlans.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 24.h, right: 24.h, top: 32.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Your Plans",
                style: TextStyleHelper.instance.title18SemiBold,
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full plan list screen
                },
                child: Text('View More'),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 138.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 24.h),
            scrollDirection: Axis.horizontal,
            itemCount: plansToShow.length,
            separatorBuilder: (context, index) => SizedBox(width: 20.h),
            itemBuilder: (context, index) {
              final plan = plansToShow[index];
              return _buildPlanCard(plan);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(PlanSummaryModel plan) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.planViewScreen,
              arguments: {
                'plan_uuid': plan.planUuid,
                'plan_data': plan.rawData,
              },
            );
          },
          child: Container(
            width: 230.h,
            height: 138.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.h),
              color: appTheme.grey200,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Default image (replace with plan.imageUrl if available)
                Image.asset(
                  'assets/images/img_rectangle_462.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        appTheme.transparentCustom,
                        appTheme.blackCustom.withAlpha(179),
                      ],
                    ),
                  ),
                ),
                // Content
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.all(16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.title,
                          style: TextStyleHelper.instance.title22RegularAndika,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          plan.destination,
                          style: TextStyleHelper.instance.body12.copyWith(
                            color: appTheme.whiteCustom,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Created: ${plan.createdAt.toLocal().toString().split(' ')[0]}',
                          style: TextStyleHelper.instance.body12.copyWith(
                            color: appTheme.whiteCustom,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsButton() {
    return FloatingActionButton(
      onPressed: () {
        _showQuickActionsDialog();
      },
      backgroundColor: appTheme.colorFF0373,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.h),
      ),
      child: const Icon(
        Icons.flash_on,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  /// Show quick actions dialog
  void _showQuickActionsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: appTheme.whiteCustom,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.h),
            topRight: Radius.circular(20.h),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.h,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20.fSize,
                        fontWeight: FontWeight.w600,
                        color: appTheme.blackCustom,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Chat with AI
                    _buildQuickActionTile(
                      icon: Icons.chat_bubble_outline,
                      title: 'Chat with AI',
                      subtitle: 'Get travel recommendations',
                      color: appTheme.colorFF0373,
                      onTap: () {
                        Navigator.pop(context);
                        _onSearchSubmitted('Tell me about travel destinations');
                      },
                    ),

                    // Search Locations
                    _buildQuickActionTile(
                      icon: Icons.search,
                      title: 'Search Locations',
                      subtitle: 'Find places to visit',
                      color: const Color(0xFF0373F3),
                      isEnabled: _hasMapData,
                      onTap: _hasMapData
                          ? () {
                              Navigator.pop(context);
                              Navigator.pushNamed(
                                  context, AppRoutes.locationTargetingScreen);
                            }
                          : null,
                    ),

                    // View Plan
                    _buildQuickActionTile(
                      icon: Icons.calendar_today,
                      title: 'View Plan',
                      subtitle: 'Check your itinerary',
                      color: Colors.orange,
                      isEnabled: _hasPlanData,
                      onTap: _hasPlanData
                          ? () {
                              Navigator.pop(context);
                              Navigator.pushNamed(
                                  context, AppRoutes.planViewScreen);
                            }
                          : null,
                    ),

                    // Test Mockup
                    _buildQuickActionTile(
                      icon: Icons.science_outlined,
                      title: 'Test Mockup',
                      subtitle: 'Test UI with mock data',
                      color: Colors.green,
                      isLast: true,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                            context, AppRoutes.testMockupScreen);
                      },
                    ),

                    // Add bottom padding for safe area
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build quick action tile
  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    bool isLast = false,
    bool isEnabled = true,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: color.withOpacity(isEnabled ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(12.h),
          border: Border.all(color: color.withOpacity(isEnabled ? 0.3 : 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 48.h,
              height: 48.h,
              decoration: BoxDecoration(
                color: isEnabled ? color : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: appTheme.whiteCustom,
                size: 24.h,
              ),
            ),
            SizedBox(width: 16.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.fSize,
                      fontWeight: FontWeight.w600,
                      color:
                          isEnabled ? appTheme.blackCustom : Colors.grey[400],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14.fSize,
                      color: isEnabled ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isEnabled ? color : Colors.grey[400],
              size: 16.h,
            ),
          ],
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
