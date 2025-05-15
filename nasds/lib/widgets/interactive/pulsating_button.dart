import 'package:flutter/material.dart';

/// A button that pulses to draw attention to important actions
class PulsatingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color? color;
  final Color? splashColor;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double elevation;
  final bool enabled;
  final bool fullWidth;
  final double? width;
  final double? height;
  final BoxBorder? border;
  final bool pulsate;
  final Duration pulseDuration;

  const PulsatingButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color,
    this.splashColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.elevation = 2.0,
    this.enabled = true,
    this.fullWidth = false,
    this.width,
    this.height,
    this.border,
    this.pulsate = true,
    this.pulseDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<PulsatingButton> createState() => _PulsatingButtonState();
}

class _PulsatingButtonState extends State<PulsatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.pulseDuration,
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    if (widget.pulsate && widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(PulsatingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.pulsate && widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if ((!widget.pulsate || !widget.enabled) && _controller.isAnimating) {
      _controller.stop();
    }
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
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    setState(() {
      _isPressed = false;
    });
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = widget.color ?? theme.primaryColor;
    final disabledColor = theme.disabledColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.pulsate && widget.enabled 
              ? _scaleAnimation.value 
              : _isPressed ? 0.95 : 1.0,
          child: Opacity(
            opacity: widget.pulsate && widget.enabled 
                ? _opacityAnimation.value 
                : 1.0,
            child: child,
          ),
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
                blurRadius: widget.elevation,
                offset: const Offset(0, 2.0),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              splashColor: widget.splashColor ?? theme.splashColor,
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
