import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../constants/app_constants.dart';
import '../models/user.dart';
import '../models/notification.dart';
import '../providers/translation_provider.dart';
import '../providers/notification_provider.dart';
import '../services/auth_service.dart';
import 'admin/user_management_screen.dart';
import 'admin/system_settings_screen.dart';
import 'admin/security_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'help_support_screen.dart';
import 'terms_conditions_screen.dart';
import 'privacy_policy_screen.dart';
import 'app_version_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final translationProvider = Provider.of<TranslationProvider>(context);
    final currentUser = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: ListView(
        children: [
          // User Profile Section
          if (currentUser != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            radius: 30,
                            child: Text(
                              currentUser.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUser.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  currentUser.username,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(currentUser.role),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    currentUser.role.displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Rank:'),
                          Text(
                            currentUser.rank,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Corps:'),
                          Text(
                            currentUser.corps,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Army Number:'),
                          Text(
                            currentUser.armyNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Unit:'),
                          Text(
                            currentUser.unitId,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // App Settings Section
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Language Settings
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: const Text('Language'),
                      subtitle: Text(translationProvider.currentLanguage.name),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        _showLanguageDialog(context, translationProvider);
                      },
                    ),

                    // Theme Settings
                    SwitchListTile(
                      secondary: const Icon(Icons.brightness_6),
                      title: const Text('Dark Mode'),
                      value: _isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          _isDarkMode = value;
                        });
                        // TODO: Implement dark mode
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dark mode coming soon!'),
                          ),
                        );
                      },
                    ),

                    // Notification Settings
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Notification Settings'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),

                    // Test Notification Button
                    ListTile(
                      leading: const Icon(Icons.notification_add),
                      title: const Text('Test Notifications'),
                      subtitle: const Text('Send test notifications'),
                      onTap: () {
                        _showTestNotificationDialog(context);
                      },
                    ),

                    // Device Management
                    ListTile(
                      leading: const Icon(Icons.devices),
                      title: const Text('Device Management'),
                      subtitle: const Text('Manage connected devices'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppConstants.deviceManagementRoute,
                        );
                      },
                    ),

                    // Dispatcher Settings (only for admin and superadmin)
                    if (currentUser != null &&
                        (currentUser.role == UserRole.superadmin ||
                            currentUser.role == UserRole.admin))
                      ListTile(
                        leading: const Icon(Icons.assignment_ind),
                        title: const Text('Dispatcher Settings'),
                        subtitle:
                            const Text('Configure dispatcher assignments'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pushNamed(context, '/dispatcher_settings');
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Admin Settings Section (only for superadmin and admin)
          if (currentUser != null &&
              (currentUser.role == UserRole.superadmin ||
                  currentUser.role == UserRole.admin)) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // User Management (only for superadmin or admin with permission)
                      if (_authService.hasPermission(Permission.manageUsers))
                        ListTile(
                          leading: const Icon(Icons.people),
                          title: const Text('User Management'),
                          subtitle: const Text('Manage users and permissions'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const UserManagementScreen(),
                              ),
                            );
                          },
                        ),

                      // System Settings (only for superadmin)
                      if (currentUser.role == UserRole.superadmin)
                        ListTile(
                          leading: const Icon(Icons.settings_applications),
                          title: const Text('System Settings'),
                          subtitle: const Text('Configure system parameters'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SystemSettingsScreen(),
                              ),
                            );
                          },
                        ),

                      // Security Settings (only for superadmin)
                      if (currentUser.role == UserRole.superadmin)
                        ListTile(
                          leading: const Icon(Icons.security),
                          title: const Text('Security Settings'),
                          subtitle: const Text('Configure security parameters'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SecuritySettingsScreen(),
                              ),
                            );
                          },
                        ),

                      // User Connections (only for superadmin or admin)
                      if (currentUser.role == UserRole.superadmin ||
                          currentUser.role == UserRole.admin)
                        ListTile(
                          leading: const Icon(Icons.device_hub),
                          title: const Text('User Connections'),
                          subtitle: const Text('Monitor connected users'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.pushNamed(context, '/user_connections');
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // About Section
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // App Version
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('App Version'),
                      subtitle: Text(AppConstants.appVersion),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppVersionScreen(),
                          ),
                        );
                      },
                    ),

                    // Help & Support
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: const Text('Help & Support'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),

                    // Terms & Conditions
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Terms & Conditions'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsConditionsScreen(),
                          ),
                        );
                      },
                    ),

                    // Privacy Policy
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Logout Button
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                _showLogoutConfirmationDialog(context);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superadmin:
        return Colors.deepOrange;
      case UserRole.admin:
        return Colors.blue;
      case UserRole.dispatcher:
        return Colors.green;
      case UserRole.operator:
        return Colors.purple;
      case UserRole.viewer:
        return Colors.blueGrey;
    }
  }

  void _showLanguageDialog(BuildContext context, TranslationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: provider.supportedLanguages.map((language) {
              return ListTile(
                title: Text(language.name),
                trailing: language.code == provider.currentLanguage.code
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  provider.changeLanguage(language);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Logout and navigate to login screen
              _authService.logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppConstants.loginRoute,
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showTestNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Test Notification'),
        content: const Text('Select a notification type to test:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendTestNotification(context, 'normal');
            },
            child: const Text('Normal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendTestNotification(context, 'high');
            },
            child: const Text('High Priority'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendTestNotification(context, 'urgent');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Urgent'),
          ),
        ],
      ),
    );
  }

  void _sendTestNotification(BuildContext context, String priority) {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    switch (priority) {
      case 'normal':
        notificationProvider.createSystemNotification(
          title: 'Test Notification',
          body: 'This is a test notification with normal priority.',
          priority: NotificationPriority.normal,
        );
        break;
      case 'high':
        notificationProvider.createSystemNotification(
          title: 'High Priority Test',
          body: 'This is a test notification with high priority.',
          priority: NotificationPriority.high,
        );
        break;
      case 'urgent':
        notificationProvider.createAlertNotification(
          title: 'URGENT: Test Alert',
          body:
              'This is an urgent test notification that requires immediate attention.',
          priority: NotificationPriority.urgent,
        );
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
