import 'package:flutter/material.dart';

class AnimationUtils {
  // Fade in animation
  static Widget fadeIn({
    required Widget child,
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeIn,
  }) {
    final Animation<double> animation = Tween<double>(
      begin: begin,
      end: end,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: curve,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  // Scale animation
  static Widget scale({
    required Widget child,
    required AnimationController controller,
    double begin = 0.8,
    double end = 1.0,
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeOut,
  }) {
    final Animation<double> animation = Tween<double>(
      begin: begin,
      end: end,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: curve,
      ),
    );

    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }

  // Slide animation
  static Widget slide({
    required Widget child,
    required AnimationController controller,
    Offset begin = const Offset(0.0, 1.0),
    Offset end = Offset.zero,
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeOut,
  }) {
    final Animation<Offset> animation = Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: curve,
      ),
    );

    return SlideTransition(
      position: animation,
      child: child,
    );
  }
}
