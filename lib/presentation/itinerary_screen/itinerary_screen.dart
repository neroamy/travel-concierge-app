import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  // Mock data according to requirements
  final String _userName = "Alanlove";
  final String _greetingTime = "Good morning";
  final String _destinationName = "Maldives Island";
  final String _destinationLocation = "Beach Reef";

  // Mock schedule data from AI agent
  final List<ItineraryItemModel> _scheduleItems = [
    ItineraryItemModel(
      time: "12:30",
      title: "Maldives",
      subtitle: "Save the Turtles",
      weatherIcon: "🌤️",
      isActive: true,
    ),
    ItineraryItemModel(
      time: "14:30",
      title: "Golden beach",
      subtitle: "Surfing on the sea",
      weatherIcon: "⛈️",
      isActive: false,
    ),
    ItineraryItemModel(
      time: "17:30",
      title: "Coconut grove",
      subtitle: "BBQ party by the sea",
      weatherIcon: "🌙",
      isActive: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteCustom,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    _buildFeaturedDestination(),
                    _buildScheduleSection(),
                    SizedBox(height: 100.h), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// Header section with greeting and user avatar - exactly matching Figma design
  Widget _buildHeaderSection() {
    return Padding(
      padding: EdgeInsets.only(
        left: 21.h,
        right: 21.h,
        top: 54.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greetingTime,
                style: TextStyle(
                  fontSize: 18.fSize,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6C6C6C),
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                "Hello,$_userName",
                style: TextStyle(
                  fontSize: 26.fSize,
                  fontWeight: FontWeight.w600,
                  color: appTheme.blackCustom,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          // User avatar - circular with mock profile image
          Container(
            width: 48.h,
            height: 48.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: AssetImage('assets/images/img_rectangle_465.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Featured destination card exactly matching Figma design
  Widget _buildFeaturedDestination() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 21.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32.h),
          Text(
            _destinationName,
            style: TextStyle(
              fontSize: 18.fSize,
              fontWeight: FontWeight.w500,
              color: appTheme.blackCustom,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            height: 176.h,
            width: 351.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11.h),
              image: const DecorationImage(
                image: AssetImage('assets/images/img_rectangle_465.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Dark overlay for better text visibility
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11.h),
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
                // Content positioning exactly as in Figma
                Positioned(
                  left: 16.h,
                  top: 16.h,
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white.withOpacity(0.7),
                        size: 14.h,
                      ),
                      SizedBox(width: 4.h),
                      Text(
                        _destinationLocation,
                        style: TextStyle(
                          fontSize: 12.fSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.7),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom content
                Positioned(
                  bottom: 25.h,
                  left: 16.h,
                  right: 16.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Multiple user avatars as shown in Figma
                      Row(
                        children: [
                          _buildUserAvatar(
                              'assets/images/img_rectangle_463.png'),
                          SizedBox(width: 8.h),
                          _buildUserAvatar(
                              'assets/images/img_rectangle_464.png'),
                          SizedBox(width: 8.h),
                          _buildUserAvatar(
                              'assets/images/img_rectangle_462.png'),
                        ],
                      ),
                      // Maldives button with exact styling
                      GestureDetector(
                        onTap: _navigateToWeatherQuery,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.h,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0373F3),
                            borderRadius: BorderRadius.circular(10.h),
                          ),
                          child: Text(
                            'Maldives',
                            style: TextStyle(
                              fontSize: 14.fSize,
                              fontWeight: FontWeight.w500,
                              color: appTheme.whiteCustom,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build user avatar circles for destination card
  Widget _buildUserAvatar(String imagePath) {
    return Container(
      width: 30.h,
      height: 30.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Schedule section with timeline design matching Figma exactly
  Widget _buildScheduleSection() {
    return Container(
      margin: EdgeInsets.only(top: 32.h),
      padding: EdgeInsets.only(top: 36.h, bottom: 24.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Schedule header
          Padding(
            padding: EdgeInsets.only(left: 22.h, bottom: 32.h),
            child: Text(
              'Schedule',
              style: TextStyle(
                fontSize: 18.fSize,
                fontWeight: FontWeight.w500,
                color: appTheme.blackCustom,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          // Timeline items
          ...List.generate(
            _scheduleItems.length,
            (index) => _buildScheduleItem(
              _scheduleItems[index],
              isFirst: index == 0,
              isLast: index == _scheduleItems.length - 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Individual schedule item with exact Figma spacing and design
  Widget _buildScheduleItem(
    ItineraryItemModel item, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: 22.h,
        right: 22.h,
        bottom: isLast ? 0 : 32.h,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time display
            SizedBox(
              width: 55.h,
              child: Text(
                item.time,
                style: TextStyle(
                  fontSize: 18.fSize,
                  fontWeight: FontWeight.w400,
                  color: appTheme.blackCustom,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            SizedBox(width: 16.h),
            // Timeline indicator
            Column(
              children: [
                if (!isFirst)
                  Container(
                    width: 2.h,
                    height: 24.h,
                    color: const Color(0xFFC4C4C4),
                  ),
                Container(
                  width: 26.h,
                  height: 26.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.isActive
                        ? const Color(0xFF0373F3)
                        : Colors.transparent,
                    border: Border.all(
                      color: item.isActive
                          ? const Color(0xFF0373F3)
                          : const Color(0xFFC4C4C4),
                      width: 2.h,
                    ),
                  ),
                  child: item.isActive
                      ? Icon(
                          Icons.location_on,
                          color: appTheme.whiteCustom,
                          size: 14.h,
                        )
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2.h,
                    height: item.isActive ? 26.h : 54.h,
                    color: item.isActive
                        ? const Color(0xFF0373F3)
                        : const Color(0xFFC4C4C4),
                  ),
              ],
            ),
            SizedBox(width: 16.h),
            // Content section
            Expanded(
              child: GestureDetector(
                onTap: () => _onActivityTap(item),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 16.fSize,
                              fontWeight: FontWeight.w600,
                              color: appTheme.blackCustom,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: 16.fSize,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFFB1B1B1),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Weather icon
                    Container(
                      width: 43.h,
                      height: 43.h,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE2E2E2),
                      ),
                      child: Center(
                        child: Text(
                          item.weatherIcon,
                          style: TextStyle(fontSize: 20.fSize),
                        ),
                      ),
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

  /// Bottom navigation bar exactly matching Figma design
  Widget _buildBottomNavBar() {
    final List<BottomNavItemModel> navItems = [
      BottomNavItemModel(
        icon: Icons.home,
        label: "Home",
        isSelected: true,
        onTap: _navigateToHome,
      ),
      BottomNavItemModel(
        icon: Icons.account_balance_wallet_outlined,
        label: "Wallet",
        isSelected: false,
        onTap: () {}, // Not implemented yet
      ),
      BottomNavItemModel(
        icon: Icons.book_outlined,
        label: "Guide",
        isSelected: false,
        onTap: () {}, // Not implemented yet
      ),
      BottomNavItemModel(
        icon: Icons.bar_chart,
        label: "Chart",
        isSelected: false,
        onTap: () {}, // Not implemented yet
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.h,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          navItems.length,
          (index) => _buildNavItem(navItems[index]),
        ),
      ),
    );
  }

  /// Individual navigation item
  Widget _buildNavItem(BottomNavItemModel item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item.icon,
            size: 24.h,
            color: item.isSelected
                ? const Color(0xFF0373F3)
                : const Color(0xFFBCBCBC),
          ),
          SizedBox(height: 4.h),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w400,
              color: item.isSelected
                  ? const Color(0xFF0373F3)
                  : const Color(0xFFBCBCBC),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // Navigation and interaction methods
  void _navigateToHome() {
    Navigator.pushNamed(context, AppRoutes.travelExplorationScreen);
  }

  void _navigateToWeatherQuery() {
    // Navigate to weather query screen (node-id=10-3272)
    Navigator.pushNamed(context, AppRoutes.weatherQueryScreen);
  }

  void _onActivityTap(ItineraryItemModel item) {
    // TODO: Call API to get more details about this activity
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Activity Details: ${item.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Data models for the screen
class ItineraryItemModel {
  final String time;
  final String title;
  final String subtitle;
  final String weatherIcon;
  final bool isActive;

  const ItineraryItemModel({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.weatherIcon,
    required this.isActive,
  });
}

class BottomNavItemModel {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const BottomNavItemModel({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
}
