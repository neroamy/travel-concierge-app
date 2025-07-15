import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import 'bottom_nav_item.dart';

class BottomNavItemModel {
  final dynamic icon; // Accepts String (asset path) or IconData
  final String? label;
  final bool? isSelected;
  BottomNavItemModel({this.icon, this.label, this.isSelected});
}

class SharedBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onTap;
  const SharedBottomNavBar({Key? key, this.selectedIndex = 0, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List items = [
      BottomNavItemModel(
        icon: ImageConstant.imgGroup125,
        label: "Home",
        isSelected: selectedIndex == 0,
      ),
      BottomNavItemModel(
        icon: Icons.list_alt, // Use a list icon for Plan List
        label: "Plan List",
        isSelected: selectedIndex == 1,
      ),
      BottomNavItemModel(
        icon: Icons.place, // Change to place icon for Place List
        label: "Place List",
        isSelected: selectedIndex == 2,
      ),
      BottomNavItemModel(
        icon: Icons.settings,
        label: "Setting",
        isSelected: selectedIndex == 3,
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
          (index) => GestureDetector(
            onTap: () {
              if (onTap != null) {
                onTap!(index);
              } else {
                if (index == 0) {
                  Navigator.pushNamed(
                      context, AppRoutes.travelExplorationScreen);
                } else if (index == 1) {
                  Navigator.pushNamed(context, AppRoutes.planListScreen);
                } else if (index == 2) {
                  Navigator.pushNamed(context,
                      AppRoutes.placeListScreen); // Navigate to Place List
                } else if (index == 3) {
                  Navigator.pushNamed(context, AppRoutes.profileSettingsScreen);
                }
              }
            },
            child: BottomNavItem(item: items[index]),
          ),
        ),
      ),
    );
  }
}
