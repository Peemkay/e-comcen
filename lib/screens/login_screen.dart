import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_theme.dart';
import '../constants/app_constants.dart';
import '../constants/security_constants.dart';
import '../services/security_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../widgets/placeholder_logo.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _securityService = SecurityService();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  final bool _supportsBiometrics = false;
  int _loginAttempts = 0;
  bool _isLocked = false;
  DateTime? _lockoutEndTime;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize auth service first
      await _authService.initialize();

      // Then check security status
      await _checkSecurityStatus();
    } catch (e) {
      debugPrint('Error initializing services: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkSecurityStatus() async {
    try {
      // Check if device is secure
      final isDeviceSecure = await _securityService.checkNetworkSecurity();

      if (!isDeviceSecure) {
        if (mounted) {
          _showSecurityWarning(
              'Device security check failed. Please ensure your device is secure.');
        }
      }

      // Check for lockout
      final lockoutEndTimeStr =
          await _securityService.secureRetrieve('lockout_end_time');
      if (lockoutEndTimeStr != null) {
        final lockoutEndTime = DateTime.parse(lockoutEndTimeStr);
        if (DateTime.now().isBefore(lockoutEndTime)) {
          setState(() {
            _isLocked = true;
            _lockoutEndTime = lockoutEndTime;
          });
        } else {
          // Lockout period has ended
          await _securityService.secureDelete('lockout_end_time');
          await _securityService.secureDelete('login_attempts');
        }
      }

      // Get login attempts
      final loginAttemptsStr =
          await _securityService.secureRetrieve('login_attempts');
      if (loginAttemptsStr != null) {
        setState(() {
          _loginAttempts = int.parse(loginAttemptsStr);
        });
      }
    } catch (e) {
      debugPrint('Error checking security status: $e');
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _showSecurityWarning(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Security Warning'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (_isLocked) {
      _showLockoutMessage();
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Sanitize inputs
        final username =
            _securityService.sanitizeInput(_usernameController.text);
        final password = _passwordController.text; // Don't sanitize passwords

        // First check if the user exists but is not approved or active
        final allUsers = await _authService.getUserService().getUsers();
        final matchingUser = allUsers.firstWhere(
          (u) =>
              u.username.toLowerCase() == username.toLowerCase() &&
              u.password == password,
          orElse: () => User(
            id: '',
            name: '',
            username: '',
            password: '',
            rank: '',
            corps: '',
            dateOfBirth: DateTime.now(),
            yearOfEnlistment: 0,
            armyNumber: '',
            unit: '',
          ),
        );

        // Check if user exists but is not approved
        if (matchingUser.id.isNotEmpty &&
            !matchingUser.isApproved &&
            matchingUser.role != UserRole.superadmin) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Your account is pending approval by a Super Administrator. '
                  'Please contact your administrator for assistance.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Check if user exists but is not active
        if (matchingUser.id.isNotEmpty &&
            !matchingUser.isActive &&
            matchingUser.role != UserRole.superadmin) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Your account has been deactivated. '
                  'Please contact your administrator for assistance.',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Try to login using the AuthService
        final user = await _authService.login(username, password);

        if (user != null) {
          // Reset login attempts
          await _securityService.secureStore('login_attempts', '0');

          // Store session information
          final sessionToken = _generateSessionToken();
          await _securityService.secureStore('session_token', sessionToken);
          await _securityService.secureStore(
              'last_activity', DateTime.now().toIso8601String());

          // Show a welcome message with the user's role
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Welcome, ${user.name} (${user.role.displayName})'),
                backgroundColor: Colors.green,
              ),
            );
          }

          // Navigate based on user role and permissions
          if (mounted) {
            if (user.hasPermission(Permission.viewAdmin)) {
              // Users with admin view permission go to admin home
              Navigator.pushReplacementNamed(context, '/home');
            } else if (user.hasPermission(Permission.viewDispatch)) {
              // Users with dispatch view permission but no admin permission go to dispatcher home
              Navigator.pushReplacementNamed(
                  context, AppConstants.dispatcherHomeRoute);
            } else {
              // Users with no permissions show error
              setState(() {
                _errorMessage =
                    'Your account does not have sufficient permissions. Please contact your administrator.';
                _isLoading = false;
              });
              return;
            }
          }
        } else {
          // Increment login attempts
          _loginAttempts++;
          await _securityService.secureStore(
              'login_attempts', _loginAttempts.toString());

          // Check if account should be locked
          if (_loginAttempts >= SecurityConstants.maxLoginAttempts) {
            final lockoutEndTime = DateTime.now().add(
              Duration(minutes: SecurityConstants.lockoutDurationMinutes),
            );
            await _securityService.secureStore(
              'lockout_end_time',
              lockoutEndTime.toIso8601String(),
            );

            setState(() {
              _isLocked = true;
              _lockoutEndTime = lockoutEndTime;
            });

            _showLockoutMessage();
          } else {
            // Show error message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Invalid username or password. ${SecurityConstants.maxLoginAttempts - _loginAttempts} attempts remaining.'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Login error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred during login: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
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
  }

  void _showLockoutMessage() {
    if (_lockoutEndTime == null) return;

    final now = DateTime.now();
    final difference = _lockoutEndTime!.difference(now);
    final minutes = difference.inMinutes;
    final seconds = difference.inSeconds % 60;

    final timeString = '$minutes:${seconds.toString().padLeft(2, '0')}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Account is locked due to too many failed attempts. Try again in $timeString.'),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  String _generateSessionToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final username = _usernameController.text;
    final randomData = _securityService.generateSalt();

    return _securityService.hashPassword(
        '$username:$timestamp:$randomData', randomData);
  }

  void _showRegistrationScreen() {
    // Secret gesture to access registration screen
    // In a real app, this would be more secure
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isVerySmallScreen = screenSize.height < 600;
    final isExtraSmallScreen = screenSize.height < 500;

    // Calculate responsive sizes with better scaling
    final logoSize = isExtraSmallScreen
        ? 80.0
        : isVerySmallScreen
            ? 100.0
            : isSmallScreen
                ? 120.0
                : 150.0;
    final titleFontSize = isExtraSmallScreen
        ? 18.0
        : isVerySmallScreen
            ? 20.0
            : isSmallScreen
                ? 22.0
                : 28.0;
    final subtitleFontSize = isExtraSmallScreen
        ? 14.0
        : isVerySmallScreen
            ? 15.0
            : isSmallScreen
                ? 16.0
                : 18.0;
    final poweredByFontSize = isExtraSmallScreen
        ? 10.0
        : isVerySmallScreen
            ? 11.0
            : isSmallScreen
                ? 12.0
                : 14.0;

    // Calculate responsive spacing with better scaling
    final double verticalSpacing = isExtraSmallScreen
        ? 8.0
        : isVerySmallScreen
            ? 12.0
            : isSmallScreen
                ? 16.0
                : 24.0;
    final double horizontalPadding = isSmallScreen ? 16.0 : 24.0;

    // Calculate form width based on screen size
    final formWidth = screenSize.width > 1200
        ? 450.0
        : screenSize.width > 600
            ? screenSize.width * 0.5
            : screenSize.width * 0.9;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withAlpha(25),
              Colors.white,
              Colors.white,
              AppTheme.secondaryColor.withAlpha(25),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenSize.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalSpacing,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: formWidth,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo and Title
                        GestureDetector(
                          onLongPress:
                              _showRegistrationScreen, // Secret gesture to access registration
                          child: Column(
                            children: [
                              // Logo with responsive size and shadow
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppTheme.primaryColor.withAlpha(75),
                                      blurRadius: 15,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: PlaceholderLogo(
                                  size: logoSize,
                                ),
                              ),
                              SizedBox(height: verticalSpacing),

                              // Title with responsive font size and gradient
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.secondaryColor,
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  'E-COMCEN Admin Login',
                                  style: TextStyle(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors
                                        .white, // This will be replaced by the gradient
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: verticalSpacing * 0.4),

                              // Subtitle with responsive font size
                              Text(
                                'Nigerian Army Signal',
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: verticalSpacing * 0.3),

                              // Powered by text with responsive font size
                              Text(
                                'Powered by NAS',
                                style: TextStyle(
                                  fontSize: poweredByFontSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: verticalSpacing * 1.2),

                        // Login Form
                        Card(
                          elevation: 10,
                          shadowColor: AppTheme.primaryColor.withAlpha(75),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(isExtraSmallScreen
                                ? 16
                                : isVerySmallScreen
                                    ? 18
                                    : isSmallScreen
                                        ? 20
                                        : 30),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Form Title
                                  Text(
                                    'Secure Login',
                                    style: TextStyle(
                                      fontSize: isExtraSmallScreen
                                          ? 16
                                          : isVerySmallScreen
                                              ? 17
                                              : isSmallScreen
                                                  ? 18
                                                  : 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: verticalSpacing * 0.6),

                                  // Username Field
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: InputDecoration(
                                      labelText: 'Username',
                                      hintText: 'Enter your username',
                                      prefixIcon: Icon(
                                        FontAwesomeIcons.userShield,
                                        size: isSmallScreen ? 16 : 18,
                                        color: AppTheme.primaryColor,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: AppTheme.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                          width: 2,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: AppTheme.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your username';
                                      }
                                      return null;
                                    },
                                    textInputAction: TextInputAction.next,
                                  ),
                                  SizedBox(height: verticalSpacing * 0.8),

                                  // Password Field
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      hintText: 'Enter your password',
                                      prefixIcon: Icon(
                                        FontAwesomeIcons.lock,
                                        size: isSmallScreen ? 16 : 18,
                                        color: AppTheme.primaryColor,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? FontAwesomeIcons.eyeSlash
                                              : FontAwesomeIcons.eye,
                                          size: isSmallScreen ? 16 : 18,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: _togglePasswordVisibility,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: AppTheme.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                          width: 2,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: AppTheme.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                    obscureText: _obscurePassword,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _login(),
                                  ),
                                  SizedBox(height: verticalSpacing * 0.8),

                                  // Login Button
                                  SizedBox(
                                    height: isExtraSmallScreen
                                        ? 44
                                        : isVerySmallScreen
                                            ? 48
                                            : isSmallScreen
                                                ? 50
                                                : 56,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        elevation: 5,
                                        shadowColor: AppTheme.primaryColor
                                            .withAlpha(128),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              height: isExtraSmallScreen
                                                  ? 16
                                                  : isVerySmallScreen
                                                      ? 18
                                                      : isSmallScreen
                                                          ? 20
                                                          : 24,
                                              width: isExtraSmallScreen
                                                  ? 16
                                                  : isVerySmallScreen
                                                      ? 18
                                                      : isSmallScreen
                                                          ? 20
                                                          : 24,
                                              child:
                                                  const CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                    FontAwesomeIcons
                                                        .rightToBracket,
                                                    size: isExtraSmallScreen
                                                        ? 14
                                                        : 16),
                                                SizedBox(
                                                    width: isExtraSmallScreen
                                                        ? 8
                                                        : 10),
                                                Text(
                                                  'LOGIN',
                                                  style: TextStyle(
                                                    fontSize: isExtraSmallScreen
                                                        ? 14
                                                        : isVerySmallScreen
                                                            ? 15
                                                            : isSmallScreen
                                                                ? 16
                                                                : 18,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  SizedBox(height: verticalSpacing * 0.6),

                                  // Forgot Password
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        // TODO: Implement forgot password functionality
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Please contact your administrator to reset your password'),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Removed admin credentials hint
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Dispatcher Login Button
                        SizedBox(height: verticalSpacing * 0.8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppConstants.dispatcherLoginRoute,
                            );
                          },
                          icon: Icon(
                            FontAwesomeIcons.truckFast,
                            size: isExtraSmallScreen ? 14 : 16,
                          ),
                          label: Text(
                            'Dispatcher Login',
                            style: TextStyle(
                              fontSize: isExtraSmallScreen
                                  ? 14
                                  : isVerySmallScreen
                                      ? 15
                                      : 16,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: BorderSide(
                                color: AppTheme.primaryColor, width: 2),
                            padding: EdgeInsets.symmetric(
                              vertical: isExtraSmallScreen
                                  ? 10
                                  : isVerySmallScreen
                                      ? 12
                                      : isSmallScreen
                                          ? 14
                                          : 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        // Version information at the bottom
                        SizedBox(height: verticalSpacing * 0.8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FontAwesomeIcons.circleInfo,
                              size: isExtraSmallScreen
                                  ? 10
                                  : isVerySmallScreen
                                      ? 11
                                      : isSmallScreen
                                          ? 12
                                          : 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'v${AppConstants.appVersion} | ${AppConstants.appPlatform}',
                                style: TextStyle(
                                  fontSize: isExtraSmallScreen
                                      ? 10
                                      : isVerySmallScreen
                                          ? 11
                                          : isSmallScreen
                                              ? 12
                                              : 14,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),

                        // Copyright information
                        SizedBox(height: verticalSpacing * 0.4),
                        Text(
                          '© ${DateTime.now().year} Nigerian Army Signal. All rights reserved.',
                          style: TextStyle(
                            fontSize: isExtraSmallScreen
                                ? 8
                                : isVerySmallScreen
                                    ? 9
                                    : isSmallScreen
                                        ? 10
                                        : 12,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
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
    );
  }
}
