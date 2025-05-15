import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_connection_provider.dart';
import '../../providers/translation_provider.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/common/section_header.dart';
import '../../models/user.dart';

/// Screen for monitoring user connections
class UserConnectionsScreen extends StatefulWidget {
  const UserConnectionsScreen({super.key});

  @override
  State<UserConnectionsScreen> createState() => _UserConnectionsScreenState();
}

class _UserConnectionsScreenState extends State<UserConnectionsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh data when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserConnectionProvider>(context, listen: false).refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final translationProvider = Provider.of<TranslationProvider>(context);
    final connectionProvider = Provider.of<UserConnectionProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: translationProvider.translate('user_connections'),
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => connectionProvider.refreshData(),
            tooltip: translationProvider.translate('refresh'),
          ),
        ],
      ),
      body: connectionProvider.isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(context, connectionProvider),
    );
  }

  Widget _buildContent(BuildContext context, UserConnectionProvider provider) {
    final translationProvider = Provider.of<TranslationProvider>(context);
    final statistics = provider.statistics;
    final activeConnections = provider.activeConnections;
    final onlineUsers = provider.onlineUsers;

    return RefreshIndicator(
      onRefresh: () => provider.refreshData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics card
            _buildStatisticsCard(context, statistics),
            const SizedBox(height: 24.0),

            // Active connections
            SectionHeader(
              title: translationProvider.translate('active_connections'),
              icon: Icons.link,
            ),
            const SizedBox(height: 8.0),
            activeConnections.isEmpty
                ? _buildEmptyCard(
                    translationProvider.translate('no_active_connections'))
                : _buildConnectionsList(context, activeConnections),
            const SizedBox(height: 24.0),

            // Online users
            SectionHeader(
              title: translationProvider.translate('online_users'),
              icon: Icons.person,
            ),
            const SizedBox(height: 8.0),
            onlineUsers.isEmpty
                ? _buildEmptyCard(
                    translationProvider.translate('no_online_users'))
                : _buildOnlineUsersList(context, onlineUsers),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(
      BuildContext context, Map<String, dynamic> statistics) {
    final translationProvider = Provider.of<TranslationProvider>(context);

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translationProvider.translate('connection_statistics'),
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  translationProvider.translate('total_users'),
                  statistics['totalUsers']?.toString() ?? '0',
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatItem(
                  context,
                  translationProvider.translate('online_users'),
                  statistics['onlineUsers']?.toString() ?? '0',
                  Icons.person,
                  Colors.green,
                ),
                _buildStatItem(
                  context,
                  translationProvider.translate('active_connections'),
                  statistics['activeConnections']?.toString() ?? '0',
                  Icons.link,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Divider(),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  translationProvider.translate('admin_connections'),
                  statistics['adminConnections']?.toString() ?? '0',
                  Icons.admin_panel_settings,
                  Colors.purple,
                  small: true,
                ),
                _buildStatItem(
                  context,
                  translationProvider.translate('superadmin_connections'),
                  statistics['superadminConnections']?.toString() ?? '0',
                  Icons.security,
                  Colors.red,
                  small: true,
                ),
                _buildStatItem(
                  context,
                  translationProvider.translate('dispatcher_connections'),
                  statistics['dispatcherConnections']?.toString() ?? '0',
                  Icons.delivery_dining,
                  Colors.teal,
                  small: true,
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            if (statistics['timestamp'] != null)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${translationProvider.translate('last_updated')}: ${_formatTimestamp(statistics['timestamp'])}',
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    bool small = false,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(small ? 8.0 : 12.0),
          decoration: BoxDecoration(
            color: color.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(
            icon,
            color: color,
            size: small ? 20.0 : 24.0,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          value,
          style: TextStyle(
            fontSize: small ? 16.0 : 20.0,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: small ? 12.0 : 14.0,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      elevation: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionsList(
      BuildContext context, List<Map<String, dynamic>> connections) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: connections.length,
      itemBuilder: (context, index) =>
          _buildConnectionItem(context, connections[index]),
    );
  }

  Widget _buildConnectionItem(
      BuildContext context, Map<String, dynamic> connection) {
    final translationProvider = Provider.of<TranslationProvider>(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(connection['role']),
          child: Icon(
            _getRoleIcon(connection['role']),
            color: Colors.white,
            size: 20.0,
          ),
        ),
        title: Text(connection['name'] ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${translationProvider.translate('device')}: ${connection['deviceInfo'] ?? 'Unknown'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${translationProvider.translate('connected_at')}: ${_formatTimestamp(connection['connectedAt'])}',
              style: const TextStyle(fontSize: 12.0),
            ),
          ],
        ),
        trailing: connection['appType'] == 'dispatcher'
            ? const Chip(
                label: Text(
                  'DSM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                  ),
                ),
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(horizontal: 8.0),
              )
            : null,
        onTap: () => _showConnectionDetails(context, connection),
      ),
    );
  }

  Widget _buildOnlineUsersList(BuildContext context, List<User> users) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) => _buildUserItem(context, users[index]),
    );
  }

  Widget _buildUserItem(BuildContext context, User user) {
    final translationProvider = Provider.of<TranslationProvider>(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role.name),
          child: Text(
            user.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${translationProvider.translate('rank')}: ${user.rank}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${translationProvider.translate('last_seen')}: ${_formatTimestamp(user.lastSeen?.millisecondsSinceEpoch)}',
              style: const TextStyle(fontSize: 12.0),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.history),
          onPressed: () => _showUserConnectionHistory(context, user),
          tooltip: translationProvider.translate('connection_history'),
        ),
        onTap: () => _showUserDetails(context, user),
      ),
    );
  }

  void _showConnectionDetails(
      BuildContext context, Map<String, dynamic> connection) {
    final translationProvider =
        Provider.of<TranslationProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translationProvider.translate('connection_details')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem(
                translationProvider.translate('user'),
                connection['name'] ?? 'Unknown',
              ),
              _buildDetailItem(
                translationProvider.translate('username'),
                connection['username'] ?? 'Unknown',
              ),
              _buildDetailItem(
                translationProvider.translate('role'),
                _getRoleName(connection['role']),
              ),
              _buildDetailItem(
                translationProvider.translate('device'),
                connection['deviceInfo'] ?? 'Unknown',
              ),
              _buildDetailItem(
                translationProvider.translate('device_id'),
                connection['deviceId'] ?? 'Unknown',
              ),
              _buildDetailItem(
                translationProvider.translate('ip_address'),
                connection['ipAddress'] ?? 'Unknown',
              ),
              _buildDetailItem(
                translationProvider.translate('connection_id'),
                connection['connectionId'] ?? 'Unknown',
              ),
              _buildDetailItem(
                translationProvider.translate('connected_at'),
                _formatTimestamp(connection['connectedAt']),
              ),
              _buildDetailItem(
                translationProvider.translate('last_heartbeat'),
                _formatTimestamp(connection['lastHeartbeat']),
              ),
              _buildDetailItem(
                translationProvider.translate('app_type'),
                connection['appType'] == 'dispatcher'
                    ? translationProvider.translate('dispatcher_app')
                    : translationProvider.translate('main_app'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translationProvider.translate('close')),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, User user) {
    final translationProvider =
        Provider.of<TranslationProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translationProvider.translate('user_details')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem(
                translationProvider.translate('name'),
                user.name,
              ),
              _buildDetailItem(
                translationProvider.translate('username'),
                user.username,
              ),
              _buildDetailItem(
                translationProvider.translate('email'),
                user.email,
              ),
              _buildDetailItem(
                translationProvider.translate('role'),
                user.role.displayName,
              ),
              _buildDetailItem(
                translationProvider.translate('rank'),
                user.rank,
              ),
              _buildDetailItem(
                translationProvider.translate('corps'),
                user.corps,
              ),
              _buildDetailItem(
                translationProvider.translate('army_number'),
                user.armyNumber,
              ),
              _buildDetailItem(
                translationProvider.translate('unit'),
                user.unitId,
              ),
              _buildDetailItem(
                translationProvider.translate('status'),
                user.isActive
                    ? translationProvider.translate('active')
                    : translationProvider.translate('inactive'),
              ),
              _buildDetailItem(
                translationProvider.translate('approved'),
                user.isApproved
                    ? translationProvider.translate('yes')
                    : translationProvider.translate('no'),
              ),
              _buildDetailItem(
                translationProvider.translate('device'),
                user.deviceInfo ?? translationProvider.translate('unknown'),
              ),
              _buildDetailItem(
                translationProvider.translate('last_seen'),
                user.lastSeen != null
                    ? _formatTimestamp(user.lastSeen!.millisecondsSinceEpoch)
                    : translationProvider.translate('never'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translationProvider.translate('close')),
          ),
        ],
      ),
    );
  }

  Future<void> _showUserConnectionHistory(
      BuildContext context, User user) async {
    final translationProvider =
        Provider.of<TranslationProvider>(context, listen: false);
    final connectionProvider =
        Provider.of<UserConnectionProvider>(context, listen: false);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16.0),
            Text('Loading connection history...'),
          ],
        ),
      ),
    );

    // Get connection history
    final history = await connectionProvider.getUserConnectionHistory(user.id);

    // Check if widget is still mounted before updating UI
    if (!mounted) return;

    // Store context before async gap
    final BuildContext currentContext = context;

    // Close loading dialog
    Navigator.of(currentContext).pop();

    // Show history dialog
    if (mounted) {
      showDialog(
        context: currentContext,
        builder: (dialogContext) => AlertDialog(
          title: Text(
              '${translationProvider.translate('connection_history')} - ${user.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: history.isEmpty
                ? Center(
                    child: Text(
                        translationProvider.translate('no_connection_history')),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: history.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(
                        history[index]['deviceInfo'] ?? 'Unknown Device',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${translationProvider.translate('connected_at')}: ${_formatTimestamp(history[index]['connectedAt'])}',
                          ),
                          if (history[index]['disconnectedAt'] != null)
                            Text(
                              '${translationProvider.translate('disconnected_at')}: ${_formatTimestamp(history[index]['disconnectedAt'])}',
                            ),
                          Text(
                            '${translationProvider.translate('ip_address')}: ${history[index]['ipAddress'] ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 12.0),
                          ),
                        ],
                      ),
                      leading: CircleAvatar(
                        backgroundColor: history[index]['isActive'] == true
                            ? Colors.green
                            : Colors.grey,
                        child: Icon(
                          history[index]['isActive'] == true
                              ? Icons.link
                              : Icons.link_off,
                          color: Colors.white,
                          size: 16.0,
                        ),
                      ),
                      trailing: history[index]['appType'] == 'dispatcher'
                          ? const Chip(
                              label: Text(
                                'DSM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.0,
                                ),
                              ),
                              backgroundColor: Colors.teal,
                              padding: EdgeInsets.symmetric(horizontal: 4.0),
                            )
                          : null,
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(translationProvider.translate('close')),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.0,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return 'Unknown';

    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final formatter = DateFormat('MMM d, yyyy HH:mm:ss');
    return formatter.format(dateTime);
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'superadmin':
        return Colors.red;
      case 'admin':
        return Colors.blue;
      case 'dispatcher':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'superadmin':
        return Icons.security;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'dispatcher':
        return Icons.delivery_dining;
      default:
        return Icons.person;
    }
  }

  String _getRoleName(String? role) {
    switch (role) {
      case 'superadmin':
        return 'Super Administrator';
      case 'admin':
        return 'Administrator';
      case 'dispatcher':
        return 'Dispatcher';
      default:
        return 'Unknown';
    }
  }
}
