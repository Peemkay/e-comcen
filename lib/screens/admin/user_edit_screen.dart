import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_theme.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class UserEditScreen extends StatefulWidget {
  final User? user;

  const UserEditScreen({super.key, this.user});

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
      // Generate a unique ID for new users
      final String userId = _isCreating
          ? 'user_${DateTime.now().millisecondsSinceEpoch}'
          : widget.user!.id;

      // Generate a default unitId if not editing
      final String unitId = _isCreating
          ? 'unit_001' // Default unit ID
          : widget.user!.unitId;

      // Get current date for registration info
      final now = DateTime.now();

      final user = User(
        id: userId,
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
        unitId: unitId,
        role: _selectedRole,
        isActive: _isCreating ? true : widget.user!.isActive,
        isApproved: _isCreating ? false : widget.user!.isApproved,
        registrationDate: _isCreating ? now : widget.user!.registrationDate,
        approvalDate: _isCreating ? null : widget.user!.approvalDate,
        approvedBy: _isCreating ? null : widget.user!.approvedBy,
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

  // Helper method to get role description
  String _getRoleDescription(UserRole role) {
    return switch (role) {
      UserRole.superadmin =>
        'Full access to all system features, including user management and permissions.',
      UserRole.admin =>
        'Administrative access to manage dispatches and users, but cannot modify user privileges.',
      UserRole.dispatcher =>
        'Can create and manage dispatches, but has limited administrative access.',
    };
  }

  // Helper methods to check permission categories
  bool _hasAnyAdminPermission() {
    return (_permissions[Permission.viewAdmin] ?? false) ||
        (_permissions[Permission.manageAdmin] ?? false);
  }

  bool _hasAnyDispatchPermission() {
    return (_permissions[Permission.viewDispatch] ?? false) ||
        (_permissions[Permission.manageDispatch] ?? false);
  }

  bool _hasAnyUserManagementPermission() {
    return (_permissions[Permission.manageUsers] ?? false) ||
        (_permissions[Permission.manageUserPrivileges] ?? false);
  }

  // Build a read-only list of permissions for non-admin users
  Widget _buildPermissionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Admin permissions
        if (_hasAnyAdminPermission()) ...[
          const Text('Admin:', style: TextStyle(fontWeight: FontWeight.bold)),
          if (_permissions[Permission.viewAdmin] ?? false)
            const Text('• View Admin Dashboard'),
          if (_permissions[Permission.manageAdmin] ?? false)
            const Text('• Manage Admin Features'),
          const SizedBox(height: 8),
        ],

        // Dispatch permissions
        if (_hasAnyDispatchPermission()) ...[
          const Text('Dispatch:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          if (_permissions[Permission.viewDispatch] ?? false)
            const Text('• View Dispatch Dashboard'),
          if (_permissions[Permission.manageDispatch] ?? false)
            const Text('• Manage Dispatches'),
          const SizedBox(height: 8),
        ],

        // User management permissions
        if (_hasAnyUserManagementPermission()) ...[
          const Text('User Management:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          if (_permissions[Permission.manageUsers] ?? false)
            const Text('• Manage Users'),
          if (_permissions[Permission.manageUserPrivileges] ?? false)
            const Text('• Manage User Privileges'),
        ],

        // If no permissions
        if (!_hasAnyAdminPermission() &&
            !_hasAnyDispatchPermission() &&
            !_hasAnyUserManagementPermission())
          const Text('No special permissions assigned.'),
      ],
    );
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
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.admin_panel_settings,
                                    color: AppTheme.primaryColor, size: 24),
                                const SizedBox(width: 8),
                                const Text(
                                  'User Role and Permissions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            const SizedBox(height: 8),

                            // Role Selection with description
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'User Role',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child:
                                            DropdownButtonFormField<UserRole>(
                                          value: _selectedRole,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
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
                                                      _updatePermissionsBasedOnRole(
                                                          value);
                                                    });
                                                  }
                                                }
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Role description
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(4),
                                      border:
                                          Border.all(color: Colors.blue[200]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Role: ${_selectedRole.displayName}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                            _getRoleDescription(_selectedRole)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Permissions
                            if (canEditPrivileges) ...[
                              const Text(
                                'Detailed Permissions',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Admin Permissions
                              ExpansionTile(
                                title: Row(
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.userShield,
                                      size: 16,
                                      color: _hasAnyAdminPermission()
                                          ? AppTheme.primaryColor
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Admin Permissions'),
                                  ],
                                ),
                                initiallyExpanded: _hasAnyAdminPermission(),
                                children: [
                                  CheckboxListTile(
                                    title: const Text('View Admin Dashboard'),
                                    subtitle: const Text(
                                        'Access to admin screens and reports'),
                                    value: _permissions[Permission.viewAdmin] ??
                                        false,
                                    onChanged: (value) {
                                      setState(() {
                                        _permissions[Permission.viewAdmin] =
                                            value ?? false;
                                        _updateRoleBasedOnPermissions();
                                      });
                                    },
                                    dense: true,
                                  ),
                                  CheckboxListTile(
                                    title: const Text('Manage Admin Features'),
                                    subtitle: const Text(
                                        'Configure system settings and features'),
                                    value:
                                        _permissions[Permission.manageAdmin] ??
                                            false,
                                    onChanged: (value) {
                                      setState(() {
                                        _permissions[Permission.manageAdmin] =
                                            value ?? false;
                                        _updateRoleBasedOnPermissions();
                                      });
                                    },
                                    dense: true,
                                  ),
                                ],
                              ),

                              // Dispatch Permissions
                              ExpansionTile(
                                title: Row(
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.envelopeCircleCheck,
                                      size: 16,
                                      color: _hasAnyDispatchPermission()
                                          ? AppTheme.primaryColor
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Dispatch Permissions'),
                                  ],
                                ),
                                initiallyExpanded: _hasAnyDispatchPermission(),
                                children: [
                                  CheckboxListTile(
                                    title:
                                        const Text('View Dispatch Dashboard'),
                                    subtitle: const Text(
                                        'Access to dispatch tracking and logs'),
                                    value:
                                        _permissions[Permission.viewDispatch] ??
                                            false,
                                    onChanged: (value) {
                                      setState(() {
                                        _permissions[Permission.viewDispatch] =
                                            value ?? false;
                                        _updateRoleBasedOnPermissions();
                                      });
                                    },
                                    dense: true,
                                  ),
                                  CheckboxListTile(
                                    title: const Text('Manage Dispatches'),
                                    subtitle: const Text(
                                        'Create, edit, and delete dispatches'),
                                    value: _permissions[
                                            Permission.manageDispatch] ??
                                        false,
                                    onChanged: (value) {
                                      setState(() {
                                        _permissions[Permission
                                            .manageDispatch] = value ?? false;
                                        _updateRoleBasedOnPermissions();
                                      });
                                    },
                                    dense: true,
                                  ),
                                ],
                              ),

                              // User Management Permissions
                              ExpansionTile(
                                title: Row(
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.userGear,
                                      size: 16,
                                      color: _hasAnyUserManagementPermission()
                                          ? AppTheme.primaryColor
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('User Management Permissions'),
                                  ],
                                ),
                                initiallyExpanded:
                                    _hasAnyUserManagementPermission(),
                                children: [
                                  CheckboxListTile(
                                    title: const Text('Manage Users'),
                                    subtitle: const Text(
                                        'Create, edit, and delete users'),
                                    value:
                                        _permissions[Permission.manageUsers] ??
                                            false,
                                    onChanged: (value) {
                                      setState(() {
                                        _permissions[Permission.manageUsers] =
                                            value ?? false;
                                        _updateRoleBasedOnPermissions();
                                      });
                                    },
                                    dense: true,
                                  ),
                                  CheckboxListTile(
                                    title: const Text('Manage User Privileges'),
                                    subtitle: const Text(
                                        'Assign roles and permissions to users'),
                                    value: _permissions[
                                            Permission.manageUserPrivileges] ??
                                        false,
                                    onChanged: (value) {
                                      setState(() {
                                        _permissions[Permission
                                                .manageUserPrivileges] =
                                            value ?? false;
                                        _updateRoleBasedOnPermissions();
                                      });
                                    },
                                    dense: true,
                                  ),
                                ],
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.lock, color: Colors.red[400]),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'You do not have permission to edit user privileges. Only users with the Super Admin role can modify permissions.',
                                        style: TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Show current permissions as read-only
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current Permissions (Read-only)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildPermissionsList(),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

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
