import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// A placeholder logo widget to use when the actual logo image is not available
class PlaceholderLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const PlaceholderLogo({
    super.key,
    this.size = 100,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'NASDS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.3,
          ),
        ),
      ),
    );
  }
}
