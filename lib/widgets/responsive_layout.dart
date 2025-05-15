import 'package:flutter/material.dart';

/// A widget that provides different layouts based on screen size
class ResponsiveLayout extends StatelessWidget {
  /// The layout to show on mobile devices (small screens)
  final Widget mobile;
  
  /// The layout to show on tablet devices (medium screens)
  final Widget? tablet;
  
  /// The layout to show on desktop devices (large screens)
  final Widget? desktop;
  
  /// The breakpoint for mobile to tablet transition
  final double tabletBreakpoint;
  
  /// The breakpoint for tablet to desktop transition
  final double desktopBreakpoint;

  /// Creates a responsive layout.
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.tabletBreakpoint = 600,
    this.desktopBreakpoint = 1200,
  });

  /// Returns true if the current screen size is mobile
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  /// Returns true if the current screen size is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  /// Returns true if the current screen size is desktop
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to get the constraints of the parent widget
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get the current screen width
        final width = constraints.maxWidth;
        
        // Desktop layout (width >= desktopBreakpoint)
        if (width >= desktopBreakpoint) {
          return desktop ?? tablet ?? mobile;
        }
        
        // Tablet layout (tabletBreakpoint <= width < desktopBreakpoint)
        if (width >= tabletBreakpoint) {
          return tablet ?? mobile;
        }
        
        // Mobile layout (width < tabletBreakpoint)
        return mobile;
      },
    );
  }
}

/// A widget that provides a two-column layout for desktop views
class TwoColumnLayout extends StatelessWidget {
  /// The left column content
  final Widget left;
  
  /// The right column content
  final Widget right;
  
  /// The ratio of left column width to right column width
  final double ratio;
  
  /// The spacing between columns
  final double spacing;
  
  /// Optional padding around the layout
  final EdgeInsetsGeometry? padding;

  /// Creates a two-column layout.
  const TwoColumnLayout({
    super.key,
    required this.left,
    required this.right,
    this.ratio = 0.4, // Left column takes 40% by default
    this.spacing = 24.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column
          Expanded(
            flex: (ratio * 100).round(),
            child: left,
          ),
          
          // Spacing
          SizedBox(width: spacing),
          
          // Right column
          Expanded(
            flex: ((1 - ratio) * 100).round(),
            child: right,
          ),
        ],
      ),
    );
  }
}

/// A widget that provides a responsive grid layout
class ResponsiveGridView extends StatelessWidget {
  /// The children to display in the grid
  final List<Widget> children;
  
  /// The number of columns for mobile layout
  final int mobileColumns;
  
  /// The number of columns for tablet layout
  final int tabletColumns;
  
  /// The number of columns for desktop layout
  final int desktopColumns;
  
  /// The spacing between items
  final double spacing;
  
  /// The aspect ratio of each item
  final double aspectRatio;
  
  /// Optional padding around the grid
  final EdgeInsetsGeometry? padding;

  /// Creates a responsive grid view.
  const ResponsiveGridView({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16.0,
    this.aspectRatio = 1.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine the number of columns based on screen width
        int columns;
        if (ResponsiveLayout.isDesktop(context)) {
          columns = desktopColumns;
        } else if (ResponsiveLayout.isTablet(context)) {
          columns = tabletColumns;
        } else {
          columns = mobileColumns;
        }
        
        return GridView.builder(
          padding: padding,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
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
