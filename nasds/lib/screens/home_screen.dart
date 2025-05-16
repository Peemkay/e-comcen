import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/user.dart';
import '../models/dispatch.dart';
import '../services/auth_service.dart';
import '../services/dispatch_service.dart';
import '../services/unit_service.dart';
import '../providers/notification_provider.dart';
import '../widgets/dispatch_tracking_dialog.dart';
import '../widgets/custom_app_bar.dart';
import 'dispatches/dispatches_screen.dart';
import 'users/users_screen.dart';
import 'reports/reports_screen.dart';
import 'units/units_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final DispatchService _dispatchService = DispatchService();

  // Stats for the dashboard
  int _pendingDispatches = 0;
  int _completedDispatches = 0;
  int _urgentDispatches = 0;
  int _alertCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  // Load real data for the dashboard
  Future<void> _loadDashboardStats() async {
    // Initialize the dispatch service if needed
    _dispatchService.initialize();

    // Calculate stats from real data
    final pendingCount = _countPendingDispatches();
    final completedCount = _countCompletedDispatches();
    final urgentCount = _countUrgentDispatches();
    final alertCount = await _getAlertCount();

    // Update state with real data
    if (mounted) {
      setState(() {
        _pendingDispatches = pendingCount;
        _completedDispatches = completedCount;
        _urgentDispatches = urgentCount;
        _alertCount = alertCount;
      });
    }

    return;
  }

  // Count pending dispatches
  int _countPendingDispatches() {
    int count = 0;

    // Count incoming dispatches with pending or in progress status
    count += _dispatchService
        .getIncomingDispatches()
        .where((d) =>
            d.status.toLowerCase() == 'pending' ||
            d.status.toLowerCase() == 'in progress')
        .length;

    // Count outgoing dispatches with pending or in progress status
    count += _dispatchService
        .getOutgoingDispatches()
        .where((d) =>
            d.status.toLowerCase() == 'pending' ||
            d.status.toLowerCase() == 'in progress')
        .length;

    // Count local dispatches with pending or in progress status
    count += _dispatchService
        .getLocalDispatches()
        .where((d) =>
            d.status.toLowerCase() == 'pending' ||
            d.status.toLowerCase() == 'in progress')
        .length;

    // Count external dispatches with pending or in progress status
    count += _dispatchService
        .getExternalDispatches()
        .where((d) =>
            d.status.toLowerCase() == 'pending' ||
            d.status.toLowerCase() == 'in progress')
        .length;

    return count;
  }

  // Count completed dispatches
  int _countCompletedDispatches() {
    int count = 0;

    // Count incoming dispatches with completed, delivered, or received status
    count += _dispatchService
        .getIncomingDispatches()
        .where((d) =>
            d.status.toLowerCase() == 'completed' ||
            d.status.toLowerCase() == 'delivered' ||
            d.status.toLowerCase() == 'received')
        .length;

    // Count outgoing dispatches with completed or delivered status
    count += _dispatchService
        .getOutgoingDispatches()
        .where((d) =>
            d.status.toLowerCase() == 'completed' ||
            d.status.toLowerCase() == 'delivered')
        .length;

    // Count local dispatches with completed status
    count += _dispatchService
        .getLocalDispatches()
        .where((d) => d.status.toLowerCase() == 'completed')
        .length;

    // Count external dispatches with completed status
    count += _dispatchService
        .getExternalDispatches()
        .where((d) => d.status.toLowerCase() == 'completed')
        .length;

    return count;
  }

  // Count urgent dispatches
  int _countUrgentDispatches() {
    int count = 0;

    // Count incoming dispatches with urgent or flash priority
    count += _dispatchService
        .getIncomingDispatches()
        .where((d) =>
            d.priority.toLowerCase() == 'urgent' ||
            d.priority.toLowerCase() == 'flash')
        .length;

    // Count outgoing dispatches with urgent or flash priority
    count += _dispatchService
        .getOutgoingDispatches()
        .where((d) =>
            d.priority.toLowerCase() == 'urgent' ||
            d.priority.toLowerCase() == 'flash')
        .length;

    // Count local dispatches with urgent or flash priority
    count += _dispatchService
        .getLocalDispatches()
        .where((d) =>
            d.priority.toLowerCase() == 'urgent' ||
            d.priority.toLowerCase() == 'flash')
        .length;

    // Count external dispatches with urgent or flash priority
    count += _dispatchService
        .getExternalDispatches()
        .where((d) =>
            d.priority.toLowerCase() == 'urgent' ||
            d.priority.toLowerCase() == 'flash')
        .length;

    return count;
  }

  // Get alert count from notification provider
  Future<int> _getAlertCount() async {
    try {
      // Get the notification provider
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      return notificationProvider.unreadCount;
    } catch (e) {
      // If there's an error or the provider is not available, return a default value
      return 0;
    }
  }

  // Show dispatch tracking dialog
  void _showTrackingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const DispatchTrackingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    // Calculate optimal grid columns based on screen width
    int gridColumns = 2; // Default for small screens
    if (screenSize.width >= 900) {
      gridColumns = 4; // Large screens
    } else if (screenSize.width >= 600) {
      gridColumns = 3; // Medium screens
    }

    // Calculate card aspect ratio based on screen size
    double cardAspectRatio = isSmallScreen ? 1.0 : 1.2;

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
                  behavior: SnackBarBehavior.floating,
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
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Welcome card
              _buildWelcomeCard(context),

              SizedBox(height: isSmallScreen ? 16 : 24),

              // Dashboard title with action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  // Quick action buttons
                  Row(
                    children: [
                      _buildQuickActionButton(
                        icon: FontAwesomeIcons.magnifyingGlass,
                        tooltip: 'Track Dispatch',
                        onTap: () => _showTrackingDialog(context),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionButton(
                        icon: FontAwesomeIcons.rotate,
                        tooltip: 'Refresh',
                        onTap: () {
                          // Show loading indicator
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Refreshing dashboard data...'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 1),
                            ),
                          );

                          // Refresh the data
                          setState(() {
                            // Trigger a refresh
                          });

                          // Load the data in the background
                          _loadDashboardStats();

                          // Store context for later use
                          final scaffoldMessenger =
                              ScaffoldMessenger.of(context);

                          // Show success message after a delay
                          Future.delayed(
                            const Duration(milliseconds: 1500),
                            () {
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Dashboard refreshed with latest data'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Dashboard cards in a responsive grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridColumns,
                    crossAxisSpacing: isSmallScreen ? 8 : 12,
                    mainAxisSpacing: isSmallScreen ? 8 : 12,
                    childAspectRatio: cardAspectRatio,
                  ),
                  itemCount: _getDashboardCards().length,
                  itemBuilder: (context, index) => _getDashboardCards()[index],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build the welcome card with user information
  Widget _buildWelcomeCard(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final user = _authService.currentUser;
    final lastLoginTime = DateTime.now().subtract(const Duration(hours: 2));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // User avatar with role indicator
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor
                          .withAlpha(204), // 0.8 opacity = 204 alpha
                      radius: isSmallScreen ? 20 : 24,
                      child: const Icon(
                        FontAwesomeIcons.userShield,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        width: 12,
                        height: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),

                // User information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?.name ?? 'User'}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor
                                  .withAlpha(38), // 0.15 opacity = 38 alpha
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getRoleName(user?.role) ??
                                  'Nigerian Army Signal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!isSmallScreen)
                            Text(
                              '• Last login: ${_formatTime(lastLoginTime)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // System information
            if (!isSmallScreen) const SizedBox(height: 12),
            if (!isSmallScreen)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.circleInfo,
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You are logged in as an administrator of the E-COMCEN system for Nigerian Army Signal.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Quick stats for the user
            if (!isSmallScreen) const SizedBox(height: 12),
            if (!isSmallScreen)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickStat(
                    icon: FontAwesomeIcons.envelopeCircleCheck,
                    label: 'Pending',
                    value: _pendingDispatches.toString(),
                    color: Colors.orange,
                  ),
                  _buildQuickStat(
                    icon: FontAwesomeIcons.check,
                    label: 'Completed',
                    value: _completedDispatches.toString(),
                    color: Colors.green,
                  ),
                  _buildQuickStat(
                    icon: FontAwesomeIcons.bell,
                    label: 'Alerts',
                    value: _alertCount.toString(),
                    color: Colors.red,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Build a quick stat indicator for the welcome card
  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(26), // 0.1 opacity = 26 alpha
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 14,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Format time for display
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Build a quick action button
  Widget _buildQuickActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  // Get the list of dashboard cards
  List<Widget> _getDashboardCards() {
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
        icon: FontAwesomeIcons.buildingFlag,
        title: 'Units',
        subtitle: 'Manage units & formations',
        color: Colors.blue[700]!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UnitsScreen(),
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
        icon: FontAwesomeIcons.trash,
        title: 'Trash',
        subtitle: 'Deleted dispatches',
        color: Colors.red[700]!,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trash feature coming soon'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
      _buildDashboardCard(
        icon: FontAwesomeIcons.locationDot,
        title: 'Track',
        subtitle: 'Track dispatches',
        color: Colors.green,
        onTap: () => _showTrackingDialog(context),
      ),
    ];
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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 2,
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
                color.withAlpha(15),
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with background
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: isSmallScreen ? 24 : 28,
                    color: color,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                // Subtitle
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
