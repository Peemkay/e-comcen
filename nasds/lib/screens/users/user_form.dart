import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';

class UserForm extends StatefulWidget {
  final User? user;

  const UserForm({super.key, this.user});

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _armyNumberController = TextEditingController();
  final _unitController = TextEditingController();
  
  // Form values
  String _rank = 'Private';
  String _corps = 'Signals';
  DateTime _dateOfBirth = DateTime(1990, 1, 1);
  int _yearOfEnlistment = DateTime.now().year;
  bool _isOfficer = false;
  
  // Lists for dropdowns
  final List<String> _ranks = [
    // Non-commissioned ranks
    'Private',
    'Lance Corporal',
    'Corporal',
    'Sergeant',
    'Staff Sergeant',
    'Warrant Officer',
    // Commissioned ranks
    'Second Lieutenant',
    'Lieutenant',
    'Captain',
    'Major',
    'Lieutenant Colonel',
    'Colonel',
    'Brigadier General',
    'Major General',
    'Lieutenant General',
    'General',
  ];
  
  final List<String> _corpsOptions = [
    'Signals',
    'Infantry',
    'Artillery',
    'Armour',
    'Engineers',
    'Supply and Transport',
    'Medical',
    'Military Police',
    'Intelligence',
    'Education',
    'Finance',
    'Chaplaincy',
    'Legal',
    'Electrical and Mechanical Engineers',
  ];
  
  bool _isEditing = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.user != null;
    
    if (_isEditing) {
      // Populate form with existing user data
      _nameController.text = widget.user!.name;
      _usernameController.text = widget.user!.username;
      _armyNumberController.text = widget.user!.armyNumber;
      _unitController.text = widget.user!.unit;
      
      _rank = widget.user!.rank;
      _corps = widget.user!.corps;
      _dateOfBirth = widget.user!.dateOfBirth;
      _yearOfEnlistment = widget.user!.yearOfEnlistment;
      
      // Determine if officer based on rank
      _isOfficer = _isOfficerRank(_rank);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _armyNumberController.dispose();
    _unitController.dispose();
    super.dispose();
  }
  
  bool _isOfficerRank(String rank) {
    final officerRanks = [
      'Second Lieutenant',
      'Lieutenant',
      'Captain',
      'Major',
      'Lieutenant Colonel',
      'Colonel',
      'Brigadier General',
      'Major General',
      'Lieutenant General',
      'General',
    ];
    return officerRanks.contains(rank);
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Must be at least 18 years old
    );
    
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }
  
  String? _validateArmyNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an Army Number';
    }
    
    if (_isOfficer) {
      // Officer format: NA/12345
      final officerRegex = RegExp(r'^NA\/\d{5}$');
      if (!officerRegex.hasMatch(value)) {
        return 'Officer Army Number must be in format NA/12345';
      }
    } else {
      // Soldier format: 12NA/34/5678
      final soldierRegex = RegExp(r'^\d{2}NA\/\d{2}\/\d{4}$');
      if (!soldierRegex.hasMatch(value)) {
        return 'Soldier Army Number must be in format 12NA/34/5678';
      }
    }
    
    return null;
  }
  
  String? _validatePassword(String? value) {
    if (!_isEditing && (value == null || value.isEmpty)) {
      return 'Please enter a password';
    }
    
    if (value != null && value.isNotEmpty && value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
  
  String? _validateConfirmPassword(String? value) {
    if (!_isEditing && (value == null || value.isEmpty)) {
      return 'Please confirm your password';
    }
    
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  void _saveUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Create user object
        final user = User(
          id: _isEditing ? widget.user!.id : DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          username: _usernameController.text,
          password: _passwordController.text.isEmpty && _isEditing 
              ? widget.user!.password 
              : _passwordController.text,
          rank: _rank,
          corps: _corps,
          dateOfBirth: _dateOfBirth,
          yearOfEnlistment: _yearOfEnlistment,
          armyNumber: _armyNumberController.text,
          unit: _unitController.text,
        );
        
        // Save to service
        if (_isEditing) {
          await _userService.updateUser(user);
        } else {
          await _userService.addUser(user);
        }
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          // Show success message and navigate back
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'User updated successfully' : 'User added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
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
        title: Text(_isEditing ? 'Edit User' : 'New User'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.user, size: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Username
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.userTag, size: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: _isEditing ? 'New Password (leave blank to keep current)' : 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(FontAwesomeIcons.lock, size: 16),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                      size: 16,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              
              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(FontAwesomeIcons.lock, size: 16),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                      size: 16,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 16),
              
              // Rank
              DropdownButtonFormField<String>(
                value: _rank,
                decoration: const InputDecoration(
                  labelText: 'Rank',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.medal, size: 16),
                ),
                items: _ranks.map((String rank) {
                  return DropdownMenuItem<String>(
                    value: rank,
                    child: Text(rank),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _rank = newValue!;
                    _isOfficer = _isOfficerRank(_rank);
                    
                    // Clear army number if officer status changes
                    if (_armyNumberController.text.isNotEmpty) {
                      _armyNumberController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Corps
              DropdownButtonFormField<String>(
                value: _corps,
                decoration: const InputDecoration(
                  labelText: 'Corps',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.shieldHalved, size: 16),
                ),
                items: _corpsOptions.map((String corps) {
                  return DropdownMenuItem<String>(
                    value: corps,
                    child: Text(corps),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _corps = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Date of Birth
              InkWell(
                onTap: () => _selectDateOfBirth(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(FontAwesomeIcons.cakeCandles, size: 16),
                  ),
                  child: Text(
                    DateFormat('dd MMM yyyy').format(_dateOfBirth),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Year of Enlistment
              TextFormField(
                initialValue: _yearOfEnlistment.toString(),
                decoration: const InputDecoration(
                  labelText: 'Year of Enlistment',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.calendarDay, size: 16),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter year of enlistment';
                  }
                  
                  final year = int.tryParse(value);
                  if (year == null) {
                    return 'Please enter a valid year';
                  }
                  
                  if (year < 1960 || year > DateTime.now().year) {
                    return 'Please enter a valid year between 1960 and ${DateTime.now().year}';
                  }
                  
                  return null;
                },
                onChanged: (value) {
                  final year = int.tryParse(value);
                  if (year != null) {
                    setState(() {
                      _yearOfEnlistment = year;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Army Number
              TextFormField(
                controller: _armyNumberController,
                decoration: InputDecoration(
                  labelText: 'Army Number',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(FontAwesomeIcons.idCard, size: 16),
                  helperText: _isOfficer 
                      ? 'Format: NA/12345 (for officers)' 
                      : 'Format: 12NA/34/5678 (for soldiers)',
                ),
                validator: _validateArmyNumber,
              ),
              const SizedBox(height: 16),
              
              // Unit
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.buildingUser, size: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a unit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isEditing ? 'Update User' : 'Save User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
