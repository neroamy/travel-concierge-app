import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),
                    _buildGreetingSection(),
                    SizedBox(height: 32.h),
                    _buildFeaturedDestination(),
                    SizedBox(height: 32.h),
                    _buildScheduleSection(),
                    SizedBox(height: 100.h),
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

  Widget _buildGreetingSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 4.h),
            const Text(
              'Hello, Alanlove',
              style: TextStyle(
                fontSize: 24,
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Container(
          width: 48.h,
          height: 48.h,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF007AFF),
          ),
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 24.h,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedDestination() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Maldives Island',
          style: TextStyle(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          height: 200.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.h),
            image: const DecorationImage(
              image: AssetImage('assets/images/img_rectangle_465.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Dark overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.h),
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
              // Content
              Padding(
                padding: EdgeInsets.all(16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Beach Reef label
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 16.h,
                        ),
                        SizedBox(width: 4.h),
                        const Text(
                          'Beach Reef',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Bottom row with profiles and button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Profile pictures
                        Row(
                          children: [
                            _buildProfileCircle(const Color(0xFF4CAF50)),
                            SizedBox(width: 8.h),
                            _buildProfileCircle(const Color(0xFFFF9800)),
                            SizedBox(width: 8.h),
                            Container(
                              width: 32.h,
                              height: 32.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16.h,
                              ),
                            ),
                          ],
                        ),
                        // Maldives button
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.h,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF),
                            borderRadius: BorderRadius.circular(20.h),
                          ),
                          child: const Text(
                            'Maldives',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCircle(Color color) {
    return Container(
      width: 32.h,
      height: 32.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        color: color,
      ),
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: 16.h,
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule',
          style: TextStyle(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 24.h),
        _buildScheduleItem(
          time: '12:30',
          title: 'Maldives',
          subtitle: 'Save the Turtles',
          icon: '🐢',
          isActive: true,
          isFirst: true,
        ),
        _buildScheduleItem(
          time: '14:30',
          title: 'Golden beach',
          subtitle: 'Surfing on the sea',
          icon: '🏄',
          isActive: false,
        ),
        _buildScheduleItem(
          time: '17:30',
          title: 'Coconut grove',
          subtitle: 'BBQ party by the sea',
          icon: '🌴',
          isActive: false,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildScheduleItem({
    required String time,
    required String title,
    required String subtitle,
    required String icon,
    required bool isActive,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          SizedBox(
            width: 48.h,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 16,
                color: isActive ? const Color(0xFF007AFF) : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 16.h),
          // Timeline
          Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 24.h,
                  color: Colors.grey[300],
                ),
              Container(
                width: 12.h,
                height: 12.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? const Color(0xFF007AFF) : Colors.grey[300],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey[300],
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.h),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 32.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    List<BottomNavItemModel> items = [
      BottomNavItemModel(
        icon: Icons.home_filled,
        label: "Home",
        isSelected: true,
      ),
      BottomNavItemModel(
        icon: Icons.account_balance_wallet_outlined,
        label: "Wallet",
        isSelected: false,
      ),
      BottomNavItemModel(
        icon: Icons.book_outlined,
        label: "Guide",
        isSelected: false,
      ),
      BottomNavItemModel(
        icon: Icons.bar_chart,
        label: "Chart",
        isSelected: false,
      ),
    ];

    return Container(
      height: 88.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.h),
          topRight: Radius.circular(24.h),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.h,
            offset: Offset(0, -5.h),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          items.length,
          (index) => _buildNavItem(items[index]),
        ),
      ),
    );
  }

  Widget _buildNavItem(BottomNavItemModel item) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          item.icon,
          size: 24.h,
          color: item.isSelected == true
              ? const Color(0xFF007AFF)
              : Colors.grey[400],
        ),
        SizedBox(height: 4.h),
        Text(
          item.label ?? '',
          style: TextStyle(
            fontSize: 12,
            color: item.isSelected == true
                ? const Color(0xFF007AFF)
                : Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class BottomNavItemModel {
  final IconData? icon;
  final String? label;
  final bool? isSelected;

  BottomNavItemModel({
    this.icon,
    this.label,
    this.isSelected,
  });
}
