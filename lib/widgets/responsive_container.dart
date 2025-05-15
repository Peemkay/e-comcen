import 'package:flutter/material.dart';

/// A responsive container that adapts to different screen sizes
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final double? minWidth;
  final double? maxHeight;
  final double? minHeight;
  final double widthFactor;
  final double heightFactor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxDecoration? decoration;
  final Alignment alignment;
  final bool centerContent;

  /// Creates a responsive container.
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.minWidth,
    this.maxHeight,
    this.minHeight,
    this.widthFactor = 0.9, // 90% of screen width by default
    this.heightFactor = 0.0, // No height constraint by default
    this.padding,
    this.margin,
    this.decoration,
    this.alignment = Alignment.center,
    this.centerContent = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the width based on screen size
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        double width = screenWidth * widthFactor;
        double? height = heightFactor > 0 ? screenHeight * heightFactor : null;
        
        // Apply min/max constraints
        if (maxWidth != null && width > maxWidth!) {
          width = maxWidth!;
        }
        if (minWidth != null && width < minWidth!) {
          width = minWidth!;
        }
        
        if (height != null) {
          if (maxHeight != null && height > maxHeight!) {
            height = maxHeight!;
          }
          if (minHeight != null && height < minHeight!) {
            height = minHeight!;
          }
        }
        
        Widget content = child;
        
        // Center the content if requested
        if (centerContent) {
          content = Center(child: child);
        }
        
        return Container(
          width: width,
          height: height,
          padding: padding,
          margin: margin,
          decoration: decoration,
          alignment: alignment,
          child: content,
        );
      },
    );
  }
}

/// A responsive padding widget that adapts to different screen sizes
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double small;
  final double medium;
  final double large;
  
  const ResponsivePadding({
    super.key,
    required this.child,
    this.small = 8.0,
    this.medium = 16.0,
    this.large = 24.0,
  });
  
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    // Determine padding based on screen width
    double padding;
    if (width < 600) {
      padding = small;
    } else if (width < 1200) {
      padding = medium;
    } else {
      padding = large;
    }
    
    return Padding(
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}

/// A responsive grid that adapts to different screen sizes
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? columnCount;
  final double spacing;
  final double aspectRatio;
  final EdgeInsetsGeometry? padding;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.columnCount,
    this.spacing = 16.0,
    this.aspectRatio = 1.0,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the number of columns based on screen width
        final width = constraints.maxWidth;
        
        int count;
        if (columnCount != null) {
          count = columnCount!;
        } else if (width < 600) {
          count = 1; // Mobile
        } else if (width < 900) {
          count = 2; // Tablet
        } else if (width < 1200) {
          count = 3; // Small desktop
        } else {
          count = 4; // Large desktop
        }
        
        return GridView.builder(
          padding: padding,
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
