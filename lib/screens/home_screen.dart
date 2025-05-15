import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../widgets/dispatch_tracking_dialog.dart';
import '../widgets/enhanced_app_bar.dart';
import '../widgets/enhanced_card.dart';
import 'dispatches/dispatches_screen.dart';
import 'users/users_screen.dart';
import 'reports/reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();

  void _showTrackingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const DispatchTrackingDialog(),
    );
  }

  String? _getRoleName(UserRole? role) {
    if (role == null) return null;
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.dispatcher:
        return 'Dispatcher';
      case UserRole.viewer:
        return 'Viewer';
      default:
        return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: EnhancedAppBar(
        title: 'E-COMCEN Dashboard',
        onSearchTap: () => _showTrackingDialog(context),
        showLogo: true,
        showUserProfile: true,
        showNotificationBadge: true,
        showSearchButton: true,
        showHelpButton: true,
        elevation: 2.0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced welcome card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor.withAlpha(15),
                        Colors.white,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withAlpha(15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              FontAwesomeIcons.userShield,
                              color: AppTheme.primaryColor,
                              size: 24,
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            AppTheme.accentColor.withAlpha(50),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getRoleName(_authService
                                                .currentUser?.role) ??
                                            'Nigerian Army Signal',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryColor.withAlpha(20),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.circleInfo,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You are logged in as an administrator of the E-COMCEN system for Nigerian Army Signal. Powered by NAS.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24.0),

              // Dashboard title with improved styling
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0, left: 4.0),
                child: Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),

              // Responsive dashboard grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: isSmallScreen ? 2 : 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
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
                    _buildDashboardCard(
                      icon: FontAwesomeIcons.magnifyingGlass,
                      title: 'Track Dispatch',
                      subtitle: 'Search and track dispatches',
                      color: Colors.teal,
                      onTap: () => _showTrackingDialog(context),
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

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 3,
      shadowColor: color.withAlpha(40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withAlpha(10),
                Colors.white,
              ],
            ),
          ),
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(30),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: isSmallScreen ? 28 : 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 15 : 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: color.withAlpha(200),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
