import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/app_export.dart';

class SafeAvatarImage extends StatelessWidget {
  final String? imageUrl;
  final double? size;
  final double? radius;
  final Widget? fallbackWidget;
  final BoxFit? fit;

  const SafeAvatarImage({
    super.key,
    this.imageUrl,
    this.size,
    this.radius,
    this.fallbackWidget,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = size ?? 40.0;
    final avatarRadius = radius ?? avatarSize / 2;

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(avatarRadius),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(avatarRadius),
        child: _buildAvatarContent(avatarSize),
      ),
    );
  }

  Widget _buildAvatarContent(double size) {
    // Check if imageUrl is valid
    if (imageUrl == null ||
        imageUrl!.isEmpty ||
        imageUrl == 'null' ||
        !_isValidUrl(imageUrl!)) {
      return _buildDefaultAvatar(size);
    }

    // Try to load network image with fallback
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: fit ?? BoxFit.cover,
      width: size,
      height: size,
      placeholder: (context, url) => _buildLoadingIndicator(size),
      errorWidget: (context, url, error) {
        print('❌ Failed to load avatar: $url - Error: $error');
        return _buildDefaultAvatar(size);
      },
      // Add timeout for slow connections
      cacheKey: imageUrl,
      memCacheWidth: size.toInt() * 2, // Optimize memory usage
      memCacheHeight: size.toInt() * 2,
    );
  }

  Widget _buildDefaultAvatar(double size) {
    if (fallbackWidget != null) {
      return fallbackWidget!;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            appTheme.colorFF0373.withOpacity(0.8),
            appTheme.colorFF0373,
          ],
        ),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLoadingIndicator(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[100],
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              appTheme.colorFF0373.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  bool _isValidUrl(String url) {
    // Basic URL validation
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.hasAuthority &&
          !url.contains('example.com'); // Exclude example URLs
    } catch (e) {
      return false;
    }
  }
}

/// Specialized avatar for user profiles
class UserAvatarImage extends StatelessWidget {
  final String? imageUrl;
  final String? username;
  final double? size;

  const UserAvatarImage({
    super.key,
    this.imageUrl,
    this.username,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = size ?? 40.0;

    return SafeAvatarImage(
      imageUrl: imageUrl,
      size: avatarSize,
      fallbackWidget: _buildUserInitials(avatarSize),
    );
  }

  Widget _buildUserInitials(double size) {
    String initials = 'U';

    if (username != null && username!.isNotEmpty) {
      final words = username!.trim().split(' ');
      if (words.isNotEmpty) {
        if (words.length == 1) {
          // Single word - take first 2 characters
          initials = words[0].length >= 2
              ? words[0].substring(0, 2).toUpperCase()
              : words[0].substring(0, 1).toUpperCase();
        } else {
          // Multiple words - take first letter of first 2 words
          initials = (words[0].isNotEmpty ? words[0][0] : '') +
              (words[1].isNotEmpty ? words[1][0] : '');
          initials = initials.toUpperCase();
        }
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            appTheme.colorFF0373.withOpacity(0.8),
            appTheme.colorFF0373,
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'PoppinsSemiBold',
          ),
        ),
      ),
    );
  }
}
