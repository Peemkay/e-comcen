import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

/// A consistent section header widget for the application
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;
  final double fontSize;
  final bool showDivider;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.textColor,
    this.fontSize = 18.0,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: iconColor ?? AppTheme.primaryColor,
                    size: fontSize + 4,
                  ),
                  const SizedBox(width: 8.0),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: textColor ?? AppTheme.primaryColor,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16.0,
                    color: iconColor ?? AppTheme.primaryColor,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            color: AppTheme.primaryColor.withAlpha(51), // 0.2 * 255 = 51
            thickness: 1.0,
          ),
      ],
    );
  }
}
