import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// A responsive wrapper widget that adapts its layout based on screen size.
/// 
/// This widget provides different layouts for mobile, tablet, and desktop screens.
class ResponsiveWrapper extends StatelessWidget {
  /// The content to display on mobile screens
  final Widget mobile;
  
  /// The content to display on tablet screens (optional)
  final Widget? tablet;
  
  /// The content to display on desktop screens (optional)
  final Widget? desktop;
  
  /// Creates a responsive wrapper.
  /// 
  /// The [mobile] parameter is required and will be used as a fallback
  /// if [tablet] or [desktop] are not provided.
  const ResponsiveWrapper({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to get the constraints of the parent widget
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get the current screen width
        final width = constraints.maxWidth;
        
        // Desktop layout (width >= 1200)
        if (width >= 1200) {
          return desktop ?? tablet ?? mobile;
        }
        
        // Tablet layout (600 <= width < 1200)
        if (width >= 600) {
          return tablet ?? mobile;
        }
        
        // Mobile layout (width < 600)
        return mobile;
      },
    );
  }
}

/// A responsive grid view that adapts its column count based on screen size.
class ResponsiveGridView extends StatelessWidget {
  /// The list of items to display in the grid
  final List<Widget> children;
  
  /// The spacing between items
  final double spacing;
  
  /// Optional fixed column count (if not provided, will be calculated based on screen width)
  final int? columnCount;
  
  /// Optional aspect ratio for grid items
  final double aspectRatio;
  
  /// Optional padding around the grid
  final EdgeInsetsGeometry? padding;

  /// Creates a responsive grid view.
  const ResponsiveGridView({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.columnCount,
    this.aspectRatio = 1.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the number of columns based on screen width
        final count = columnCount ?? AppTheme.getResponsiveGridCount(context);
        
        return GridView.builder(
          padding: padding ?? AppTheme.getResponsivePadding(context),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// A responsive container that adapts its width based on screen size.
class ResponsiveContainer extends StatelessWidget {
  /// The content to display inside the container
  final Widget child;
  
  /// The maximum width of the container
  final double? maxWidth;
  
  /// The minimum width of the container
  final double? minWidth;
  
  /// The width factor (percentage of screen width)
  final double widthFactor;
  
  /// Optional padding inside the container
  final EdgeInsetsGeometry? padding;
  
  /// Optional margin around the container
  final EdgeInsetsGeometry? margin;
  
  /// Optional decoration for the container
  final BoxDecoration? decoration;

  /// Creates a responsive container.
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.minWidth,
    this.widthFactor = 0.9, // 90% of screen width by default
    this.padding,
    this.margin,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the width based on screen size
        final screenWidth = MediaQuery.of(context).size.width;
        double width = screenWidth * widthFactor;
        
        // Apply min/max constraints
        if (maxWidth != null && width > maxWidth!) {
          width = maxWidth!;
        }
        if (minWidth != null && width < minWidth!) {
          width = minWidth!;
        }
        
        return Container(
          width: width,
          padding: padding,
          margin: margin,
          decoration: decoration,
          child: child,
        );
      },
    );
  }
}

/// A responsive text widget that adapts its font size based on screen width.
class ResponsiveText extends StatelessWidget {
  /// The text to display
  final String text;
  
  /// The base font size (will be scaled based on screen width)
  final double fontSize;
  
  /// The text style
  final TextStyle? style;
  
  /// The text alignment
  final TextAlign? textAlign;
  
  /// Whether to use bold font weight
  final bool bold;
  
  /// The maximum number of lines
  final int? maxLines;
  
  /// How to handle text overflow
  final TextOverflow? overflow;

  /// Creates a responsive text widget.
  const ResponsiveText(
    this.text, {
    super.key,
    this.fontSize = 14.0,
    this.style,
    this.textAlign,
    this.bold = false,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate the responsive font size
    final responsiveFontSize = AppTheme.getResponsiveFontSize(
      context,
      baseFontSize: fontSize,
    );
    
    // Create the text style
    final textStyle = (style ?? const TextStyle()).copyWith(
      fontSize: responsiveFontSize,
      fontWeight: bold ? FontWeight.bold : null,
    );
    
    return Text(
      text,
      style: textStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
