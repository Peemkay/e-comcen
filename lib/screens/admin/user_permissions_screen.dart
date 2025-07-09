import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../constants/app_theme.dart';
import '../../widgets/loading_indicator.dart';

/// Screen for managing user permissions
class UserPermissionsScreen extends StatefulWidget {
  final User user;

  const UserPermissionsScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<UserPermissionsScreen> createState() => _UserPermissionsScreenState();
}

class _UserPermissionsScreenState extends State<UserPermissionsScreen> {
  final _authService = AuthService();
  late Map<Permission, bool> _permissions;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  void _loadPermissions() {
    // Start with the user's current permissions
    _permissions = widget.user.getAllPermissions();
  }

  Future<void> _savePermissions() async {
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if current user has permission to manage user privileges
      if (!_authService.hasPermission(Permission.manageUserPrivileges)) {
        setState(() {
          _errorMessage =
              'You do not have permission to manage user privileges';
          _isLoading = false;
        });
        return;
      }

      // Update user permissions
      final success = await _authService.updateUserPermissions(
        widget.user.id,
        _permissions,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User permissions updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return success
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to update user permissions';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPermissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if current user has permission to manage user privileges
      if (!_authService.hasPermission(Permission.manageUserPrivileges)) {
        setState(() {
          _errorMessage =
              'You do not have permission to manage user privileges';
          _isLoading = false;
        });
        return;
      }

      // Reset user permissions to role defaults
      final success = await _authService.resetUserPermissions(widget.user.id);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User permissions reset to role defaults'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return success
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to reset user permissions';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildPermissionCategory(String title, List<Permission> permissions) {
    return ExpansionTile(
      title: Text(title),
      children: permissions.map((permission) {
        return CheckboxListTile(
          title: Text(_getPermissionTitle(permission)),
          subtitle: Text(_getPermissionDescription(permission)),
          value: _permissions[permission] ?? false,
          onChanged: (value) {
            setState(() {
              _permissions[permission] = value ?? false;
              _hasChanges = true;
            });
          },
          dense: true,
        );
      }).toList(),
    );
  }

  String _getPermissionTitle(Permission permission) {
    switch (permission) {
      // Admin permissions
      case Permission.viewAdmin:
        return 'View Admin Dashboard';
      case Permission.manageAdmin:
        return 'Manage Admin Features';

      // Dispatch permissions
      case Permission.viewDispatch:
        return 'View Dispatches';
      case Permission.createDispatch:
        return 'Create Dispatches';
      case Permission.editDispatch:
        return 'Edit Dispatches';
      case Permission.deleteDispatch:
        return 'Delete Dispatches';
      case Permission.manageDispatch:
        return 'Manage All Dispatches';

      // User management permissions
      case Permission.viewUsers:
        return 'View Users';
      case Permission.createUser:
        return 'Create Users';
      case Permission.editUser:
        return 'Edit Users';
      case Permission.deleteUser:
        return 'Delete Users';
      case Permission.manageUsers:
        return 'Manage All Users';
      case Permission.manageUserPrivileges:
        return 'Manage User Privileges';

      // Report permissions
      case Permission.viewReports:
        return 'View Reports';
      case Permission.generateReports:
        return 'Generate Reports';
      case Permission.exportReports:
        return 'Export Reports';

      // Unit management permissions
      case Permission.viewUnits:
        return 'View Units';
      case Permission.manageUnits:
        return 'Manage Units';

      // System settings permissions
      case Permission.viewSettings:
        return 'View Settings';
      case Permission.manageSettings:
        return 'Manage Settings';

      // Security permissions
      case Permission.viewSecurityLogs:
        return 'View Security Logs';
      case Permission.manageSecuritySettings:
        return 'Manage Security Settings';
    }
  }

  String _getPermissionDescription(Permission permission) {
    switch (permission) {
      // Admin permissions
      case Permission.viewAdmin:
        return 'Access to admin screens and reports';
      case Permission.manageAdmin:
        return 'Configure system settings and features';

      // Dispatch permissions
      case Permission.viewDispatch:
        return 'View dispatch details and listings';
      case Permission.createDispatch:
        return 'Create new dispatches';
      case Permission.editDispatch:
        return 'Edit existing dispatches';
      case Permission.deleteDispatch:
        return 'Delete dispatches';
      case Permission.manageDispatch:
        return 'Full control over all dispatch operations';

      // User management permissions
      case Permission.viewUsers:
        return 'View user details and listings';
      case Permission.createUser:
        return 'Create new users';
      case Permission.editUser:
        return 'Edit existing users';
      case Permission.deleteUser:
        return 'Delete users';
      case Permission.manageUsers:
        return 'Full control over user management';
      case Permission.manageUserPrivileges:
        return 'Assign roles and permissions to users';

      // Report permissions
      case Permission.viewReports:
        return 'View system reports';
      case Permission.generateReports:
        return 'Generate new reports';
      case Permission.exportReports:
        return 'Export reports to files';

      // Unit management permissions
      case Permission.viewUnits:
        return 'View unit details and listings';
      case Permission.manageUnits:
        return 'Create, edit, and delete units';

      // System settings permissions
      case Permission.viewSettings:
        return 'View system settings';
      case Permission.manageSettings:
        return 'Modify system settings';

      // Security permissions
      case Permission.viewSecurityLogs:
        return 'View security logs and events';
      case Permission.manageSecuritySettings:
        return 'Configure security settings';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Permissions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _savePermissions,
            tooltip: 'Save Permissions',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Reset Permissions'),
                        content: const Text(
                            'This will reset all permissions to the defaults for this user\'s role. '
                            'Are you sure you want to continue?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _resetPermissions();
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                  },
            tooltip: 'Reset to Role Defaults',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _buildPermissionsForm(),
    );
  }

  Widget _buildPermissionsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Username: ${widget.user.username}'),
                  Text('Role: ${widget.user.role.displayName}'),
                  Text(
                      'Status: ${widget.user.isActive ? "Active" : "Inactive"}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
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

          // Permissions sections
          const Text(
            'Permissions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Admin permissions
          _buildPermissionCategory(
            'Admin Permissions',
            [Permission.viewAdmin, Permission.manageAdmin],
          ),

          // Dispatch permissions
          _buildPermissionCategory(
            'Dispatch Permissions',
            [
              Permission.viewDispatch,
              Permission.createDispatch,
              Permission.editDispatch,
              Permission.deleteDispatch,
              Permission.manageDispatch,
            ],
          ),

          // User management permissions
          _buildPermissionCategory(
            'User Management Permissions',
            [
              Permission.viewUsers,
              Permission.createUser,
              Permission.editUser,
              Permission.deleteUser,
              Permission.manageUsers,
              Permission.manageUserPrivileges,
            ],
          ),

          // Report permissions
          _buildPermissionCategory(
            'Report Permissions',
            [
              Permission.viewReports,
              Permission.generateReports,
              Permission.exportReports,
            ],
          ),

          // Unit management permissions
          _buildPermissionCategory(
            'Unit Management Permissions',
            [Permission.viewUnits, Permission.manageUnits],
          ),

          // System settings permissions
          _buildPermissionCategory(
            'System Settings Permissions',
            [Permission.viewSettings, Permission.manageSettings],
          ),

          // Security permissions
          _buildPermissionCategory(
            'Security Permissions',
            [
              Permission.viewSecurityLogs,
              Permission.manageSecuritySettings,
            ],
          ),
        ],
      ),
    );
  }
}
