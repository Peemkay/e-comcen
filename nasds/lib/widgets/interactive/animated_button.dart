import 'package:flutter/material.dart';

/// An animated button that provides visual feedback when pressed
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color? color;
  final Color? splashColor;
  final Color? highlightColor;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double elevation;
  final double highlightElevation;
  final Duration animationDuration;
  final bool enabled;
  final bool fullWidth;
  final double? width;
  final double? height;
  final BoxBorder? border;

  const AnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color,
    this.splashColor,
    this.highlightColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.elevation = 2.0,
    this.highlightElevation = 4.0,
    this.animationDuration = const Duration(milliseconds: 150),
    this.enabled = true,
    this.fullWidth = false,
    this.width,
    this.height,
    this.border,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    setState(() {
      _isPressed = true;
    });
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = widget.color ?? theme.primaryColor;
    final disabledColor = theme.disabledColor;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.enabled ? widget.onPressed : null,
        child: Container(
          width: widget.fullWidth ? double.infinity : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.enabled ? buttonColor : disabledColor,
            borderRadius: widget.borderRadius,
            border: widget.border,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: _isPressed
                    ? widget.highlightElevation
                    : widget.elevation,
                offset: Offset(0, _isPressed ? 1.0 : 2.0),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              splashColor: widget.splashColor ?? theme.splashColor,
              highlightColor: widget.highlightColor ?? theme.highlightColor,
              borderRadius: widget.borderRadius,
              onTap: widget.enabled ? widget.onPressed : null,
              child: Padding(
                padding: widget.padding,
                child: Center(
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
