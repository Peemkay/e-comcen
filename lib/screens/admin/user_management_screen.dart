
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_theme.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../extensions/string_extensions.dart';
import 'user_edit_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  List<User> _users = [];
  List<User> _pendingApprovalUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showPendingOnly = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if current user has permission to manage users
      if (!_authService.hasPermission(Permission.manageUsers)) {
        setState(() {
          _errorMessage = 'You do not have permission to manage users';
          _isLoading = false;
        });
        return;
      }

      // Load all users from the service (this will refresh from storage)
      final allUsers = await _userService.getUsers();

      // Separate pending approval users
      final pendingUsers = allUsers.where((user) => !user.isApproved).toList();

      // Filter users based on the current view mode
      final filteredUsers = _showPendingOnly ? pendingUsers : allUsers;

      setState(() {
        _users = filteredUsers;
        _pendingApprovalUsers = pendingUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading users: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _togglePendingOnlyView() {
    setState(() {
      _showPendingOnly = !_showPendingOnly;
    });
    _loadUsers();
  }

  Future<void> _deleteUser(User user) async {
    // Don't allow deleting yourself
    if (user.id == _authService.currentUser?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete your own account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.deleteUser(user.id);
      await _loadUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${user.name} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting user: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _editUser(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserEditScreen(user: user),
      ),
    ).then((_) => _loadUsers());
  }

  void _createUser() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserEditScreen(),
      ),
    ).then((_) => _loadUsers());
  }

  Future<void> _approveUser(User user) async {
    // Only super admin can approve users
    if (!_authService.isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only Super Administrators can approve users'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirm approval
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Approval'),
        content: Text('Are you sure you want to approve ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.approveUser(user.id);
      await _loadUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${user.name} approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error approving user: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleUserActiveStatus(User user, bool newStatus) async {
    // Only super admin can toggle user active status
    if (!_authService.isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Only Super Administrators can activate/deactivate users'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Don't allow deactivating yourself
    if (user.id == _authService.currentUser?.id && !newStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot deactivate your own account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirm status change
    final action = newStatus ? 'activate' : 'deactivate';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm ${action.capitalize()}'),
        content: Text('Are you sure you want to $action ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: newStatus ? Colors.green : Colors.orange,
            ),
            child: Text(action.capitalize()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.toggleUserActiveStatus(user.id, newStatus);
      await _loadUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'User ${user.name} ${newStatus ? 'activated' : 'deactivated'} successfully'),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating user status: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _getRoleChipColor(UserRole role) {
    switch (role) {
      case UserRole.superadmin:
        return '#FF5722'; // Deep Orange
      case UserRole.admin:
        return '#2196F3'; // Blue
      case UserRole.dispatcher:
        return '#4CAF50'; // Green
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          // Toggle between all users and pending approval users
          if (_authService.isSuperAdmin)
            IconButton(
              icon: Icon(_showPendingOnly
                  ? FontAwesomeIcons.userCheck
                  : FontAwesomeIcons.userClock),
              onPressed: _togglePendingOnlyView,
              tooltip:
                  _showPendingOnly ? 'Show All Users' : 'Show Pending Approval',
            ),
          // Badge showing number of pending approvals
          if (_authService.isSuperAdmin &&
              _pendingApprovalUsers.isNotEmpty &&
              !_showPendingOnly)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(FontAwesomeIcons.bell),
                    onPressed: () => _togglePendingOnlyView(),
                    tooltip: 'Pending Approvals',
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${_pendingApprovalUsers.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createUser,
        backgroundColor: AppTheme.primaryColor,
        tooltip: 'Add User',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        // Determine card color based on user status
                        final cardColor = !user.isApproved
                            ? Colors.orange[50] // Pending approval
                            : !user.isActive
                                ? Colors.grey[100] // Inactive
                                : Colors.white; // Active

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          elevation: 2,
                          color: cardColor,
                          child: Column(
                            children: [
                              // Status banner for pending approval or inactive users
                              if (!user.isApproved || !user.isActive)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 16,
                                  ),
                                  color: !user.isApproved
                                      ? Colors.orange
                                      : Colors.grey,
                                  child: Text(
                                    !user.isApproved
                                        ? 'Pending Approval'
                                        : 'Inactive Account',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: user.isActive
                                      ? AppTheme.primaryColor
                                      : Colors.grey,
                                  child: Text(
                                    user.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(child: Text(user.name)),
                                    if (user.isApproved &&
                                        user.approvalDate != null)
                                      Tooltip(
                                        message:
                                            'Approved by ${user.approvedBy} on ${_formatDate(user.approvalDate!)}',
                                        child: const Icon(
                                          Icons.verified,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Username: ${user.username}'),
                                    const SizedBox(height: 4),
                                    Text('Army Number: ${user.armyNumber}'),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(int.parse(
                                                    _getRoleChipColor(user.role)
                                                        .substring(1, 7),
                                                    radix: 16) +
                                                0xFF000000),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            user.role.displayName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Rank: ${user.rank}'),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Unit: ${user.unit}'),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        user.registrationDate != null
                                            ? 'Registered: ${_formatDate(user.registrationDate!)}'
                                            : 'Registration date unknown',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Approve button (only for super admin and unapproved users)
                                    if (_authService.isSuperAdmin &&
                                        !user.isApproved)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        onPressed: () => _approveUser(user),
                                        tooltip: 'Approve User',
                                      ),

                                    // Toggle active status (only for super admin)
                                    if (_authService.isSuperAdmin &&
                                        user.role != UserRole.superadmin)
                                      IconButton(
                                        icon: Icon(
                                          user.isActive
                                              ? Icons.toggle_on
                                              : Icons.toggle_off,
                                          color: user.isActive
                                              ? Colors.green
                                              : Colors.grey,
                                          size: 28,
                                        ),
                                        onPressed: () =>
                                            _toggleUserActiveStatus(
                                          user,
                                          !user.isActive,
                                        ),
                                        tooltip: user.isActive
                                            ? 'Deactivate User'
                                            : 'Activate User',
                                      ),

                                    // Edit button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () => _editUser(user),
                                      tooltip: 'Edit User',
                                    ),

                                    // Delete button (not for super admin)
                                    if (user.role != UserRole.superadmin)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _deleteUser(user),
                                        tooltip: 'Delete User',
                                      ),
                                  ],
                                ),
                                onTap: () => _editUser(user),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
