import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../constants/security_constants.dart';
import '../extensions/string_extensions.dart';
import '../providers/security_provider.dart';
import '../providers/navigation_provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _isBiometricSupported = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isAuthenticating = false;

  // Session timeout timer
  Timer? _sessionTimer;
  DateTime? _sessionExpiryTime;

  // PIN for unlocking (should be retrieved from secure storage in a real app)
  final String _correctPin = '123456';

  late SecurityProvider _securityProvider;
  late NavigationProvider _navigationProvider;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _startSessionExpiryTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _securityProvider = Provider.of<SecurityProvider>(context, listen: false);
    _navigationProvider =
        Provider.of<NavigationProvider>(context, listen: false);

    // Calculate session expiry time
    _sessionExpiryTime = DateTime.now()
        .add(Duration(minutes: SecurityConstants.sessionTimeoutMinutes * 2));
  }

  Future<void> _checkBiometrics() async {
    try {
      _canCheckBiometrics = await _localAuth.canCheckBiometrics;
      _isBiometricSupported = await _localAuth.isDeviceSupported();

      if (_canCheckBiometrics && _isBiometricSupported) {
        _availableBiometrics = await _localAuth.getAvailableBiometrics();

        if (_availableBiometrics.isNotEmpty) {
          _authenticateWithBiometrics();
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Error checking biometrics: $e');
    }
  }

  void _startSessionExpiryTimer() {
    // Cancel any existing timer
    _sessionTimer?.cancel();

    // Set session expiry time (twice the session timeout to give users time to unlock)
    _sessionExpiryTime = DateTime.now()
        .add(Duration(minutes: SecurityConstants.sessionTimeoutMinutes * 2));

    // Start a timer to update the countdown
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Just trigger a rebuild to update the countdown
        });

        // Check if session has completely expired
        if (DateTime.now().isAfter(_sessionExpiryTime!)) {
          _sessionTimer?.cancel();
          _handleCompleteSessionExpiry();
        }
      }
    });
  }

  void _handleCompleteSessionExpiry() {
    // Completely log out the user when session fully expires
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

  String _getTimeRemaining() {
    if (_sessionExpiryTime == null) return '00:00';

    final now = DateTime.now();
    final remaining = _sessionExpiryTime!.difference(now);

    if (remaining.isNegative) return '00:00';

    final minutes =
        remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    try {
      final authenticated =
          await _securityProvider.authenticateUser(biometricOnly: true);

      if (authenticated && mounted) {
        // Resume session
        _securityProvider.updateActivity();

        // Navigate to the last active route
        final lastRoute = _navigationProvider.lastActiveRoute;
        Navigator.pushReplacementNamed(context, lastRoute);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session resumed successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error authenticating with biometrics: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric authentication failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with lock icon overlay
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // App logo
                        Image.asset(
                          'assets/images/nasds_logo.png',
                          height: 120,
                        ),
                        // Lock icon overlay
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'app_name'.tr(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'app_full_name'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Security classification if enabled
                    if (SecurityConstants.securityClassification.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          SecurityConstants.securityClassification,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Session timeout message with countdown
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Session Locked',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your session has been locked due to inactivity',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // Countdown timer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Session expires in: ${_getTimeRemaining()}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Unlock options
                    Text(
                      'Unlock Options',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PIN unlock button
                    ElevatedButton.icon(
                      onPressed: () {
                        _showUnlockScreen();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.pin_outlined),
                      label: Text(
                        'Enter PIN',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Biometric authentication button
                    if (_canCheckBiometrics &&
                        _isBiometricSupported &&
                        _availableBiometrics.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: _authenticateWithBiometrics,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.white, width: 1),
                          ),
                          elevation: 0,
                        ),
                        icon: Icon(
                          _availableBiometrics.contains(BiometricType.face)
                              ? Icons.face
                              : _availableBiometrics
                                      .contains(BiometricType.fingerprint)
                                  ? Icons.fingerprint
                                  : Icons.security,
                        ),
                        label: Text(
                          _availableBiometrics.contains(BiometricType.face)
                              ? 'Use Face ID'
                              : _availableBiometrics
                                      .contains(BiometricType.fingerprint)
                                  ? 'Use Fingerprint'
                                  : 'Use Biometrics',
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Divider
                    Divider(color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 16),

                    // Logout button
                    TextButton.icon(
                      onPressed: () {
                        _showLogoutConfirmation();
                      },
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white70,
                      ),
                      label: Text(
                        'Log Out Completely',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUnlockScreen() {
    // Cancel the session expiry timer while showing the unlock screen
    _sessionTimer?.cancel();

    screenLock(
      context: context,
      title: const Text('Enter PIN to Unlock'),
      // The subtitle parameter is not supported in the current version
      // description: const Text('Enter your PIN to resume your session'),
      customizedButtonChild: const Icon(
        Icons.fingerprint,
        color: Colors.white,
      ),
      customizedButtonTap: _canCheckBiometrics && _isBiometricSupported
          ? () async {
              final authenticated =
                  await _securityProvider.authenticateUser(biometricOnly: true);
              if (authenticated && mounted) {
                // Resume session
                _securityProvider.updateActivity();

                // Navigate to the last active route
                final lastRoute = _navigationProvider.lastActiveRoute;
                Navigator.pop(context); // Close the PIN screen
                Navigator.pushReplacementNamed(context, lastRoute);

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session resumed successfully'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          : null,
      correctString: _correctPin,
      onUnlocked: () {
        // Resume session
        _securityProvider.updateActivity();

        // Navigate to the last active route
        final lastRoute = _navigationProvider.lastActiveRoute;
        Navigator.pushReplacementNamed(context, lastRoute);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session resumed successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      config: ScreenLockConfig(
        backgroundColor: AppTheme.primaryColor,
        buttonStyle: OutlinedButton.styleFrom(
          backgroundColor: Colors.white24,
          foregroundColor: Colors.white,
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      // When the user cancels the PIN entry, restart the session expiry timer
      cancelButton: const Text('Cancel', style: TextStyle(color: Colors.white)),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text(
          'Are you sure you want to log out completely? You will need to log in again to access the application.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Close the dialog first
              Navigator.pop(dialogContext);

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              );

              // Perform logout
              _securityProvider.logout().then((_) {
                // Pop the loading dialog
                if (mounted && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }

                // Navigate to login screen
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              }).catchError((error) {
                // Pop the loading dialog
                if (mounted && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }

                // Show error message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error logging out: ${error.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
