import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// A responsive card widget that adapts its size and layout based on screen size.
///
/// This widget provides a consistent card layout for displaying information,
/// with responsive padding and constraints to prevent overflow issues.
class ResponsiveCard extends StatelessWidget {
  /// The title of the card
  final String? title;
  
  /// The content of the card
  final Widget content;
  
  /// Optional icon to display next to the title
  final IconData? icon;
  
  /// Optional color for the icon and title
  final Color? color;
  
  /// Optional callback when the card is tapped
  final VoidCallback? onTap;
  
  /// Optional elevation of the card
  final double elevation;
  
  /// Optional padding inside the card
  final EdgeInsetsGeometry? padding;
  
  /// Optional margin around the card
  final EdgeInsetsGeometry? margin;
  
  /// Optional border radius of the card
  final BorderRadius? borderRadius;
  
  /// Optional width of the card (if null, will use responsive width)
  final double? width;
  
  /// Optional height of the card
  final double? height;
  
  /// Optional background color of the card
  final Color? backgroundColor;
  
  /// Optional border of the card
  final Border? border;

  /// Creates a responsive card.
  const ResponsiveCard({
    Key? key,
    this.title,
    required this.content,
    this.icon,
    this.color,
    this.onTap,
    this.elevation = 2.0,
    this.padding,
    this.margin,
    this.borderRadius,
    this.width,
    this.height,
    this.backgroundColor,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate responsive values
    final responsivePadding = padding ?? 
        AppTheme.getResponsivePadding(context, factor: 1.0);
    final responsiveMargin = margin ?? 
        AppTheme.getResponsivePadding(context, factor: 0.5);
    final responsiveBorderRadius = borderRadius ?? 
        BorderRadius.circular(12.0);
    final responsiveWidth = width ?? 
        AppTheme.getResponsiveCardWidth(context);
    
    // Create the card content
    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title section if title is provided
        if (title != null) ...[
          Row(
            children: [
              // Icon if provided
              if (icon != null) ...[
                Icon(
                  icon,
                  color: color ?? AppTheme.primaryColor,
                  size: AppTheme.getResponsiveIconSize(context),
                ),
                SizedBox(width: AppTheme.getResponsiveSpacing(context, factor: 0.5)),
              ],
              // Title text
              Expanded(
                child: Text(
                  title!,
                  style: TextStyle(
                    fontSize: AppTheme.getResponsiveFontSize(context, baseFontSize: 16),
                    fontWeight: FontWeight.bold,
                    color: color ?? AppTheme.primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.getResponsiveSpacing(context, factor: 0.75)),
        ],
        // Main content
        content,
      ],
    );
    
    // Wrap in a container with responsive constraints
    cardContent = Container(
      width: responsiveWidth,
      height: height,
      padding: responsivePadding,
      child: cardContent,
    );
    
    // Create the card with responsive properties
    return Card(
      elevation: elevation,
      margin: responsiveMargin,
      shape: RoundedRectangleBorder(
        borderRadius: responsiveBorderRadius,
        side: border != null 
            ? BorderSide(color: border!.top.color, width: border!.top.width) 
            : BorderSide.none,
      ),
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: responsiveBorderRadius,
        child: cardContent,
      ),
    );
  }
}

/// A responsive summary card for displaying statistics or summary information.
class ResponsiveSummaryCard extends StatelessWidget {
  /// The title of the summary card
  final String title;
  
  /// The value to display (e.g., count, amount)
  final String value;
  
  /// Optional icon to display
  final IconData? icon;
  
  /// Optional color for the icon and value
  final Color? color;
  
  /// Optional callback when the card is tapped
  final VoidCallback? onTap;
  
  /// Optional subtitle or description
  final String? subtitle;

  /// Creates a responsive summary card.
  const ResponsiveSummaryCard({
    Key? key,
    required this.title,
    required this.value,
    this.icon,
    this.color,
    this.onTap,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine if we're on a small screen
    final isSmallScreen = AppTheme.isMobileDevice(context);
    
    // Create the content based on screen size
    Widget content;
    
    if (isSmallScreen) {
      // Horizontal layout for small screens
      content = Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color ?? AppTheme.primaryColor,
              size: AppTheme.getResponsiveIconSize(context, baseSize: 32),
            ),
            SizedBox(width: AppTheme.getResponsiveSpacing(context, factor: 1.0)),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTheme.getResponsiveFontSize(context, baseFontSize: 14),
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: AppTheme.getResponsiveSpacing(context, factor: 0.25)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppTheme.getResponsiveFontSize(context, baseFontSize: 20),
                    fontWeight: FontWeight.bold,
                    color: color ?? AppTheme.primaryColor,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: AppTheme.getResponsiveSpacing(context, factor: 0.25)),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: AppTheme.getResponsiveFontSize(context, baseFontSize: 12),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    } else {
      // Vertical layout for larger screens
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color ?? AppTheme.primaryColor,
              size: AppTheme.getResponsiveIconSize(context, baseSize: 40),
            ),
            SizedBox(height: AppTheme.getResponsiveSpacing(context, factor: 0.75)),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: AppTheme.getResponsiveFontSize(context, baseFontSize: 24),
              fontWeight: FontWeight.bold,
              color: color ?? AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: AppTheme.getResponsiveSpacing(context, factor: 0.5)),
          Text(
            title,
            style: TextStyle(
              fontSize: AppTheme.getResponsiveFontSize(context, baseFontSize: 14),
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            SizedBox(height: AppTheme.getResponsiveSpacing(context, factor: 0.5)),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: AppTheme.getResponsiveFontSize(context, baseFontSize: 12),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
    }
    
    // Create the card with the responsive content
    return ResponsiveCard(
      content: content,
      onTap: onTap,
      backgroundColor: Colors.white,
      elevation: 2.0,
      padding: AppTheme.getResponsivePadding(context, factor: 1.0),
    );
  }
}
