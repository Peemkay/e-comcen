import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../constants/security_constants.dart';
import '../extensions/string_extensions.dart';
import '../providers/security_provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({Key? key}) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _isBiometricSupported = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
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

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    try {
      final securityProvider =
          Provider.of<SecurityProvider>(context, listen: false);
      final authenticated =
          await securityProvider.authenticateUser(biometricOnly: true);

      if (authenticated) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      debugPrint('Error authenticating with biometrics: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
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
                    // Logo
                    Image.asset(
                      'assets/images/nasds_logo.png',
                      height: 120,
                    ),
                    const SizedBox(height: 32),

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

                    // Security classification
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
                    const SizedBox(height: 48),

                    // Session timeout message
                    Text(
                      'session_timeout_message'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Unlock button
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
                      ),
                      icon: const Icon(Icons.lock_open),
                      label: Text(
                        'unlock'.tr(),
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
                      TextButton.icon(
                        onPressed: _authenticateWithBiometrics,
                        icon: Icon(
                          _availableBiometrics.contains(BiometricType.face)
                              ? Icons.face
                              : _availableBiometrics
                                      .contains(BiometricType.fingerprint)
                                  ? Icons.fingerprint
                                  : Icons.security,
                          color: Colors.white,
                        ),
                        label: Text(
                          'use_biometrics'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),

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
                        'logout'.tr(),
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
    final securityProvider =
        Provider.of<SecurityProvider>(context, listen: false);

    screenLock(
      context: context,
      title: Text('enter_pin'.tr()),
      // Remove confirmTitle as it's not supported in the current version
      customizedButtonChild: const Icon(
        Icons.fingerprint,
        color: Colors.white,
      ),
      customizedButtonTap: _canCheckBiometrics && _isBiometricSupported
          ? () async {
              final authenticated =
                  await securityProvider.authenticateUser(biometricOnly: true);
              if (authenticated && mounted) {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/home');
              }
            }
          : null,
      correctString: '123456', // This should be retrieved from secure storage
      onUnlocked: () {
        securityProvider.updateActivity();
        Navigator.pushReplacementNamed(context, '/home');
      },
      config: ScreenLockConfig(
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('logout_confirmation_title'.tr()),
        content: Text('logout_confirmation_message'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              final securityProvider =
                  Provider.of<SecurityProvider>(context, listen: false);
              await securityProvider.logout();

              if (mounted) {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('logout'.tr()),
          ),
        ],
      ),
    );
  }
}
