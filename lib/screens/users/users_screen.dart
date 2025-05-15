import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_theme.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import 'user_form.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserService _userService = UserService();
  late List<User> _users;
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _userService.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      _loadUsers();
      return;
    }

    setState(() {
      _users = _users.where((user) {
        return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.rank.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.unit.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    });
  }

  void _addNewUser() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserForm(),
      ),
    ).then((_) => _loadUsers());
  }

  void _editUser(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserForm(user: user),
      ),
    ).then((_) => _loadUsers());
  }

  void _deleteUser(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Close the dialog first
              Navigator.pop(context);

              // Store the BuildContext before the async gap
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              try {
                // Delete the user
                await _userService.deleteUser(user.id);

                // Reload the users list
                _loadUsers();

                // Show success message if still mounted
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('User deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                // Show error message if still mounted
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error deleting user: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: AppTheme.primaryColor,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewUser,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users by name, username, rank, or unit',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterUsers();
                });
              },
            ),
          ),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _users.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return _buildUserCard(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(User user) {
    // Use MediaQuery to get screen size
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Show user details
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) => SingleChildScrollView(
                controller: scrollController,
                child: _buildUserDetailSheet(user),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isSmallScreen
              ? _buildCompactUserCard(user)
              : _buildFullUserCard(user),
        ),
      ),
    );
  }

  // Compact user card for small screens
  Widget _buildCompactUserCard(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with avatar and name
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              radius: 20,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.username,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // User info
        Text('Rank: ${user.rank}', overflow: TextOverflow.ellipsis),
        Text('Unit: ${user.unit}', overflow: TextOverflow.ellipsis),

        const SizedBox(height: 8),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(FontAwesomeIcons.penToSquare, size: 18),
              onPressed: () => _editUser(user),
              tooltip: 'Edit',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              icon: const Icon(FontAwesomeIcons.trash,
                  size: 18, color: Colors.red),
              onPressed: () => _deleteUser(user),
              tooltip: 'Delete',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ],
    );
  }

  // Full user card for larger screens
  Widget _buildFullUserCard(User user) {
    return Row(
      children: [
        // Avatar
        CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          radius: 24,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // User info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text('Username: ${user.username}'),
              Text('Rank: ${user.rank}'),
              Text('Unit: ${user.unit}'),
            ],
          ),
        ),

        // Action buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(FontAwesomeIcons.penToSquare, size: 20),
              onPressed: () => _editUser(user),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(FontAwesomeIcons.trash,
                  size: 20, color: Colors.red),
              onPressed: () => _deleteUser(user),
              tooltip: 'Delete',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserDetailSheet(User user) {
    // Use MediaQuery to get screen size
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  radius: isSmallScreen ? 20 : 24,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 16 : 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.rank,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),

            // User details - Responsive layout
            isSmallScreen
                ? _buildCompactUserDetails(user)
                : _buildFullUserDetails(user),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _editUser(user);
                  },
                  icon: Icon(
                    FontAwesomeIcons.penToSquare,
                    size: isSmallScreen ? 16 : 20,
                  ),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteUser(user);
                  },
                  icon: Icon(
                    FontAwesomeIcons.trash,
                    size: isSmallScreen ? 16 : 20,
                    color: Colors.red,
                  ),
                  label:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Compact user details for small screens
  Widget _buildCompactUserDetails(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompactDetailItem(
            FontAwesomeIcons.userTag, 'Username', user.username),
        _buildCompactDetailItem(
            FontAwesomeIcons.buildingUser, 'Unit', user.unit),
        _buildCompactDetailItem(
            FontAwesomeIcons.idCard, 'Army Number', user.armyNumber),
        _buildCompactDetailItem(FontAwesomeIcons.calendarDay,
            'Year of Enlistment', user.yearOfEnlistment.toString()),
      ],
    );
  }

  // Full user details for larger screens
  Widget _buildFullUserDetails(User user) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(FontAwesomeIcons.userTag),
          title: const Text('Username'),
          subtitle: Text(user.username),
        ),
        ListTile(
          leading: const Icon(FontAwesomeIcons.buildingUser),
          title: const Text('Unit'),
          subtitle: Text(user.unit),
        ),
        ListTile(
          leading: const Icon(FontAwesomeIcons.idCard),
          title: const Text('Army Number'),
          subtitle: Text(user.armyNumber),
        ),
        ListTile(
          leading: const Icon(FontAwesomeIcons.calendarDay),
          title: const Text('Year of Enlistment'),
          subtitle: Text(user.yearOfEnlistment.toString()),
        ),
      ],
    );
  }

  // Compact detail item for small screens
  Widget _buildCompactDetailItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
