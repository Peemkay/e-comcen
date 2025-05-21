import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Utility class for handling the Nigerian Army Signals logo
class LogoUtil {
  /// Returns the Nigerian Army Signals logo as an Image widget
  ///
  /// [width] and [height] are optional parameters to specify the size of the logo
  /// If not provided, the logo will be rendered at its natural size
  static Widget getLogo({double? width, double? height}) {
    return Image.asset(
      AppConstants.logoPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }

  /// Returns the simplified Nigerian Army Signals icon as an Image widget
  ///
  /// [width] and [height] are optional parameters to specify the size of the icon
  /// If not provided, the icon will be rendered at its natural size
  static Widget getIcon({double? width, double? height}) {
    return Image.asset(
      AppConstants.iconPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }

  /// Returns the Nigerian Army Signals logo with a specified size
  ///
  /// [size] is the width and height of the logo
  static Widget getSquareLogo(double size) {
    return getLogo(width: size, height: size);
  }

  /// Returns the Nigerian Army Signals icon with a specified size
  ///
  /// [size] is the width and height of the icon
  static Widget getSquareIcon(double size) {
    return getIcon(width: size, height: size);
  }

  /// Returns the Nigerian Army Signals logo as a circular avatar
  ///
  /// [radius] is the radius of the circular avatar
  static Widget getCircularLogo(double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.transparent,
      child: getSquareLogo(radius * 2),
    );
  }

  /// Returns the Nigerian Army Signals icon as a circular avatar
  ///
  /// [radius] is the radius of the circular avatar
  static Widget getCircularIcon(double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.transparent,
      child: getSquareIcon(radius * 2),
    );
  }
}
