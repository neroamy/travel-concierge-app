import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

/// Widget for displaying location pin on the map
class MapPin extends StatelessWidget {
  final double top;
  final double left;
  final VoidCallback? onTap;

  const MapPin({
    super.key,
    required this.top,
    required this.left,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26.h,
          height: 26.h,
          decoration: BoxDecoration(
            color: appTheme.colorFF0373,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: appTheme.colorFF0373.withOpacity(0.3),
                blurRadius: 8.h,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Icon(
            Icons.location_on,
            color: appTheme.whiteCustom,
            size: 16.h,
          ),
        ),
      ),
    );
  }
}
