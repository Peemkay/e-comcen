import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/security_constants.dart';
import '../providers/security_provider.dart';
import '../screens/lock_screen.dart';

/// A widget that wraps the entire app to enforce security policies
class SecureAppWrapper extends StatefulWidget {
  final Widget child;
  final bool enforceScreenCapturePrevention;

  const SecureAppWrapper({
    super.key,
    required this.child,
    this.enforceScreenCapturePrevention = true,
  });

  @override
  State<SecureAppWrapper> createState() => _SecureAppWrapperState();
}

class _SecureAppWrapperState extends State<SecureAppWrapper>
    with WidgetsBindingObserver {
  late SecurityProvider _securityProvider;
  Timer? _inactivityTimer;
  DateTime? _lastActivityTime;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Prevent screen capture if enabled
    if (widget.enforceScreenCapturePrevention &&
        SecurityConstants.preventScreenCapture) {
      _preventScreenCapture();
    }

    // Start inactivity timer
    _resetInactivityTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _securityProvider = Provider.of<SecurityProvider>(context, listen: false);

    // Initialize security provider
    if (!_securityProvider.isInitialized) {
      _initializeSecurityProvider();
    }
  }

  Future<void> _initializeSecurityProvider() async {
    try {
      await _securityProvider.initialize();
    } catch (e) {
      debugPrint('Error initializing security provider: $e');
    }
  }

  void _preventScreenCapture() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

    // Prevent screenshots and screen recording
    SystemChannels.platform
        .invokeMethod('SystemChrome.setPreventScreenCapture', true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground
        _checkSecurityStatus();
        _resetInactivityTimer();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        // App went to background
        _cancelInactivityTimer();
        break;
      case AppLifecycleState.detached:
        // App is detached
        _cancelInactivityTimer();
        break;
      default:
        break;
    }
  }

  void _checkSecurityStatus() {
    if (_securityProvider.isInitialized) {
      // Check if session is still active
      if (!_securityProvider.isSessionActive &&
          _securityProvider.isAuthenticated) {
        setState(() {
          _isLocked = true;
        });
      }

      // Check network security
      _securityProvider.checkNetworkSecurity();
    }
  }

  void _resetInactivityTimer() {
    _cancelInactivityTimer();

    _lastActivityTime = DateTime.now();
    _inactivityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkInactivity(),
    );
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _checkInactivity() {
    if (_lastActivityTime == null) return;

    final now = DateTime.now();
    final difference = now.difference(_lastActivityTime!);

    if (difference.inMinutes >= SecurityConstants.sessionTimeoutMinutes) {
      debugPrint(
          'Session timeout detected: ${difference.inMinutes} minutes of inactivity');

      // Update the security provider first
      if (_securityProvider.isInitialized) {
        // This will trigger the session timeout event
        _securityProvider.sessionTimeout();
      }

      setState(() {
        _isLocked = true;
      });
      _cancelInactivityTimer();
    }
  }

  void _onUserInteraction() {
    if (_isLocked) return;

    _lastActivityTime = DateTime.now();
    if (_securityProvider.isInitialized) {
      _securityProvider.updateActivity();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelInactivityTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _onUserInteraction(),
      onPointerMove: (_) => _onUserInteraction(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Get the screen size
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          // Log screen dimensions for debugging
          debugPrint('Screen dimensions: $screenWidth x $screenHeight');

          // Use a Navigator to handle the lock screen properly
          return Container(
            width: screenWidth,
            height: screenHeight,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: _isLocked
                ? MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: Theme.of(context),
                    home: LockScreen(
                      onUnlock: () {
                        setState(() {
                          _isLocked = false;
                        });
                        _resetInactivityTimer();
                      },
                    ),
                  )
                : widget.child,
          );
        },
      ),
    );
  }
}
