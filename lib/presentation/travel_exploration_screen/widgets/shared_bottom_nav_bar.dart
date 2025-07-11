import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../travel_exploration_screen.dart' show BottomNavItemModel;
import 'bottom_nav_item.dart';

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
        icon: ImageConstant.imgGroup120,
        label: "Wallet",
        isSelected: selectedIndex == 1,
      ),
      BottomNavItemModel(
        icon: ImageConstant.imgGroup123,
        label: "Guide",
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
                  // Wallet: Not implemented
                } else if (index == 2) {
                  // Guide: Not implemented
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
