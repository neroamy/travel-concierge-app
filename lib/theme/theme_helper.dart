import 'package:flutter/material.dart';

String _appTheme = "lightCode";
LightCodeColors get appTheme => ThemeHelper().themeColor();
ThemeData get theme => ThemeHelper().themeData();

/// Helper class for managing themes and colors.

// ignore_for_file: must_be_immutable
class ThemeHelper {
  // A map of custom color themes supported by the app
  final Map<String, LightCodeColors> _supportedCustomColor = {
    'lightCode': LightCodeColors(),
  };

  // A map of color schemes supported by the app
  final Map<String, ColorScheme> _supportedColorScheme = {
    'lightCode': ColorSchemes.lightCodeColorScheme,
  };

  /// Changes the app theme to [newTheme].
  void changeTheme(String newTheme) {
    _appTheme = newTheme;
  }

  /// Returns the lightCode colors for the current theme.
  LightCodeColors _getThemeColors() {
    return _supportedCustomColor[_appTheme] ?? LightCodeColors();
  }

  /// Returns the current theme data.
  ThemeData _getThemeData() {
    var colorScheme =
        _supportedColorScheme[_appTheme] ?? ColorSchemes.lightCodeColorScheme;
    return ThemeData(
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
    );
  }

  /// Returns the lightCode colors for the current theme.
  LightCodeColors themeColor() => _getThemeColors();

  /// Returns the current theme data.
  ThemeData themeData() => _getThemeData();
}

class ColorSchemes {
  static const lightCodeColorScheme = ColorScheme.light();
}

class LightCodeColors {
  // App Colors
  Color get black => const Color(0xFF1E1E1E);
  Color get white => const Color(0xFFFFFFFF);
  Color get gray400 => const Color(0xFF9CA3AF);

  // Additional Colors
  Color get blackCustom => Colors.black;
  Color get whiteCustom => Colors.white;
  Color get greyCustom => Colors.grey;
  Color get transparentCustom => Colors.transparent;
  Color get colorFFFFFF => const Color(0xFFFFFFFF);
  Color get colorFFFAFA => const Color(0xFFFAFAFA);
  Color get colorFF8181 => const Color(0xFF818181);
  Color get colorFFE9E9 => const Color(0xFFE9E9E9);
  Color get colorFFA9A9 => const Color(0xFFA9A9A9);
  Color get colorFF0373 => const Color(0xFF0373F3);
  Color get colorFFBCBC => const Color(0xFFBCBCBC);

  // Color Shades - Each shade has its own dedicated constant
  Color get grey200 => Colors.grey.shade200;
  Color get grey100 => Colors.grey.shade100;
}
