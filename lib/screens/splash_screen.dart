import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../constants/security_constants.dart';
import '../widgets/placeholder_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Main animations
  late AnimationController _mainAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Logo animations
  late AnimationController _logoAnimationController;
  late Animation<double> _logoRotateAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoGlowAnimation;

  // Text animations
  late AnimationController _textAnimationController;
  late Animation<double> _textSlideAnimation;

  // Security banner animation
  late AnimationController _securityBannerController;
  late Animation<double> _securityBannerAnimation;

  // Progress indicator animation
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize main animation controller
    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Create main animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Initialize logo animation controller
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Create logo animations
    _logoRotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.1),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0),
        weight: 60,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    );

    _logoGlowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.5),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 0.8),
        weight: 30,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Initialize text animation controller
    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Create text animations
    _textSlideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Initialize security banner animation controller
    _securityBannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Create security banner animation
    _securityBannerAnimation = Tween<double>(begin: -50, end: 0).animate(
      CurvedAnimation(
        parent: _securityBannerController,
        curve: Curves.easeOutBack,
      ),
    );

    // Initialize progress animation controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Create progress animation
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations in sequence
    _mainAnimationController.forward().then((_) {
      _logoAnimationController.forward();
      _textAnimationController.forward();

      // Delay security banner animation
      Future.delayed(const Duration(milliseconds: 300), () {
        _securityBannerController.forward();
      });

      // Delay progress animation
      Future.delayed(const Duration(milliseconds: 600), () {
        _progressController.forward();
      });
    });

    // Navigate to loading screen after splash duration
    Timer(
      Duration(seconds: AppConstants.splashDuration),
      () => Navigator.pushReplacementNamed(context, AppConstants.loadingRoute),
    );
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _logoAnimationController.dispose();
    _textAnimationController.dispose();
    _securityBannerController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isVerySmallScreen = screenSize.height < 600;

    // More responsive sizes based on screen dimensions
    final logoSize = isVerySmallScreen
        ? 100.0
        : isSmallScreen
            ? 120.0
            : 150.0;
    final titleFontSize = isVerySmallScreen
        ? 24.0
        : isSmallScreen
            ? 28.0
            : 36.0;
    final subtitleFontSize = isVerySmallScreen
        ? 14.0
        : isSmallScreen
            ? 16.0
            : 18.0;

    // Adaptive spacing based on screen height
    final baseSpacing = isVerySmallScreen
        ? 10.0
        : isSmallScreen
            ? 15.0
            : 20.0;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withAlpha(217), // 0.85 opacity
              AppTheme.secondaryColor.withAlpha(153), // 0.6 opacity
            ],
            stops: const [0.2, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: screenSize.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _mainAnimationController,
                  _logoAnimationController,
                  _textAnimationController,
                ]),
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: baseSpacing,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                                // Logo with animations
                                Transform.rotate(
                                  angle: _logoRotateAnimation.value,
                                  child: Transform.scale(
                                    scale: _logoScaleAnimation.value,
                                    child: Container(
                                      width: logoSize,
                                      height: logoSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.accentColor.withAlpha(
                                              (51 + (_logoGlowAnimation.value * 77))
                                                  .toInt(), // 0.2-0.5 opacity
                                            ),
                                            blurRadius: 20 +
                                                (_logoGlowAnimation.value * 15),
                                            spreadRadius:
                                                4 + (_logoGlowAnimation.value * 4),
                                          ),
                                        ],
                                      ),
                                      child: PlaceholderLogo(
                                        size: logoSize,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: baseSpacing * 2),

                                // App name with slide animation
                                Transform.translate(
                                  offset: Offset(0, _textSlideAnimation.value),
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        Colors.white,
                                        AppTheme.accentColor,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                    child: Text(
                                      AppConstants.appName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: isVerySmallScreen ? 1.5 : 3,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black
                                                .withAlpha(77), // 0.3 opacity
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                SizedBox(height: baseSpacing * 0.8),

                                // Full app name with slide animation
                                Transform.translate(
                                  offset:
                                      Offset(0, _textSlideAnimation.value * 1.2),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      AppConstants.appFullName,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withAlpha(230), // 0.9 opacity
                                        fontSize: subtitleFontSize,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: baseSpacing),

                                // Powered by text with slide animation
                                Transform.translate(
                                  offset:
                                      Offset(0, _textSlideAnimation.value * 1.4),
                                  child: Text(
                                    'Powered by ${AppConstants.appPoweredBy}',
                                    style: TextStyle(
                                      color: Colors.white
                                          .withAlpha(179), // 0.7 opacity
                                      fontSize: isVerySmallScreen ? 12 : 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: baseSpacing * 0.5),

                                // Version and platform info with slide animation
                                Transform.translate(
                                  offset:
                                      Offset(0, _textSlideAnimation.value * 1.6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'v${AppConstants.appVersion} | ${AppConstants.appPlatform} | ${AppConstants.appDeviceName}',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withAlpha(153), // 0.6 opacity
                                        fontSize: isVerySmallScreen ? 10 : 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                SizedBox(height: baseSpacing * 2),

                                // Animated progress indicator
                                AnimatedBuilder(
                                  animation: _progressController,
                                  builder: (context, child) {
                                    return SizedBox(
                                      width: isVerySmallScreen ? 50 : 70,
                                      height: isVerySmallScreen ? 50 : 70,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Outer circle
                                          CircularProgressIndicator(
                                            value: _progressAnimation.value,
                                            valueColor:
                                                const AlwaysStoppedAnimation<Color>(
                                              AppTheme.accentColor,
                                            ),
                                            strokeWidth: isVerySmallScreen ? 3 : 4,
                                          ),
                                          // Inner circle
                                          CircularProgressIndicator(
                                            value: _progressAnimation.value * 0.8,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white
                                                  .withAlpha(179), // 0.7 opacity
                                            ),
                                            strokeWidth: 2,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for drawing a grid pattern
class GridPatternPainter extends CustomPainter {
  final Color lineColor;
  final double lineWidth;
  final double gridSize;

  GridPatternPainter({
    required this.lineColor,
    required this.lineWidth,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(GridPatternPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.lineWidth != lineWidth ||
      oldDelegate.gridSize != gridSize;
}
