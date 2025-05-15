import 'package:flutter/material.dart';
import '../utils/responsive_layout_util.dart';

/// A widget that handles overflow by adapting its layout based on available space.
///
/// This widget helps prevent overflow errors by automatically adjusting its
/// layout based on the available space and screen size.
class ResponsiveOverflowHandler extends StatelessWidget {
  /// The child widget that might overflow
  final Widget child;
  
  /// Optional maximum width constraint
  final double? maxWidth;
  
  /// Optional maximum height constraint
  final double? maxHeight;
  
  /// Whether to use a scrollable view for the content
  final bool scrollable;
  
  /// The scroll direction (only applicable if scrollable is true)
  final Axis scrollDirection;
  
  /// Optional padding around the content
  final EdgeInsets? padding;
  
  /// Optional alignment of the content
  final Alignment alignment;
  
  /// Optional background color
  final Color? backgroundColor;

  /// Creates a responsive overflow handler.
  const ResponsiveOverflowHandler({
    super.key,
    required this.child,
    this.maxWidth,
    this.maxHeight,
    this.scrollable = true,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.alignment = Alignment.center,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate responsive constraints
    final screenWidth = ResponsiveLayoutUtil.screenWidth(context);
    final screenHeight = ResponsiveLayoutUtil.screenHeight(context);
    
    final responsiveMaxWidth = maxWidth ?? screenWidth * 0.95;
    final responsiveMaxHeight = maxHeight ?? screenHeight * 0.95;
    
    // Create the content with constraints
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: responsiveMaxWidth,
        maxHeight: responsiveMaxHeight,
      ),
      child: child,
    );
    
    // Add padding if provided
    if (padding != null) {
      content = Padding(
        padding: padding!,
        child: content,
      );
    }
    
    // Wrap in SingleChildScrollView if scrollable is true
    if (scrollable) {
      content = SingleChildScrollView(
        scrollDirection: scrollDirection,
        physics: const ClampingScrollPhysics(),
        child: content,
      );
    }
    
    // Wrap in Align to position the content
    content = Align(
      alignment: alignment,
      child: content,
    );
    
    // Add background color if provided
    if (backgroundColor != null) {
      content = Container(
        color: backgroundColor,
        child: content,
      );
    }
    
    return content;
  }
}

/// A widget that handles text overflow by automatically adjusting font size.
class ResponsiveAutoSizeText extends StatelessWidget {
  /// The text to display
  final String text;
  
  /// The text style
  final TextStyle? style;
  
  /// The minimum font size to use
  final double minFontSize;
  
  /// The maximum font size to use
  final double maxFontSize;
  
  /// The step size for font size adjustment
  final double stepGranularity;
  
  /// The maximum number of lines
  final int? maxLines;
  
  /// How to handle text overflow
  final TextOverflow overflow;
  
  /// The text alignment
  final TextAlign? textAlign;
  
  /// Whether to use soft wrapping
  final bool softWrap;

  /// Creates a responsive auto-size text.
  const ResponsiveAutoSizeText(
    this.text, {
    super.key,
    this.style,
    this.minFontSize = 8.0,
    this.maxFontSize = 24.0,
    this.stepGranularity = 1.0,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
    this.softWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate the base font size based on screen size
    final baseFontSize = ResponsiveLayoutUtil.responsiveFontSize(
      context,
      baseFontSize: style?.fontSize ?? 14.0,
    );
    
    // Create a copy of the style with the responsive font size
    final responsiveStyle = (style ?? const TextStyle()).copyWith(
      fontSize: baseFontSize,
    );
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Start with the maximum font size
        double fontSize = maxFontSize;
        
        // Create a text painter to measure the text
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: responsiveStyle.copyWith(fontSize: fontSize),
          ),
          maxLines: maxLines,
          textDirection: TextDirection.ltr,
        );
        
        // Reduce the font size until the text fits within the constraints
        while (fontSize > minFontSize) {
          textPainter.text = TextSpan(
            text: text,
            style: responsiveStyle.copyWith(fontSize: fontSize),
          );
          
          textPainter.layout(maxWidth: constraints.maxWidth);
          
          // Check if the text fits within the constraints
          if (textPainter.didExceedMaxLines ||
              textPainter.width > constraints.maxWidth ||
              (maxLines != null && textPainter.height > constraints.maxHeight)) {
            // Text doesn't fit, reduce the font size
            fontSize -= stepGranularity;
          } else {
            // Text fits, we're done
            break;
          }
        }
        
        // Create the text widget with the adjusted font size
        return Text(
          text,
          style: responsiveStyle.copyWith(fontSize: fontSize),
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
          softWrap: softWrap,
        );
      },
    );
  }
}
