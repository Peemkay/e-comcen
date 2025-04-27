import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../constants/army_data.dart';
import '../extensions/string_extensions.dart';
import '../models/admin_user.dart';
import '../providers/translation_provider.dart';

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
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _unitController.dispose();
    _armyNumberController.dispose();
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
      return '${'army_number'.tr()} ${'is_required'.tr()}';
    }

    // We're using a non-strict validation approach
    // Just check if it contains any valid characters
    if (!isValidArmyNumber(value)) {
      return 'invalid_army_number'.tr();
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

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Create admin user object
      final adminUser = AdminUser(
        username: _usernameController.text,
        password:
            _passwordController.text, // In a real app, this should be hashed
        name: _nameController.text,
        corps: _selectedCorps!,
        dateOfBirth: _dateOfBirth!,
        yearOfEnlistment: _yearOfEnlistment!,
        unit: _unitController.text,
        rank: _selectedRank!,
        armyNumber: _armyNumberController.text,
      );

      // TODO: Save the admin user to a database or shared preferences
      // For now, we'll just print the details
      debugPrint('Registered admin user: ${adminUser.toMap()}');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
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
                const SizedBox(height: 32),

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

                      // Suggest army number format based on rank
                      if (newValue != null &&
                          _armyNumberController.text.isEmpty) {
                        _armyNumberController.text =
                            generateSampleArmyNumber(newValue);
                      }
                    });
                  },
                  hint: 'Select your rank',
                ),
                const SizedBox(height: 16),

                // Army Number
                TextFormField(
                  controller: _armyNumberController,
                  decoration: AppTheme.inputDecoration(
                    'army_number'.tr(),
                    hint: 'army_number_hint'.tr(),
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
