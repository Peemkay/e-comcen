import "package:flutter/material.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:nasds/constants/app_theme.dart";

class EnhancedCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? headerColor;
  final Color? backgroundColor;
  final double? elevation;
  final double? borderRadius;

  const EnhancedCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.headerColor,
    this.backgroundColor,
    this.elevation = 2.0,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerColor ?? AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius ?? 8.0),
                topRight: Radius.circular(borderRadius ?? 8.0),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                FaIcon(
                  icon,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          // Card content
          Container(
            padding: const EdgeInsets.all(16),
            color: backgroundColor,
            child: child,
          ),
        ],
      ),
    );
  }
}
