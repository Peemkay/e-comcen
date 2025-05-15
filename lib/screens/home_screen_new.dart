import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/user.dart';
import '../models/dispatch.dart';
import '../services/auth_service.dart';
import '../services/dispatch_service.dart';
import '../services/user_service.dart';
import '../widgets/dispatch_tracking_dialog.dart';
import '../widgets/notifications/notification_badge.dart';
import '../widgets/responsive_layout.dart';
import 'help/help_menu_screen.dart';
import 'profile/user_profile_screen.dart';

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
  final _dispatchService = DispatchService();
  final _userService = UserService();

  // Stats data
  int _pendingDispatchesCount = 0;
  int _activeUsersCount = 0;
  int _reportsGeneratedCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // Load real stats from services
  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get pending dispatches count (dispatches that are not completed or delivered)
      final incomingDispatches = _dispatchService.getIncomingDispatches();
      final outgoingDispatches = _dispatchService.getOutgoingDispatches();
      final localDispatches = _dispatchService.getLocalDispatches();
      final externalDispatches = _dispatchService.getExternalDispatches();

      final pendingIncoming = incomingDispatches
          .where((d) =>
              d.status.toLowerCase() != 'delivered' &&
              d.status.toLowerCase() != 'completed')
          .length;

      final pendingOutgoing = outgoingDispatches
          .where((d) =>
              d.status.toLowerCase() != 'delivered' &&
              d.status.toLowerCase() != 'completed')
          .length;

      final pendingLocal = localDispatches
          .where((d) =>
              d.status.toLowerCase() != 'delivered' &&
              d.status.toLowerCase() != 'completed')
          .length;

      final pendingExternal = externalDispatches
          .where((d) =>
              d.status.toLowerCase() != 'delivered' &&
              d.status.toLowerCase() != 'completed')
          .length;

      // Get active users count
      final users = await _userService.getUsers();
      final activeUsers = users.where((u) => u.isActive && u.isApproved).length;

      // Get reports count (using logs as a proxy for reports generated)
      final logs = _dispatchService.getComcenLogs();
      final reportsLogs = logs
          .where((log) =>
              log.action.toLowerCase().contains('report') ||
              log.notes.toLowerCase().contains('report'))
          .length;

      if (mounted) {
        setState(() {
          _pendingDispatchesCount = pendingIncoming +
              pendingOutgoing +
              pendingLocal +
              pendingExternal;
          _activeUsersCount = activeUsers;
          _reportsGeneratedCount = reportsLogs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            Container(
              height: 36,
              width: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  AppConstants.logoPath,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Title
            const Flexible(
              child: Text(
                'E-COMCEN Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2.0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        actions: [
          // Search button
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 18),
            tooltip: 'Search & Track Dispatch',
            onPressed: () => _showTrackingDialog(context),
          ),

          // Notification badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: NotificationBadge(
              size: 20.0,
              badgeColor: AppTheme.accentColor,
              showBadge: true, // Show badge when there are notifications
              count: 3, // Example count, should be from notification provider
              onTap: () {
                Navigator.pushNamed(context, '/notifications');
              },
              child: const FaIcon(FontAwesomeIcons.bell, size: 18),
            ),
          ),

          // Help button
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.circleQuestion, size: 18),
            tooltip: 'Help & Support',
            onPressed: () => _showHelpMenu(context),
          ),

          // User profile
          Padding(
            padding: const EdgeInsets.only(right: 8.0, left: 4.0),
            child: InkWell(
              onTap: () => _showUserProfileMenu(context),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentColor,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(_authService.currentUser?.name ?? 'User'),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          // Mobile layout (single column)
          mobile: _buildMobileLayout(context),

          // Desktop layout (two columns)
          desktop: _buildDesktopLayout(context),
        ),
      ),
    );
  }

  // Mobile layout with single column
  Widget _buildMobileLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card
          _buildWelcomeCard(),

          const SizedBox(height: 24.0),

          // Dashboard title
          const Padding(
            padding: EdgeInsets.only(
              bottom: 16.0,
              left: 4.0,
            ),
            child: Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),

          // Dashboard cards
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: _buildDashboardCards(),
            ),
          ),
        ],
      ),
    );
  }

  // Desktop layout with two columns
  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: TwoColumnLayout(
        // Left column (welcome card and additional info)
        left: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            _buildWelcomeCard(),

            const SizedBox(height: 24.0),

            // Additional info or stats can be added here
            _buildQuickStatsCard(),
          ],
        ),

        // Right column (dashboard cards)
        right: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard title
            const Padding(
              padding: EdgeInsets.only(
                bottom: 16.0,
                left: 4.0,
              ),
              child: Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),

            // Dashboard cards in a responsive grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: _buildDashboardCards(),
              ),
            ),
          ],
        ),

        // Left column takes 35% of the width
        ratio: 0.35,
      ),
    );
  }

  // Welcome card widget
  Widget _buildWelcomeCard() {
    return Card(
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
                              color: AppTheme.accentColor.withAlpha(50),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getRoleName(_authService.currentUser?.role) ??
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
    );
  }

  // Quick stats card for desktop layout
  Widget _buildQuickStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quick Stats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                if (!_isLoading)
                  IconButton(
                    icon: const Icon(FontAwesomeIcons.arrowsRotate, size: 14),
                    onPressed: _loadStats,
                    tooltip: 'Refresh stats',
                    color: AppTheme.primaryColor,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats rows
            _buildStatRow(
              icon: FontAwesomeIcons.envelopeCircleCheck,
              title: 'Pending Dispatches',
              value: _pendingDispatchesCount.toString(),
              color: AppTheme.primaryColor,
            ),
            const Divider(height: 24),
            _buildStatRow(
              icon: FontAwesomeIcons.userCheck,
              title: 'Active Users',
              value: _activeUsersCount.toString(),
              color: AppTheme.secondaryColor,
            ),
            const Divider(height: 24),
            _buildStatRow(
              icon: FontAwesomeIcons.fileLines,
              title: 'Reports Generated',
              value: _reportsGeneratedCount.toString(),
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  // Stat row for quick stats card
  Widget _buildStatRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FaIcon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // List of dashboard cards
  List<Widget> _buildDashboardCards() {
    return [
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
          Navigator.pushNamed(context, AppConstants.settingsRoute);
        },
      ),
      _buildDashboardCard(
        icon: FontAwesomeIcons.magnifyingGlass,
        title: 'Track Dispatch',
        subtitle: 'Search and track dispatches',
        color: Colors.teal,
        onTap: () => _showTrackingDialog(context),
      ),
      _buildDashboardCard(
        icon: FontAwesomeIcons.trash,
        title: 'Trash',
        subtitle: 'View deleted items',
        color: Colors.red,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trash feature coming soon')),
          );
        },
      ),
    ];
  }

  String? _getRoleName(UserRole? role) {
    if (role == null) return null;
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

  void _showTrackingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const DispatchTrackingDialog(),
    );
  }

  void _showHelpMenu(BuildContext context) {
    // Show help menu options in a bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            const Center(
              child: Text(
                'Help & Support',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildHelpMenuItem(
              'User Guide',
              'View comprehensive user documentation',
              FontAwesomeIcons.bookOpen,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpMenuScreen(),
                  ),
                );
              },
            ),
            _buildHelpMenuItem(
              'FAQs',
              'Frequently asked questions',
              FontAwesomeIcons.circleQuestion,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpMenuScreen(),
                  ),
                );
              },
            ),
            _buildHelpMenuItem(
              'Contact Support',
              'Get help from our support team',
              FontAwesomeIcons.headset,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpMenuScreen(),
                  ),
                );
              },
            ),
            _buildHelpMenuItem(
              'About',
              'About E-COMCEN',
              FontAwesomeIcons.circleInfo,
              () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/about');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpMenuItem(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: FaIcon(
          icon,
          size: 18,
          color: AppTheme.primaryColor,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _showUserProfileMenu(BuildContext context) {
    // Show user profile options in a bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            // User info header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  radius: 30,
                  child: Text(
                    _getInitials(_authService.currentUser?.name ?? 'User'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _authService.currentUser?.name ?? 'User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getRoleName(_authService.currentUser?.role) ?? 'User',
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
            const Divider(height: 32),

            // Profile options
            _buildProfileMenuItem(
              'View Profile',
              'View and edit your profile information',
              FontAwesomeIcons.userPen,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserProfileScreen(),
                  ),
                );
              },
            ),
            _buildProfileMenuItem(
              'Notification Settings',
              'Manage your notification preferences',
              FontAwesomeIcons.bell,
              () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/notification_settings');
              },
            ),
            _buildProfileMenuItem(
              'Settings',
              'App settings and preferences',
              FontAwesomeIcons.gear,
              () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppConstants.settingsRoute);
              },
            ),
            const Divider(),
            _buildProfileMenuItem(
              'Logout',
              'Sign out of your account',
              FontAwesomeIcons.rightFromBracket,
              () {
                Navigator.pop(context);
                _authService.logout();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              },
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem(
      String title, String subtitle, IconData icon, VoidCallback onTap,
      {Color color = AppTheme.primaryColor}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: FaIcon(
          icon,
          size: 18,
          color: color,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(color: color),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
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
