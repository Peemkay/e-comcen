import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/security_constants.dart';
import '../providers/security_provider.dart';

/// A widget that wraps the entire app to enforce security policies
/// Note: Lock screen functionality has been removed as requested
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Prevent screen capture if enabled
    if (widget.enforceScreenCapturePrevention &&
        SecurityConstants.preventScreenCapture) {
      _preventScreenCapture();
    }
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
        if (_securityProvider.isInitialized) {
          // Check network security
          _securityProvider.checkNetworkSecurity();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get the screen size
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // Log screen dimensions for debugging
        debugPrint('Screen dimensions: $screenWidth x $screenHeight');

        // Simply return the child widget - no lock screen functionality
        return Container(
          width: screenWidth,
          height: screenHeight,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: widget.child,
        );
      },
    );
  }
}
