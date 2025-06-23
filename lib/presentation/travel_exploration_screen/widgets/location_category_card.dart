import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';

class LocationCategoryCard extends StatelessWidget {
  final dynamic category;
  final VoidCallback? onTap;

  const LocationCategoryCard({super.key, required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 142.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.h),
          color: appTheme.grey200,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomImageView(
              imagePath: category.image,
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
                padding: EdgeInsets.all(8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name ?? '',
                      style: TextStyleHelper.instance.title18RegularAndika,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      category.locationCount ?? '',
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
    );
  }
}
