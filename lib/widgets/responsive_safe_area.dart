import 'package:flutter/material.dart';
import '../utils/responsive_layout_util.dart';

/// A responsive safe area widget that adapts its padding based on screen size and orientation.
///
/// This widget extends the functionality of the standard SafeArea widget by adding
/// responsive padding that adapts to different screen sizes and orientations.
class ResponsiveSafeArea extends StatelessWidget {
  /// The child widget to be wrapped with safe area and responsive padding
  final Widget child;
  
  /// Optional minimum padding to apply regardless of screen size
  final EdgeInsets? minimumPadding;
  
  /// Optional padding factor to scale the padding based on screen size
  final double paddingFactor;
  
  /// Whether to maintain the bottom padding in landscape mode
  final bool maintainBottomPadding;
  
  /// Whether to use a scrollable view for the content
  final bool scrollable;
  
  /// Optional background color
  final Color? backgroundColor;

  /// Creates a responsive safe area.
  const ResponsiveSafeArea({
    super.key,
    required this.child,
    this.minimumPadding,
    this.paddingFactor = 1.0,
    this.maintainBottomPadding = true,
    this.scrollable = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if we're in landscape mode
    final isLandscape = ResponsiveLayoutUtil.isLandscape(context);
    
    // Calculate responsive padding based on screen size
    final responsivePadding = ResponsiveLayoutUtil.responsivePadding(
      context,
      factor: paddingFactor,
    );
    
    // Apply minimum padding if provided
    final padding = minimumPadding != null
        ? EdgeInsets.fromLTRB(
            math.max(minimumPadding!.left, responsivePadding.left),
            math.max(minimumPadding!.top, responsivePadding.top),
            math.max(minimumPadding!.right, responsivePadding.right),
            math.max(minimumPadding!.bottom, responsivePadding.bottom),
          )
        : responsivePadding;
    
    // Adjust padding for landscape mode if needed
    final adjustedPadding = isLandscape && !maintainBottomPadding
        ? padding.copyWith(bottom: 0)
        : padding;
    
    // Create the content with padding
    Widget content = Padding(
      padding: adjustedPadding,
      child: child,
    );
    
    // Wrap in SingleChildScrollView if scrollable is true
    if (scrollable) {
      content = SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: content,
      );
    }
    
    // Wrap in SafeArea to avoid system UI overlays
    return SafeArea(
      child: Container(
        color: backgroundColor,
        child: content,
      ),
    );
  }
}

/// A responsive padding widget that adapts its padding based on screen size.
class ResponsivePadding extends StatelessWidget {
  /// The child widget to be wrapped with responsive padding
  final Widget child;
  
  /// Optional padding factor to scale the padding based on screen size
  final double factor;
  
  /// Optional minimum padding to apply regardless of screen size
  final EdgeInsets? minimumPadding;
  
  /// Optional custom horizontal padding
  final double? horizontal;
  
  /// Optional custom vertical padding
  final double? vertical;

  /// Creates a responsive padding.
  const ResponsivePadding({
    super.key,
    required this.child,
    this.factor = 1.0,
    this.minimumPadding,
    this.horizontal,
    this.vertical,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate responsive padding based on screen size
    final responsivePadding = ResponsiveLayoutUtil.responsivePadding(
      context,
      horizontal: horizontal,
      vertical: vertical,
      factor: factor,
    );
    
    // Apply minimum padding if provided
    final padding = minimumPadding != null
        ? EdgeInsets.fromLTRB(
            math.max(minimumPadding!.left, responsivePadding.left),
            math.max(minimumPadding!.top, responsivePadding.top),
            math.max(minimumPadding!.right, responsivePadding.right),
            math.max(minimumPadding!.bottom, responsivePadding.bottom),
          )
        : responsivePadding;
    
    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// Import dart:math for max function
import 'dart:math' as math;
