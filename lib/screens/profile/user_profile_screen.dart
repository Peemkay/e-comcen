import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_theme.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

/// Screen that displays the user's profile information
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user from auth service
      _currentUser = _authService.currentUser;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 18),
            tooltip: 'Edit Profile',
            onPressed: () {
              // Navigate to edit profile screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit profile feature coming soon'),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(child: Text('User not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile header
                      _buildProfileHeader(isSmallScreen),
                      const SizedBox(height: 24),

                      // Profile details
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const Divider(),
                              const SizedBox(height: 8),
                              _buildProfileItem(
                                'Name',
                                _currentUser!.name,
                                FontAwesomeIcons.user,
                              ),
                              _buildProfileItem(
                                'Username',
                                _currentUser!.username,
                                FontAwesomeIcons.userTag,
                              ),
                              _buildProfileItem(
                                'Rank',
                                _currentUser!.rank,
                                FontAwesomeIcons.medal,
                              ),
                              _buildProfileItem(
                                'Army Number',
                                _currentUser!.armyNumber,
                                FontAwesomeIcons.idCard,
                              ),
                              _buildProfileItem(
                                'Unit',
                                _currentUser!.unit,
                                FontAwesomeIcons.buildingUser,
                              ),
                              _buildProfileItem(
                                'Year of Enlistment',
                                _currentUser!.yearOfEnlistment.toString(),
                                FontAwesomeIcons.calendarDay,
                              ),
                              _buildProfileItem(
                                'Role',
                                _getRoleName(_currentUser!.role),
                                FontAwesomeIcons.userShield,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Account actions
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Account Actions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const Divider(),
                              const SizedBox(height: 8),
                              _buildActionButton(
                                'Change Password',
                                FontAwesomeIcons.lock,
                                () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Change password feature coming soon'),
                                    ),
                                  );
                                },
                              ),
                              _buildActionButton(
                                'Notification Settings',
                                FontAwesomeIcons.bell,
                                () {
                                  Navigator.pushNamed(
                                      context, '/notification_settings');
                                },
                              ),
                              _buildActionButton(
                                'Logout',
                                FontAwesomeIcons.rightFromBracket,
                                () {
                                  _authService.logout();
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, '/login', (route) => false);
                                },
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader(bool isSmallScreen) {
    return Column(
      children: [
        // Avatar
        CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          radius: isSmallScreen ? 50 : 60,
          child: Text(
            _getInitials(_currentUser?.name ?? 'User'),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 30 : 36,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Name and role
        Text(
          _currentUser?.name ?? 'User',
          style: TextStyle(
            fontSize: isSmallScreen ? 22 : 26,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _getRoleName(_currentUser?.role),
            style: TextStyle(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w500,
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          FaIcon(
            icon,
            size: 18,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed,
      {Color color = AppTheme.primaryColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              FaIcon(
                icon,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleName(UserRole? role) {
    if (role == null) return 'User';
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.superadmin:
        return 'Super Administrator';
      case UserRole.dispatcher:
        return 'Dispatcher';
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';

    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else {
      return name.substring(0, 1).toUpperCase();
    }
  }
}
