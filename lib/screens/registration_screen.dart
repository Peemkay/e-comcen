import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_theme.dart';
import '../constants/app_constants.dart';
import '../constants/army_data.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _armyNumberController = TextEditingController();
  final _emailController = TextEditingController();

  final _authService = AuthService();
  final _localStorageService = LocalStorageService();

  bool _isInitialized = false;

  String? _selectedCorps;
  String? _selectedRank;
  DateTime? _dateOfBirth;
  int? _yearOfEnlistment;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final List<int> _enlistmentYears =
      List.generate(50, (index) => DateTime.now().year - index);

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize auth service first
      await _authService.initialize();

      // Then initialize local storage service
      await _localStorageService.initialize();

      setState(() {
        _isInitialized = true;
      });

      debugPrint('Registration services initialized successfully');
    } catch (e) {
      debugPrint('Error initializing registration services: $e');
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
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _unitController.dispose();
    _armyNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  String? _validateArmyNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Army Number is required';
    }

    // We're using a non-strict validation approach
    // Just check if it contains any valid characters
    if (!isValidArmyNumber(value)) {
      return 'Invalid Army Number format. Please use format like NA/12345 or 20NA/23/123456';
    }

    return null;
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_dateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select date of birth'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      if (_yearOfEnlistment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select year of enlistment'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Check if services are initialized
        if (!_isInitialized) {
          await _initializeServices();

          if (!_isInitialized) {
            throw Exception("Failed to initialize services");
          }
        }

        // Check if username already exists
        final existingUser = await _authService
            .getUserService()
            .getUserByUsername(_usernameController.text);
        if (existingUser != null) {
          throw Exception(
              "Username already exists. Please choose a different username.");
        }

        // Generate a unique ID for the user
        final userId = const Uuid().v4();

        // Create user object
        final user = User(
          id: userId,
          username: _usernameController.text,
          password: _passwordController.text, // Will be hashed by Firebase
          // email is handled separately since it's not in the User model
          name: _nameController.text,
          corps: _selectedCorps!,
          dateOfBirth: _dateOfBirth!,
          yearOfEnlistment: _yearOfEnlistment!,
          unit: _unitController.text,
          unitId: _unitController.text, // Using unit as unitId
          rank: _selectedRank!,
          armyNumber: _armyNumberController.text,
          role: UserRole.admin, // Default to admin role
          isActive: true,
          isApproved: false, // Requires approval by superadmin
          registrationDate: DateTime.now(),
        );

        // Register user using the auth service (which will handle storage)
        try {
          // Use the auth service to register the user
          final registeredUser = await _authService.register(user);

          if (registeredUser != null) {
            debugPrint('User registered successfully: ${user.id}');

            if (mounted) {
              setState(() {
                _isLoading = false;
              });

              // Show success message and navigate back
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Registration successful. Your account requires approval by a Super Administrator.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 5),
                ),
              );

              Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
            }
          } else {
            throw Exception("Registration failed - username may already exist");
          }
        } catch (error) {
          debugPrint('Registration error: $error');

          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            // Show error message with more specific information
            String errorMessage = 'Registration failed';

            if (error.toString().contains('username already exists')) {
              errorMessage =
                  'Username already exists. Please choose a different username.';
            } else if (error.toString().contains('database')) {
              errorMessage = 'Database error. Please try again later.';
            } else {
              errorMessage = 'Registration failed: $error';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Registration error: $e');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: $e'),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Registration'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                const Text(
                  'Create Admin Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please fill in all the required information',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Registration guidance
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withAlpha(76)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registration Guidelines:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Username must be at least 4 characters',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '• Password must be at least 6 characters',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '• All fields are required',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '• New accounts require approval by a Super Administrator',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: AppTheme.inputDecoration(
                    'Username',
                    prefixIcon:
                        const Icon(FontAwesomeIcons.userShield, size: 18),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 4) {
                      return 'Username must be at least 4 characters';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: AppTheme.inputDecoration(
                    'Email',
                    prefixIcon: const Icon(FontAwesomeIcons.envelope, size: 18),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email address';
                    }
                    // More comprehensive email validation
                    final emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  decoration: AppTheme.inputDecoration(
                    'Password',
                    prefixIcon: const Icon(FontAwesomeIcons.lock, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? FontAwesomeIcons.eyeSlash
                            : FontAwesomeIcons.eye,
                        size: 18,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: AppTheme.inputDecoration(
                    'Confirm Password',
                    prefixIcon: const Icon(FontAwesomeIcons.lock, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? FontAwesomeIcons.eyeSlash
                            : FontAwesomeIcons.eye,
                        size: 18,
                      ),
                      onPressed: _toggleConfirmPasswordVisibility,
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: AppTheme.inputDecoration(
                    'Full Name',
                    hint: 'e.g. MI Haruna (officers) or Ayo IH (soldiers)',
                    prefixIcon: const Icon(FontAwesomeIcons.user, size: 18),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Corps Dropdown
                AppTheme.dropdownDecoration(
                  'Corps',
                  _selectedCorps,
                  nigerianArmyCorps,
                  (String? newValue) {
                    setState(() {
                      _selectedCorps = newValue;
                    });
                  },
                  hint: 'Select your corps',
                ),
                const SizedBox(height: 16),

                // Date of Birth
                InkWell(
                  onTap: () => _selectDateOfBirth(context),
                  child: InputDecorator(
                    decoration: AppTheme.inputDecoration(
                      'Date of Birth',
                      prefixIcon:
                          const Icon(FontAwesomeIcons.calendar, size: 18),
                    ),
                    child: Text(
                      _dateOfBirth == null
                          ? 'Select date of birth'
                          : DateFormat('dd MMM yyyy').format(_dateOfBirth!),
                      style: TextStyle(
                        color:
                            _dateOfBirth == null ? Colors.grey : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Year of Enlistment
                DropdownButtonFormField<int>(
                  value: _yearOfEnlistment,
                  decoration: AppTheme.inputDecoration(
                    'Year of Enlistment',
                    prefixIcon:
                        const Icon(FontAwesomeIcons.calendarPlus, size: 18),
                  ),
                  items: _enlistmentYears.map((int year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      _yearOfEnlistment = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select year of enlistment';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Unit
                TextFormField(
                  controller: _unitController,
                  decoration: AppTheme.inputDecoration(
                    'Unit',
                    prefixIcon:
                        const Icon(FontAwesomeIcons.buildingFlag, size: 18),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your unit';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Rank Dropdown
                AppTheme.dropdownDecoration(
                  'Rank',
                  _selectedRank,
                  allRanks,
                  (String? newValue) {
                    setState(() {
                      _selectedRank = newValue;

                      // No longer suggesting sample army numbers in production
                    });
                  },
                  hint: 'Select your rank',
                ),
                const SizedBox(height: 16),

                // Army Number
                TextFormField(
                  controller: _armyNumberController,
                  decoration: AppTheme.inputDecoration(
                    'Army Number',
                    hint: 'e.g. NA/12345 or 20NA/23/123456',
                    prefixIcon: const Icon(FontAwesomeIcons.idCard, size: 18),
                  ),
                  validator: _validateArmyNumber,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 32),

                // Register Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: AppTheme.primaryButtonStyle,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('REGISTER'),
                ),
                const SizedBox(height: 16),

                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
