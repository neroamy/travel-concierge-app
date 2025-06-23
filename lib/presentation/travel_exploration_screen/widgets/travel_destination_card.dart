import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';

class TravelDestinationCard extends StatelessWidget {
  final dynamic destination;
  final double? width;
  final VoidCallback? onTap;

  const TravelDestinationCard(
      {super.key, required this.destination, this.width, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 138.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.h),
          color: appTheme.grey200,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomImageView(
              imagePath: destination.image,
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
                      destination.name ?? '',
                      style: TextStyleHelper.instance.title22RegularAndika,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          destination.price ?? '',
                          style: TextStyleHelper.instance.body12.copyWith(
                            color: appTheme.whiteCustom,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              destination.rating ?? '',
                              style: TextStyleHelper.instance.body12.copyWith(
                                color: destination.ratingColor ??
                                    appTheme.whiteCustom,
                              ),
                            ),
                            SizedBox(width: 4.h),
                            CustomImageView(
                              imagePath: destination.ratingIcon,
                              height: 16.h,
                              width: 16.h,
                            ),
                          ],
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
