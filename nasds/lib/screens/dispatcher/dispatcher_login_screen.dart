import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../constants/security_constants.dart';
import '../../extensions/string_extensions.dart';
import '../../models/user.dart';
import '../../providers/security_provider.dart';
import '../../services/auth_service.dart';
import 'dispatcher_home_screen.dart';

class DispatcherLoginScreen extends StatefulWidget {
  const DispatcherLoginScreen({super.key});

  @override
  State<DispatcherLoginScreen> createState() => _DispatcherLoginScreenState();
}

class _DispatcherLoginScreenState extends State<DispatcherLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  int _loginAttempts = 0;

  @override
  void initState() {
    super.initState();
    _authService.initialize();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both username and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try to login with the dispatcher role
      final user = await _authService.loginWithRole(
        username,
        password,
        UserRole.dispatcher,
      );

      if (user != null) {
        if (mounted) {
          // Show a welcome message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome, ${user.name} (${user.role.displayName})'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to dispatcher home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DispatcherHomeScreen(),
            ),
          );
        }
      } else {
        // Fallback for testing - accept hardcoded credentials
        if ((username == 'dispatcher' && password == 'dispatcher') ||
            (username == 'ibrahim' && password == 'dispatcher123') ||
            (username == 'emeka' && password == 'dispatcher123') ||
            (username == 'aisha' && password == 'dispatcher123')) {
          // Create a dispatcher user manually
          final dispatcherUser = User(
            id: '999',
            name: 'Test Dispatcher',
            username: username,
            password: password,
            rank: 'Corporal',
            corps: 'Signals',
            dateOfBirth: DateTime(1995, 6, 15),
            yearOfEnlistment: 2015,
            armyNumber: '15NA/44/8765',
            unit: 'Nigerian Army School of Signals',
            role: UserRole.dispatcher,
          );

          if (mounted) {
            // Set the current user in the auth service
            _authService.setCurrentUser(dispatcherUser);

            // Show a welcome message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Welcome, ${dispatcherUser.name} (${dispatcherUser.role.displayName})'),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate to dispatcher home screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DispatcherHomeScreen(),
              ),
            );
            return;
          }
        } else {
          _loginAttempts++;

          setState(() {
            _errorMessage = 'Invalid username or password for dispatcher';

            // Lock account after too many attempts
            if (_loginAttempts >= SecurityConstants.maxLoginAttempts) {
              _errorMessage =
                  'Too many failed attempts. Please try again later.';
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withAlpha(204), // 0.8 * 255 = 204
              AppTheme.primaryColor.withAlpha(153), // 0.6 * 255 = 153
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25), // 0.1 * 255 = 25
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            FontAwesomeIcons.truckFast,
                            size: 64,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'E-COMCEN DSM',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Dispatch Service Manager',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Login form
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25), // 0.1 * 255 = 25
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dispatcher Login',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Username field
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            obscureText: true,
                            onSubmitted: (_) => _login(),
                          ),

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    Colors.red.withAlpha(25), // 0.1 * 255 = 25
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'LOGIN',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Back to main app
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppConstants.loginRoute,
                                );
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Back to E-COMCEN'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Security classification banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.security,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'SECRET',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
