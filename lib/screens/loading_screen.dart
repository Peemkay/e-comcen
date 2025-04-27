import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../constants/security_constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  // Progress animation
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Fade animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Pulse animation for progress indicator
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Slide animation for cards
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  // Rotate animation for gear icon
  late AnimationController _rotateController;
  late Animation<double> _rotateAnimation;

  // Progress value and loading messages
  double _progressValue = 0.0;
  final List<String> _loadingMessages = [
    'Initializing secure environment...',
    'Loading communication protocols...',
    'Preparing dispatch management system...',
    'Configuring secure channels...',
    'Establishing encrypted connections...',
    'Almost ready...',
  ];
  int _currentMessageIndex = 0;

  // Loading steps with icons and descriptions
  final List<LoadingStep> _loadingSteps = [
    LoadingStep(
      icon: Icons.security,
      title: 'Security Check',
      description: 'Verifying system integrity',
    ),
    LoadingStep(
      icon: Icons.storage,
      title: 'Data Preparation',
      description: 'Loading dispatch records',
    ),
    LoadingStep(
      icon: Icons.settings,
      title: 'System Configuration',
      description: 'Applying user preferences',
    ),
    LoadingStep(
      icon: Icons.sync,
      title: 'Synchronization',
      description: 'Connecting to secure network',
    ),
  ];

  // Completed steps
  final List<bool> _completedSteps = [false, false, false, false];

  @override
  void initState() {
    super.initState();

    // Initialize progress animation controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    // Create progress animation
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
        setState(() {
          _progressValue = _progressAnimation.value;
        });

        // Change loading message based on progress
        if (_progressValue < 0.15 && _currentMessageIndex != 0) {
          setState(() {
            _currentMessageIndex = 0;
          });
        } else if (_progressValue >= 0.15 &&
            _progressValue < 0.3 &&
            _currentMessageIndex != 1) {
          setState(() {
            _currentMessageIndex = 1;
            _completedSteps[0] = true;
          });
        } else if (_progressValue >= 0.3 &&
            _progressValue < 0.5 &&
            _currentMessageIndex != 2) {
          setState(() {
            _currentMessageIndex = 2;
            _completedSteps[1] = true;
          });
        } else if (_progressValue >= 0.5 &&
            _progressValue < 0.7 &&
            _currentMessageIndex != 3) {
          setState(() {
            _currentMessageIndex = 3;
            _completedSteps[2] = true;
          });
        } else if (_progressValue >= 0.7 &&
            _progressValue < 0.9 &&
            _currentMessageIndex != 4) {
          setState(() {
            _currentMessageIndex = 4;
            _completedSteps[3] = true;
          });
        } else if (_progressValue >= 0.9 && _currentMessageIndex != 5) {
          setState(() {
            _currentMessageIndex = 5;
          });
        }
      });

    // Initialize fade animation controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Create fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    // Initialize pulse animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Create pulse animation
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize slide animation controller
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Create slide animation
    _slideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Initialize rotate animation controller
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Create rotate animation
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _rotateController,
        curve: Curves.linear,
      ),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _progressController.forward();

    // Navigate to home screen after loading completes
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Timer(
          const Duration(milliseconds: 800),
          () =>
              Navigator.pushReplacementNamed(context, AppConstants.loginRoute),
        );
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey.shade50,
              Colors.grey.shade100,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 24.0 : 32.0,
                vertical: 16.0,
              ),
              child: Column(
                children: [
                  // Security classification banner
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.security,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          SecurityConstants.securityClassification,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Logo and title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor
                                        .withAlpha(51), // 0.2 opacity
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: SvgPicture.asset(
                                'assets/images/nasds_logo.svg',
                                width: 40,
                                height: 40,
                                colorFilter: ColorFilter.mode(
                                  AppTheme.primaryColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            AppConstants.appFullName,
                            style: TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Progress indicator and percentage
                  AnimatedBuilder(
                    animation:
                        Listenable.merge([_progressAnimation, _pulseAnimation]),
                    builder: (context, child) {
                      return Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Background circle
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade50,
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 2,
                                  ),
                                ),
                              ),

                              // Circular progress indicator
                              SizedBox(
                                width: 130,
                                height: 130,
                                child: CircularProgressIndicator(
                                  value: _progressValue,
                                  strokeWidth: 10,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryColor,
                                  ),
                                ),
                              ),

                              // Secondary progress indicator
                              SizedBox(
                                width: 110,
                                height: 110,
                                child: CircularProgressIndicator(
                                  value:
                                      _progressValue * 0.8, // Slightly behind
                                  strokeWidth: 6,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.secondaryColor,
                                  ),
                                ),
                              ),

                              // Progress percentage
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Text(
                                      '${(_progressValue * 100).toInt()}%',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Loading...',
                                    style: TextStyle(
                                      color: AppTheme.textColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Loading message
                          Container(
                            height: 50,
                            alignment: Alignment.center,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.0, 0.5),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                _loadingMessages[_currentMessageIndex],
                                key: ValueKey<int>(_currentMessageIndex),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.secondaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Loading steps
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) {
                        return ListView.builder(
                          itemCount: _loadingSteps.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            // Calculate staggered animation offset
                            final staggeredOffset =
                                _slideAnimation.value * (1 + (index * 0.2));

                            return Transform.translate(
                              offset: Offset(staggeredOffset, 0),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildLoadingStepCard(
                                  _loadingSteps[index],
                                  _completedSteps[index],
                                  index,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Footer
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '© ${AppConstants.currentYear} ${AppConstants.appOrganization}',
                          style: TextStyle(
                            color: AppTheme.textColor
                                .withAlpha(179), // 0.7 opacity
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.textColor
                                .withAlpha(128), // 0.5 opacity
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'v${AppConstants.appVersion}',
                          style: TextStyle(
                            color: AppTheme.textColor
                                .withAlpha(179), // 0.7 opacity
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build a loading step card
  Widget _buildLoadingStepCard(LoadingStep step, bool isCompleted, int index) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted
              ? AppTheme.secondaryColor.withAlpha(128) // 0.5 opacity
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Step icon with animation
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppTheme.secondaryColor.withAlpha(26) // 0.1 opacity
                    : Colors.grey.shade100,
              ),
              child: Center(
                child: isCompleted
                    ? Icon(
                        Icons.check_circle,
                        color: AppTheme.secondaryColor,
                        size: 28,
                      )
                    : index == _currentMessageIndex ~/ 2
                        ? AnimatedBuilder(
                            animation: _rotateController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotateAnimation.value,
                                child: Icon(
                                  Icons.settings,
                                  color: AppTheme.primaryColor,
                                  size: 28,
                                ),
                              );
                            },
                          )
                        : Icon(
                            step.icon,
                            color: Colors.grey,
                            size: 28,
                          ),
              ),
            ),
            const SizedBox(width: 16),

            // Step title and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      color: isCompleted
                          ? AppTheme.secondaryColor
                          : index == _currentMessageIndex ~/ 2
                              ? AppTheme.primaryColor
                              : Colors.grey.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Status indicator
            SizedBox(
              width: 24,
              child: isCompleted
                  ? const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    )
                  : index == _currentMessageIndex ~/ 2
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.circle_outlined,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Model class for loading steps
class LoadingStep {
  final IconData icon;
  final String title;
  final String description;

  LoadingStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}
