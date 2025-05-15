import 'package:flutter/material.dart';

/// An animated list item that provides visual feedback when pressed
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Color? splashColor;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Duration animationDuration;
  final bool enabled;
  final int index;
  final Duration staggerDuration;
  final Curve curve;
  final bool animate;
  final BoxBorder? border;

  const AnimatedListItem({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.splashColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.animationDuration = const Duration(milliseconds: 150),
    this.enabled = true,
    this.index = 0,
    this.staggerDuration = const Duration(milliseconds: 50),
    this.curve = Curves.easeOut,
    this.animate = true,
    this.border,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    // Entry animations
    final entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    final delay = widget.staggerDuration.inMilliseconds * widget.index;
    final entryDuration = const Duration(milliseconds: 600);
    
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted && widget.animate) {
        entryController.forward();
      }
    });
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: entryController,
        curve: Interval(0.0, 0.6, curve: widget.curve),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: entryController,
        curve: Interval(0.0, 0.6, curve: widget.curve),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.onTap == null) return;
    setState(() {
      _isPressed = true;
    });
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled || widget.onTap == null) return;
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (!widget.enabled || widget.onTap == null) return;
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemColor = widget.color ?? theme.cardColor;

    if (!widget.animate) {
      return _buildInteractiveItem(itemColor);
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: child,
          ),
        );
      },
      child: _buildInteractiveItem(itemColor),
    );
  }

  Widget _buildInteractiveItem(Color itemColor) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.onTap != null ? _scaleAnimation.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: itemColor,
              borderRadius: widget.borderRadius,
              border: widget.border,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                onTap: widget.enabled ? widget.onTap : null,
                borderRadius: widget.borderRadius,
                splashColor: widget.splashColor,
                child: Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
