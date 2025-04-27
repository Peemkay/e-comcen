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
        content: Text('Are you sure you want to delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await _userService.deleteUser(user.id);
                _loadUsers();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Username: ${user.username}'),
            Text('Rank: ${user.rank}'),
            Text('Unit: ${user.unit}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(FontAwesomeIcons.penToSquare, size: 20),
              onPressed: () => _editUser(user),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(FontAwesomeIcons.trash, size: 20, color: Colors.red),
              onPressed: () => _deleteUser(user),
              tooltip: 'Delete',
            ),
          ],
        ),
        onTap: () {
          // Show user details
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) => _buildUserDetailSheet(user),
          );
        },
      ),
    );
  }
  
  Widget _buildUserDetailSheet(User user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
                radius: 24,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.rank,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),
          
          // User details
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
                icon: const Icon(FontAwesomeIcons.penToSquare),
                label: const Text('Edit'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteUser(user);
                },
                icon: const Icon(FontAwesomeIcons.trash, color: Colors.red),
                label: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
