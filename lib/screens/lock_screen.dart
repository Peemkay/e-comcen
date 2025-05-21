import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../constants/security_constants.dart';
import '../extensions/string_extensions.dart';
import '../providers/security_provider.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback? onUnlock;

  const LockScreen({
    super.key,
    this.onUnlock,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  // Store the time when the session was locked
  final DateTime _lockedTime = DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Format the locked time
    final formattedTime = DateFormat('HH:mm:ss').format(_lockedTime);

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
                    // App logo with lock icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock_outline,
                          size: 60,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Session timeout title
                    Text(
                      'session_timeout'.tr(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Session timeout message
                    Card(
                      color: Colors.white.withAlpha(25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Main message
                            Text(
                              'session_timeout_message'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),

                            // Detailed message
                            Text(
                              'session_timeout_details'.tr(args: {
                                'minutes': SecurityConstants
                                    .sessionTimeoutMinutes
                                    .toString(),
                              }),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),

                            // Locked time
                            Text(
                              'session_locked_at'.tr(args: {
                                'time': formattedTime,
                              }),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
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
                        elevation: 4,
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
                    const SizedBox(height: 8),

                    // Unlock description
                    Text(
                      'unlock_description'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Logout button
                    OutlinedButton.icon(
                      onPressed: () {
                        _showLogoutConfirmation();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        'logout'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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
      title: Text(
        'unlock_description'.tr(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      // Removed biometric authentication button
      correctString: '000000', // Simple default PIN for easier testing
      maxRetries: 3,
      retryDelay: const Duration(seconds: 3),
      delayBuilder: (context, delay) => Text(
        'Please wait ${delay.inSeconds} seconds before trying again',
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      // Use default keypad styling
      onUnlocked: () {
        // Update activity time and resume session
        securityProvider.updateActivity();

        // Call the onUnlock callback if provided
        if (widget.onUnlock != null) {
          widget.onUnlock!();
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                const Text('Session resumed successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
      config: ScreenLockConfig(
        backgroundColor: AppTheme.primaryColor,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'logout_confirmation_title'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        content: Text(
          'logout_confirmation_message'.tr(),
          style: const TextStyle(fontSize: 16),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: Text(
              'cancel'.tr(),
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Get the security provider
              final securityProvider =
                  Provider.of<SecurityProvider>(context, listen: false);

              // Close the dialog first to avoid context issues
              Navigator.pop(dialogContext);

              // Show loading indicator with a more descriptive message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text('Logging out...'),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );

              // Perform logout
              Future.delayed(const Duration(milliseconds: 500), () async {
                await securityProvider.logout();

                if (mounted) {
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logged out successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );

                  // Exit the app and restart at login screen
                  SystemNavigator.pop();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'logout'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
