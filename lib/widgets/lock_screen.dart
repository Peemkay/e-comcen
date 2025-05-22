import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nasds/providers/lock_screen_provider.dart';
import 'package:nasds/constants/app_theme.dart';
import 'package:nasds/constants/app_constants.dart';
import 'package:nasds/utils/app_bar_utils.dart';
import 'package:provider/provider.dart';

/// A widget that handles app restart functionality
class RestartWidget extends StatefulWidget {
  final Widget child;

  const RestartWidget({super.key, required this.child});

  static void restartApp(BuildContext context) {
    // Use the global navigator key to ensure we have the correct context
    if (AppBarUtils.navigatorKey.currentContext != null) {
      // Navigate to login screen using the global navigator key
      AppBarUtils.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppConstants.loginRoute,
        (route) => false,
      );
    } else {
      // Fallback to using the provided context
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        AppConstants.loginRoute,
        (route) => false,
      );
    }
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// A widget that displays a lock screen overlay when the app is locked
class LockScreen extends StatefulWidget {
  final Widget child;

  const LockScreen({
    super.key,
    required this.child,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Handle unlock attempt
  Future<void> _handleUnlock() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final lockScreenProvider =
          Provider.of<LockScreenProvider>(context, listen: false);
      final success = await lockScreenProvider.unlockScreen(
        _usernameController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        // Clear the form
        _usernameController.clear();
        _passwordController.clear();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unlocked successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid credentials'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Handle logout
  void _handleLogout() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text(
            'Are you sure you want to logout? This will exit the application.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Close the dialog first
              Navigator.pop(dialogContext);

              // Then perform the logout
              _performLogout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // Perform the actual logout
  void _performLogout() {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // First unlock the screen to prevent state updates after navigation
      final lockScreenProvider =
          Provider.of<LockScreenProvider>(context, listen: false);
      lockScreenProvider.logout();

      // Clear the form
      _usernameController.clear();
      _passwordController.clear();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        // Exit the app completely after a short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          // This will exit the app on all platforms
          SystemNavigator.pop();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LockScreenProvider>(
      builder: (context, lockScreenProvider, _) {
        // If not locked, just show the child
        if (!lockScreenProvider.isLocked) {
          return widget.child;
        }

        // If locked, show the lock screen overlay
        _animationController.forward();

        return Stack(
          children: [
            // The original app content (blurred/dimmed)
            Opacity(
              opacity: 0.3, // Dim the background
              child: AbsorbPointer(
                absorbing: true, // Prevent interaction with background
                child: widget.child,
              ),
            ),

            // Lock screen overlay
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                color: Colors.black45,
                child: Center(
                  child: Card(
                    elevation: 10,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    shadowColor: AppTheme.primaryColor.withAlpha(128),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Lock icon
                              const Icon(
                                FontAwesomeIcons.lock,
                                size: 48,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(height: 16),

                              // Title
                              const Text(
                                'Screen Locked',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Subtitle
                              const Text(
                                'Enter your credentials to unlock',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Username field
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(FontAwesomeIcons.user),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your username';
                                  }
                                  return null;
                                },
                                enabled: !_isLoading,
                              ),
                              const SizedBox(height: 16),

                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(FontAwesomeIcons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showPassword
                                          ? FontAwesomeIcons.eyeSlash
                                          : FontAwesomeIcons.eye,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showPassword = !_showPassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: !_showPassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                                enabled: !_isLoading,
                              ),
                              const SizedBox(height: 24),

                              // Buttons
                              Row(
                                children: [
                                  // Logout button
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(
                                          FontAwesomeIcons.rightFromBracket),
                                      label: const Text('Logout'),
                                      onPressed:
                                          _isLoading ? null : _handleLogout,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Unlock button
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: _isLoading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(FontAwesomeIcons.unlock),
                                      label: Text(_isLoading
                                          ? 'Unlocking...'
                                          : 'Unlock'),
                                      onPressed:
                                          _isLoading ? null : _handleUnlock,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
