import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';

class BottomNavItem extends StatelessWidget {
  final dynamic item;

  const BottomNavItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 20.h),
        CustomImageView(imagePath: item.icon, height: 28.h, width: 28.h),
        SizedBox(height: 4.h),
        Text(
          item.label ?? '',
          style: TextStyleHelper.instance.body14.copyWith(
            color: (item.isSelected ?? false)
                ? const Color(0xFF0373F3)
                : appTheme.colorFFBCBC,
          ),
        ),
      ],
    );
  }
}
