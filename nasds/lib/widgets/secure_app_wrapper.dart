import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/security_constants.dart';
import '../providers/security_provider.dart';
import '../providers/navigation_provider.dart';

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
    with WidgetsBindingObserver, RouteAware {
  late SecurityProvider _securityProvider;
  late NavigationProvider _navigationProvider;
  Timer? _inactivityTimer;
  DateTime? _lastActivityTime;
  final RouteObserver<ModalRoute<void>> _routeObserver =
      RouteObserver<ModalRoute<void>>();

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
    _navigationProvider =
        Provider.of<NavigationProvider>(context, listen: false);

    // Initialize security provider
    if (!_securityProvider.isInitialized) {
      _initializeSecurityProvider();
    }

    // Register for route changes
    ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route != null) {
      _routeObserver.subscribe(this, route);

      // Update current route in navigation provider
      if (route.settings.name != null) {
        _navigationProvider.setCurrentRoute(route.settings.name!);
      }
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
        // Log out the user completely
        _securityProvider.logout().then((_) {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
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
      // Log out the user completely
      _securityProvider.logout().then((_) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      });

      _cancelInactivityTimer();
    }
  }

  void _onUserInteraction() {
    _lastActivityTime = DateTime.now();
    if (_securityProvider.isInitialized) {
      _securityProvider.updateActivity();
    }
  }

  // Route observer methods
  @override
  void didPush() {
    // Route was pushed onto navigator and is now top-most route
    final route = ModalRoute.of(context);
    if (route?.settings.name != null) {
      _navigationProvider.setCurrentRoute(route!.settings.name!);
      _navigationProvider.setLastActiveRoute(route.settings.name!);
    }
  }

  @override
  void didPopNext() {
    // Route was popped off navigator and this route is now top-most route
    final route = ModalRoute.of(context);
    if (route?.settings.name != null) {
      _navigationProvider.setCurrentRoute(route!.settings.name!);
      _navigationProvider.setLastActiveRoute(route.settings.name!);
    }
  }

  @override
  void didPop() {
    // This route was popped off the navigator
  }

  void didReplace({Route<dynamic>? newRoute}) {
    // This route was replaced by another route
    if (newRoute?.settings.name != null) {
      _navigationProvider.setCurrentRoute(newRoute!.settings.name!);
      _navigationProvider.setLastActiveRoute(newRoute.settings.name!);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routeObserver.unsubscribe(this);
    _cancelInactivityTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _onUserInteraction(),
      onPointerMove: (_) => _onUserInteraction(),
      child: widget.child,
    );
  }
}
