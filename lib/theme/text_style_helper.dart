import 'package:flutter/material.dart';
import '../core/app_export.dart';

/// A helper class for managing text styles in the application
class TextStyleHelper {
  static TextStyleHelper? _instance;

  TextStyleHelper._();

  static TextStyleHelper get instance {
    _instance ??= TextStyleHelper._();
    return _instance!;
  }

  // Headline Styles
  // Medium-large text styles for section headers

  TextStyle get headline26SemiBold => TextStyle(
    fontSize: 26.fSize,
    fontWeight: FontWeight.w600,
    color: appTheme.blackCustom,
  );

  // Title Styles
  // Medium text styles for titles and subtitles

  TextStyle get title22RegularAndika => TextStyle(
    fontSize: 22.fSize,
    fontWeight: FontWeight.w400,
    fontFamily: 'Andika',
    color: appTheme.whiteCustom,
  );

  TextStyle get title20RegularRoboto => TextStyle(
    fontSize: 20.fSize,
    fontWeight: FontWeight.w400,
    fontFamily: 'Roboto',
  );

  TextStyle get title18SemiBold => TextStyle(
    fontSize: 18.fSize,
    fontWeight: FontWeight.w600,
    color: appTheme.blackCustom,
  );

  TextStyle get title18RegularAndika => TextStyle(
    fontSize: 18.fSize,
    fontWeight: FontWeight.w400,
    fontFamily: 'Andika',
    color: appTheme.whiteCustom,
  );

  TextStyle get title16Medium => TextStyle(
    fontSize: 16.fSize,
    fontWeight: FontWeight.w500,
    color: appTheme.colorFF8181,
  );

  TextStyle get title16 =>
      TextStyle(fontSize: 16.fSize, color: appTheme.colorFFA9A9);

  // Body Styles
  // Standard text styles for body content

  TextStyle get body14 => TextStyle(fontSize: 14.fSize);

  TextStyle get body12 => TextStyle(fontSize: 12.fSize);
}
