import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/floating_chat_button.dart';

class WeatherQueryScreen extends StatefulWidget {
  const WeatherQueryScreen({super.key});

  @override
  State<WeatherQueryScreen> createState() => _WeatherQueryScreenState();
}

class _WeatherQueryScreenState extends State<WeatherQueryScreen> {
  // Selected filters and day
  String _selectedCategory = "schedule";
  int _selectedDay = 1; // Default to Day 1

  // Categories for filter tabs with icons
  final List<CategoryModel> _categories = [
    CategoryModel(id: "schedule", icon: Icons.schedule, label: "Schedule"),
    CategoryModel(
        id: "restaurant", icon: Icons.restaurant, label: "Restaurant"),
    CategoryModel(id: "hotel", icon: Icons.hotel, label: "Hotel"),
  ];

  // Day data - will be populated from AI response
  List<DayModel> _days = [];

  // Itinerary data - will be populated from AI response
  List<ItineraryItemModel> _itineraryItems = [];

  // AI itinerary data
  List<ItineraryDayModel>? _aiItinerary;

  @override
  void initState() {
    super.initState();
    _initializeWithArguments();
  }

  /// Initialize with arguments from navigation
  void _initializeWithArguments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['itinerary'] != null) {
        final itinerary = args['itinerary'] as List<ItineraryDayModel>;
        _loadAIItinerary(itinerary);
      } else {
        _loadDefaultData();
      }
    });
  }

  /// Load AI itinerary data
  void _loadAIItinerary(List<ItineraryDayModel> itinerary) {
    print('📅 Loading AI itinerary with ${itinerary.length} days');

    setState(() {
      _aiItinerary = itinerary;

      // Convert AI itinerary to day models
      _days = itinerary
          .map((day) => DayModel(
                day: day.dayNumber,
                date: day.displayDate,
              ))
          .toList();

      // Set selected day to first day
      _selectedDay = _days.isNotEmpty ? _days.first.day : 1;

      // Load activities for selected day
      _loadActivitiesForSelectedDay();
    });
  }

  /// Load default demo data
  void _loadDefaultData() {
    print('📅 Loading default demo data');

    setState(() {
      _days = [
        DayModel(day: 1, date: "July 14"),
        DayModel(day: 2, date: "July 15"),
        DayModel(day: 3, date: "July 16"),
      ];

      _itineraryItems = [
        ItineraryItemModel(
          time: "12:30",
          title: "Maldives",
          subtitle: "Save the Turtles",
          weatherIcon: "📍",
          isActive: true,
        ),
        ItineraryItemModel(
          time: "14:30",
          title: "Golden beach",
          subtitle: "Surfing on the sea",
          weatherIcon: "⛅",
          isActive: false,
        ),
        ItineraryItemModel(
          time: "17:30",
          title: "Coconut grove",
          subtitle: "BBQ party by the sea",
          weatherIcon: "🌸",
          isActive: false,
        ),
        ItineraryItemModel(
          time: "21:30",
          title: "Maldives Islands",
          subtitle: "Sea blowing",
          weatherIcon: "🌧️",
          isActive: false,
        ),
      ];
    });
  }

  /// Load activities for the selected day
  void _loadActivitiesForSelectedDay() {
    if (_aiItinerary == null) return;

    final selectedDayData = _aiItinerary!.firstWhere(
      (day) => day.dayNumber == _selectedDay,
      orElse: () => _aiItinerary!.first,
    );

    print(
        '📅 Loading activities for Day $_selectedDay: ${selectedDayData.activities.length} activities');

    setState(() {
      _itineraryItems = selectedDayData.activities.map((activity) {
        // Convert time slot to time format
        final time = _convertTimeSlotToTime(activity.timeSlot);

        return ItineraryItemModel(
          time: time,
          title: activity.title,
          subtitle: activity.description,
          weatherIcon: activity.weatherIcon,
          isActive: activity.isActive,
        );
      }).toList();
    });
  }

  /// Convert time slot to time format
  String _convertTimeSlotToTime(String timeSlot) {
    switch (timeSlot.toLowerCase()) {
      case 'morning':
        return '09:00';
      case 'afternoon':
        return '14:00';
      case 'evening':
        return '18:00';
      case 'late afternoon':
        return '16:00';
      default:
        return '12:00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteCustom,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildCategoryTabs(),
                _buildDaySelector(),
                Expanded(
                  child: _buildItineraryContent(),
                ),
              ],
            ),
          ),
          // Floating Chat Button
          const FloatingChatButton(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// Header section with back button, title and action icon
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
            _aiItinerary != null ? "AI Itinerary" : "Itinerary Form",
            style: TextStyle(
              fontSize: 18.fSize,
              fontWeight: FontWeight.w600,
              color: appTheme.blackCustom,
              fontFamily: 'Poppins',
            ),
          ),
          // Action icon (appears to be a calendar or export icon)
          GestureDetector(
            onTap: _onActionTap,
            child: Icon(
              Icons.calendar_month_outlined,
              size: 24.h,
              color: appTheme.blackCustom,
            ),
          ),
        ],
      ),
    );
  }

  /// Category filter tabs exactly matching Figma design
  Widget _buildCategoryTabs() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.h),
      child: Row(
        children: List.generate(
          _categories.length,
          (index) => _buildCategoryTab(_categories[index]),
        ),
      ),
    );
  }

  /// Individual category tab
  Widget _buildCategoryTab(CategoryModel category) {
    final bool isSelected = _selectedCategory == category.id;

    return GestureDetector(
      onTap: () => _onCategorySelected(category.id),
      child: Container(
        margin: EdgeInsets.only(right: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0373F3) : Colors.transparent,
          borderRadius: BorderRadius.circular(20.h),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF0373F3) : const Color(0xFFE5E5E5),
            width: 1.h,
          ),
        ),
        child: Icon(
          category.icon,
          size: 20.h,
          color: isSelected ? appTheme.whiteCustom : const Color(0xFF9E9E9E),
        ),
      ),
    );
  }

  /// Day selector tabs matching Figma design
  Widget _buildDaySelector() {
    if (_days.isEmpty) {
      return SizedBox(height: 24.h);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 24.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          _days.length,
          (index) => _buildDayTab(_days[index]),
        ),
      ),
    );
  }

  /// Individual day tab
  Widget _buildDayTab(DayModel day) {
    final bool isSelected = _selectedDay == day.day;

    return GestureDetector(
      onTap: () => _onDaySelected(day.day),
      child: Column(
        children: [
          Text(
            "Day ${day.day}",
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.w600,
              color:
                  isSelected ? appTheme.blackCustom : const Color(0xFF9E9E9E),
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            day.date,
            style: TextStyle(
              fontSize: 12.fSize,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF9E9E9E),
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8.h),
          // Underline indicator for selected day
          if (isSelected)
            Container(
              width: 40.h,
              height: 3.h,
              decoration: BoxDecoration(
                color: const Color(0xFF0373F3),
                borderRadius: BorderRadius.circular(2.h),
              ),
            ),
        ],
      ),
    );
  }

  /// Itinerary content with timeline - matching Figma exactly
  Widget _buildItineraryContent() {
    if (_itineraryItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64.h,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'No activities for this day',
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

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.h),
      child: Column(
        children: List.generate(
          _itineraryItems.length,
          (index) => _buildItineraryItem(
            _itineraryItems[index],
            isLast: index == _itineraryItems.length - 1,
          ),
        ),
      ),
    );
  }

  /// Individual itinerary item with exact Figma styling
  Widget _buildItineraryItem(ItineraryItemModel item, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 32.h),
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
                  fontSize: 16.fSize,
                  fontWeight: FontWeight.w600,
                  color: appTheme.blackCustom,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            SizedBox(width: 16.h),
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 12.h,
                  height: 12.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.isActive
                        ? const Color(0xFF0373F3)
                        : const Color(0xFFE5E5E5),
                  ),
                  child: item.isActive
                      ? Icon(
                          Icons.location_on,
                          color: appTheme.whiteCustom,
                          size: 8.h,
                        )
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2.h,
                    height: 60.h,
                    color: const Color(0xFFE5E5E5),
                  ),
              ],
            ),
            SizedBox(width: 16.h),
            // Content section
            Expanded(
              child: GestureDetector(
                onTap: () => _onItineraryItemTap(item),
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
                              fontSize: 14.fSize,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF9E9E9E),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Weather/Status icon
                    Container(
                      width: 40.h,
                      height: 40.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF5F5F5),
                      ),
                      child: Center(
                        child: Text(
                          item.weatherIcon,
                          style: TextStyle(fontSize: 18.fSize),
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

  /// Bottom navigation bar with Guide tab active
  Widget _buildBottomNavBar() {
    final List<BottomNavItemModel> navItems = [
      BottomNavItemModel(
        icon: Icons.home,
        label: "Home",
        isSelected: false,
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
        isSelected: true, // Guide tab is active in this screen
        onTap: () {}, // Current screen
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
              fontSize: 12.fSize,
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

  // Event handlers
  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategory = categoryId;
    });
    // TODO: Filter itinerary items based on category
  }

  void _onDaySelected(int day) {
    setState(() {
      _selectedDay = day;
    });
    // Load activities for selected day
    _loadActivitiesForSelectedDay();
  }

  void _onActionTap() {
    // TODO: Export or share itinerary
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_aiItinerary != null
            ? 'Export AI itinerary feature coming soon'
            : 'Export itinerary feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onItineraryItemTap(ItineraryItemModel item) {
    // TODO: Show detailed information about this activity
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.title} details'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushNamed(context, AppRoutes.travelExplorationScreen);
  }
}

// Data models
class DayModel {
  final int day;
  final String date;

  const DayModel({
    required this.day,
    required this.date,
  });
}

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

class CategoryModel {
  final String id;
  final IconData icon;
  final String label;

  const CategoryModel({
    required this.id,
    required this.icon,
    required this.label,
  });
}
