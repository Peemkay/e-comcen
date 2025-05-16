import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_theme.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class UserEditScreen extends StatefulWidget {
  final User? user;

  const UserEditScreen({Key? key, this.user}) : super(key: key);

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rankController = TextEditingController();
  final _corpsController = TextEditingController();
  final _armyNumberController = TextEditingController();
  final _unitController = TextEditingController();

  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  DateTime _dateOfBirth = DateTime(1990);
  int _yearOfEnlistment = DateTime.now().year - 5;
  UserRole _selectedRole = UserRole.dispatcher;

  bool _isLoading = false;
  bool _isCreating = true;
  bool _showPassword = false;
  String? _errorMessage;

  // Map to track which permissions are enabled for this user
  final Map<Permission, bool> _permissions = {};

  @override
  void initState() {
    super.initState();
    _isCreating = widget.user == null;

    if (!_isCreating) {
      // Editing existing user
      _nameController.text = widget.user!.name;
      _usernameController.text = widget.user!.username;
      _rankController.text = widget.user!.rank;
      _corpsController.text = widget.user!.corps;
      _armyNumberController.text = widget.user!.armyNumber;
      _unitController.text = widget.user!.unit;
      _dateOfBirth = widget.user!.dateOfBirth;
      _yearOfEnlistment = widget.user!.yearOfEnlistment;
      _selectedRole = widget.user!.role;

      // Initialize permissions based on role
      for (var permission in Permission.values) {
        _permissions[permission] = widget.user!.role.hasPermission(permission);
      }
    } else {
      // Creating new user - set default values
      _corpsController.text = 'Signals';
      _unitController.text = 'Nigerian Army School of Signals';

      // Initialize permissions based on default role
      for (var permission in Permission.values) {
        _permissions[permission] = _selectedRole.hasPermission(permission);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _rankController.dispose();
    _corpsController.dispose();
    _armyNumberController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if current user has permission to manage users
    if (!_authService.hasPermission(Permission.manageUsers)) {
      setState(() {
        _errorMessage = 'You do not have permission to manage users';
      });
      return;
    }

    // Check if current user has permission to manage privileges
    // Only super admins can change roles and permissions
    if (_isCreating || _selectedRole != widget.user?.role) {
      if (!_authService.hasPermission(Permission.manageUserPrivileges)) {
        setState(() {
          _errorMessage = 'You do not have permission to change user roles';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = User(
        id: _isCreating ? '' : widget.user!.id,
        name: _nameController.text,
        username: _usernameController.text,
        password: _passwordController.text.isEmpty && !_isCreating
            ? widget.user!.password
            : _passwordController.text,
        rank: _rankController.text,
        corps: _corpsController.text,
        dateOfBirth: _dateOfBirth,
        yearOfEnlistment: _yearOfEnlistment,
        armyNumber: _armyNumberController.text,
        unit: _unitController.text,
        role: _selectedRole,
      );

      if (_isCreating) {
        await _userService.addUser(user);
      } else {
        await _userService.updateUser(user);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isCreating
                  ? 'User created successfully'
                  : 'User updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving user: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _updateRoleBasedOnPermissions() {
    // If all permissions are granted, set role to superadmin
    bool hasAllPermissions =
        Permission.values.every((p) => _permissions[p] == true);
    if (hasAllPermissions) {
      setState(() {
        _selectedRole = UserRole.superadmin;
      });
      return;
    }

    // If has admin permissions but not privilege management, set role to admin
    bool hasAdminPermissions = _permissions[Permission.viewAdmin] == true &&
        _permissions[Permission.manageAdmin] == true &&
        _permissions[Permission.viewDispatch] == true &&
        _permissions[Permission.manageDispatch] == true &&
        _permissions[Permission.manageUsers] == true;

    if (hasAdminPermissions &&
        _permissions[Permission.manageUserPrivileges] != true) {
      setState(() {
        _selectedRole = UserRole.admin;
      });
      return;
    }

    // If only has dispatch permissions, set role to dispatcher
    bool hasOnlyDispatchPermissions =
        _permissions[Permission.viewDispatch] == true &&
            _permissions[Permission.manageDispatch] == true &&
            _permissions[Permission.viewAdmin] != true &&
            _permissions[Permission.manageAdmin] != true &&
            _permissions[Permission.manageUsers] != true &&
            _permissions[Permission.manageUserPrivileges] != true;

    if (hasOnlyDispatchPermissions) {
      setState(() {
        _selectedRole = UserRole.dispatcher;
      });
      return;
    }

    // If custom permissions that don't match a role, keep current role
  }

  void _updatePermissionsBasedOnRole(UserRole role) {
    // Update permissions based on the selected role
    for (var permission in Permission.values) {
      _permissions[permission] = role.hasPermission(permission);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canEditPrivileges =
        _authService.hasPermission(Permission.manageUserPrivileges);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreating ? 'Create User' : 'Edit User'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveUser,
            tooltip: 'Save',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(25), // 0.1 * 255 = 25
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Basic Information Section
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
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
                        prefixIcon: Icon(Icons.account_circle),
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
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: _isCreating
                            ? 'Password'
                            : 'New Password (leave blank to keep current)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (_isCreating && (value == null || value.isEmpty)) {
                          return 'Please enter a password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Military Information Section
                    const Text(
                      'Military Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rank
                    TextFormField(
                      controller: _rankController,
                      decoration: const InputDecoration(
                        labelText: 'Rank',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(FontAwesomeIcons.medal),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a rank';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Corps
                    TextFormField(
                      controller: _corpsController,
                      decoration: const InputDecoration(
                        labelText: 'Corps',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(FontAwesomeIcons.shieldHalved),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a corps';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Army Number
                    TextFormField(
                      controller: _armyNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Army Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(FontAwesomeIcons.idCard),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an army number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Unit
                    TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(FontAwesomeIcons.buildingFlag),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a unit';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text('Date of Birth:'),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _dateOfBirth,
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _dateOfBirth = date;
                              });
                            }
                          },
                          child: Text(
                            '${_dateOfBirth.day}/${_dateOfBirth.month}/${_dateOfBirth.year}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Year of Enlistment
                    Row(
                      children: [
                        const Icon(Icons.military_tech, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text('Year of Enlistment:'),
                        const SizedBox(width: 16),
                        DropdownButton<int>(
                          value: _yearOfEnlistment,
                          items: List.generate(
                            50,
                            (index) => DropdownMenuItem(
                              value: DateTime.now().year - index,
                              child: Text('${DateTime.now().year - index}'),
                            ),
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _yearOfEnlistment = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Role and Permissions Section
                    const Text(
                      'Role and Permissions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Role Selection
                    Row(
                      children: [
                        const Icon(Icons.admin_panel_settings,
                            color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text('User Role:'),
                        const SizedBox(width: 16),
                        DropdownButton<UserRole>(
                          value: _selectedRole,
                          items: UserRole.values.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role.displayName),
                            );
                          }).toList(),
                          onChanged: canEditPrivileges
                              ? (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedRole = value;
                                      _updatePermissionsBasedOnRole(value);
                                    });
                                  }
                                }
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Permissions
                    if (canEditPrivileges) ...[
                      const Text(
                        'Permissions:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Admin Permissions
                      const Text('Admin Permissions:'),
                      CheckboxListTile(
                        title: const Text('View Admin Dashboard'),
                        value: _permissions[Permission.viewAdmin] ?? false,
                        onChanged: (value) {
                          setState(() {
                            _permissions[Permission.viewAdmin] = value ?? false;
                            _updateRoleBasedOnPermissions();
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Manage Admin Features'),
                        value: _permissions[Permission.manageAdmin] ?? false,
                        onChanged: (value) {
                          setState(() {
                            _permissions[Permission.manageAdmin] =
                                value ?? false;
                            _updateRoleBasedOnPermissions();
                          });
                        },
                      ),

                      // Dispatch Permissions
                      const Text('Dispatch Permissions:'),
                      CheckboxListTile(
                        title: const Text('View Dispatch Dashboard'),
                        value: _permissions[Permission.viewDispatch] ?? false,
                        onChanged: (value) {
                          setState(() {
                            _permissions[Permission.viewDispatch] =
                                value ?? false;
                            _updateRoleBasedOnPermissions();
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Manage Dispatches'),
                        value: _permissions[Permission.manageDispatch] ?? false,
                        onChanged: (value) {
                          setState(() {
                            _permissions[Permission.manageDispatch] =
                                value ?? false;
                            _updateRoleBasedOnPermissions();
                          });
                        },
                      ),

                      // User Management Permissions
                      const Text('User Management Permissions:'),
                      CheckboxListTile(
                        title: const Text('Manage Users'),
                        value: _permissions[Permission.manageUsers] ?? false,
                        onChanged: (value) {
                          setState(() {
                            _permissions[Permission.manageUsers] =
                                value ?? false;
                            _updateRoleBasedOnPermissions();
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Manage User Privileges'),
                        value: _permissions[Permission.manageUserPrivileges] ??
                            false,
                        onChanged: (value) {
                          setState(() {
                            _permissions[Permission.manageUserPrivileges] =
                                value ?? false;
                            _updateRoleBasedOnPermissions();
                          });
                        },
                      ),
                    ] else ...[
                      const Text(
                        'You do not have permission to edit user privileges.',
                        style: TextStyle(
                          color: Colors.red,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _isCreating ? 'Create User' : 'Update User',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
