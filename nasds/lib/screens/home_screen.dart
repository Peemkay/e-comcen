import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../widgets/dispatch_tracking_dialog.dart';
import '../widgets/custom_app_bar.dart';
import 'dispatches/dispatches_screen.dart';
import 'users/users_screen.dart';
import 'reports/reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  // Show dispatch tracking dialog
  void _showTrackingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const DispatchTrackingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'E-COMCEN Dashboard',
        actions: [
          // Track dispatch button
          IconButton(
            icon: const Icon(FontAwesomeIcons.magnifyingGlass, size: 18),
            onPressed: () => _showTrackingDialog(context),
            tooltip: 'Track Dispatch',
          ),

          // Help button
          IconButton(
            icon: const Icon(FontAwesomeIcons.circleQuestion, size: 18),
            onPressed: () {
              // Show help
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help feature coming soon'),
                ),
              );
            },
            tooltip: 'Help',
          ),

          // Logout button
          IconButton(
            icon: const Icon(FontAwesomeIcons.rightFromBracket, size: 18),
            onPressed: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        _authService.logout(); // Logout user
                        Navigator.pushReplacementNamed(context,
                            AppConstants.loginRoute); // Navigate to login
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            radius: 24,
                            child: const Icon(
                              FontAwesomeIcons.userShield,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, ${_authService.currentUser?.name ?? 'User'}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                Text(
                                  _getRoleName(
                                          _authService.currentUser?.role) ??
                                      'Nigerian Army Signal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'You are logged in as an administrator of the E-COMCEN system for Nigerian Army Signal. Powered by NAS.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Dashboard title
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // Dashboard cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildDashboardCard(
                      icon: FontAwesomeIcons.envelopeCircleCheck,
                      title: 'Dispatches',
                      subtitle: 'Manage dispatches',
                      color: AppTheme.primaryColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DispatchesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      icon: FontAwesomeIcons.users,
                      title: 'Users',
                      subtitle: 'Manage users',
                      color: AppTheme.secondaryColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UsersScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      icon: FontAwesomeIcons.chartLine,
                      title: 'Reports',
                      subtitle: 'View reports',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReportsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      icon: FontAwesomeIcons.gear,
                      title: 'Settings',
                      subtitle: 'System settings',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pushNamed(
                            context, AppConstants.settingsRoute);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _getRoleName(UserRole? role) {
    if (role == null) return null;

    if (role == UserRole.superadmin) {
      return 'Super Administrator';
    } else if (role == UserRole.admin) {
      return 'Administrator';
    } else if (role == UserRole.dispatcher) {
      return 'Dispatcher';
    }

    return 'User';
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
