import 'package:flutter/material.dart';

/// A widget that displays a shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  final bool enabled;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFEBEBF4),
    this.highlightColor = const Color(0xFFF4F4F4),
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                0.0,
                _animation.value,
                1.0,
              ],
              begin: const Alignment(-1.0, -0.5),
              end: const Alignment(2.0, 0.5),
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A placeholder widget that displays a shimmer loading effect
class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  final bool enabled;

  const ShimmerPlaceholder({
    super.key,
    this.width = double.infinity,
    this.height = 16.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(4.0)),
    this.baseColor = const Color(0xFFEBEBF4),
    this.highlightColor = const Color(0xFFF4F4F4),
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      baseColor: baseColor,
      highlightColor: highlightColor,
      duration: duration,
      enabled: enabled,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// A list item placeholder that displays a shimmer loading effect
class ShimmerListItem extends StatelessWidget {
  final double height;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  final bool enabled;
  final bool showAvatar;
  final bool showAction;
  final int lines;
  final double lineSpacing;

  const ShimmerListItem({
    super.key,
    this.height = 80.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    this.baseColor = const Color(0xFFEBEBF4),
    this.highlightColor = const Color(0xFFF4F4F4),
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
    this.showAvatar = true,
    this.showAction = true,
    this.lines = 2,
    this.lineSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4.0,
            offset: const Offset(0, 2.0),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showAvatar)
            ShimmerPlaceholder(
              width: 48.0,
              height: 48.0,
              borderRadius: BorderRadius.circular(24.0),
              baseColor: baseColor,
              highlightColor: highlightColor,
              duration: duration,
              enabled: enabled,
            ),
          if (showAvatar) const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                lines,
                (index) => Padding(
                  padding: EdgeInsets.only(
                    bottom: index < lines - 1 ? lineSpacing : 0.0,
                  ),
                  child: ShimmerPlaceholder(
                    width: index == 0 ? double.infinity : double.infinity * 0.7,
                    height: 16.0,
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    duration: duration,
                    enabled: enabled,
                  ),
                ),
              ),
            ),
          ),
          if (showAction) const SizedBox(width: 16.0),
          if (showAction)
            ShimmerPlaceholder(
              width: 24.0,
              height: 24.0,
              borderRadius: BorderRadius.circular(12.0),
              baseColor: baseColor,
              highlightColor: highlightColor,
              duration: duration,
              enabled: enabled,
            ),
        ],
      ),
    );
  }
}
