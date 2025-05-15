import 'package:flutter/material.dart';
import '../utils/responsive_layout_util.dart';

/// A responsive grid layout that adapts to different screen sizes.
///
/// This grid automatically adjusts the number of columns based on the screen width,
/// providing an optimal layout for different devices from mobile to desktop.
class ResponsiveGrid extends StatelessWidget {
  /// The list of widgets to display in the grid.
  final List<Widget> children;

  /// Optional fixed number of columns. If not provided, the number of columns
  /// will be calculated based on the screen width.
  final int? columnCount;

  /// Spacing between items in the grid.
  final double spacing;

  /// Aspect ratio of each grid item (width / height).
  final double aspectRatio;

  /// Padding around the grid.
  final EdgeInsetsGeometry? padding;

  /// Whether the grid should scroll.
  final bool scrollable;

  /// Optional scroll controller.
  final ScrollController? scrollController;

  /// Optional scroll physics.
  final ScrollPhysics? scrollPhysics;

  /// Creates a responsive grid layout.
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.columnCount,
    this.spacing = 16.0,
    this.aspectRatio = 1.0,
    this.padding,
    this.scrollable = true,
    this.scrollController,
    this.scrollPhysics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the number of columns based on screen width
        final count =
            columnCount ?? ResponsiveLayoutUtil.responsiveGridCount(context);

        // Calculate responsive spacing
        final responsiveSpacing = ResponsiveLayoutUtil.responsiveValue(
          context,
          mobileValue: spacing,
          desktopValue: spacing * 1.5,
        );

        // Calculate responsive aspect ratio
        final responsiveAspectRatio =
            ResponsiveLayoutUtil.responsiveCardAspectRatio(context);

        // Calculate responsive padding
        final gridPadding = padding ??
            EdgeInsets.all(
              ResponsiveLayoutUtil.responsiveSpacing(context,
                  baseSpacing: 16.0),
            );

        // Create the grid layout
        final gridView = GridView.builder(
          padding: gridPadding,
          shrinkWrap: true,
          physics:
              scrollable ? scrollPhysics : const NeverScrollableScrollPhysics(),
          controller: scrollable ? scrollController : null,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            childAspectRatio: aspectRatio * responsiveAspectRatio,
            crossAxisSpacing: responsiveSpacing,
            mainAxisSpacing: responsiveSpacing,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );

        return scrollable
            ? gridView
            : SizedBox(
                width: constraints.maxWidth,
                child: gridView,
              );
      },
    );
  }
}

/// A responsive grid item that adapts to different screen sizes.
///
/// This widget provides a consistent layout for grid items with optional
/// title, subtitle, and content sections.
class ResponsiveGridItem extends StatelessWidget {
  /// The primary content of the grid item.
  final Widget child;

  /// Optional title widget displayed at the top of the grid item.
  final Widget? title;

  /// Optional subtitle widget displayed below the title.
  final Widget? subtitle;

  /// Optional icon displayed in the top-left corner of the grid item.
  final IconData? icon;

  /// Color of the icon.
  final Color? iconColor;

  /// Background color of the grid item.
  final Color? backgroundColor;

  /// Border color of the grid item.
  final Color? borderColor;

  /// Elevation of the grid item.
  final double? elevation;

  /// Border radius of the grid item.
  final double? borderRadius;

  /// Padding inside the grid item.
  final EdgeInsetsGeometry? padding;

  /// Optional callback when the grid item is tapped.
  final VoidCallback? onTap;

  /// Creates a responsive grid item.
  const ResponsiveGridItem({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.elevation,
    this.borderRadius,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get responsive values based on screen size
    // Desktop view check removed (unused)
    final responsiveElevation =
        elevation ?? ResponsiveLayoutUtil.responsiveElevation(context);
    final responsiveBorderRadius =
        borderRadius ?? ResponsiveLayoutUtil.responsiveBorderRadius(context);

    // Calculate padding based on screen size
    final defaultPadding = EdgeInsets.all(
      ResponsiveLayoutUtil.responsiveSpacing(context, baseSpacing: 12.0),
    );
    final itemPadding = padding ?? defaultPadding;

    // Build the grid item content
    Widget itemContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title section
        if (title != null || icon != null)
          Padding(
            padding: EdgeInsets.only(
              bottom: subtitle != null ? 4.0 : 8.0,
            ),
            child: Row(
              children: [
                if (icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: ResponsiveLayoutUtil.responsiveIconSize(context),
                    ),
                  ),
                if (title != null) Expanded(child: title!),
              ],
            ),
          ),

        // Subtitle
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: subtitle!,
          ),

        // Main content
        Expanded(child: child),
      ],
    );

    // Wrap in Material for proper elevation and ink effects
    return Material(
      color: backgroundColor ?? Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(responsiveBorderRadius),
      elevation: responsiveElevation,
      child: InkWell(
        borderRadius: BorderRadius.circular(responsiveBorderRadius),
        onTap: onTap,
        child: Padding(
          padding: itemPadding,
          child: itemContent,
        ),
      ),
    );
  }
}
