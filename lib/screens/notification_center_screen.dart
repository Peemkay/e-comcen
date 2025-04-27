import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification.dart';
import '../widgets/notifications/notification_card.dart';
import '../constants/app_theme.dart';

/// Screen that displays all notifications
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({Key? key}) : super(key: key);

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _expandedNotificationId;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshNotifications();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Refresh notifications
  Future<void> _refreshNotifications() async {
    setState(() {
      _isLoading = true;
    });
    
    await Provider.of<NotificationProvider>(context, listen: false)
        .refreshNotifications();
    
    setState(() {
      _isLoading = false;
    });
  }
  
  // Mark notification as read
  Future<void> _markAsRead(String notificationId) async {
    await Provider.of<NotificationProvider>(context, listen: false)
        .markAsRead(notificationId);
  }
  
  // Delete notification
  Future<void> _deleteNotification(String notificationId) async {
    await Provider.of<NotificationProvider>(context, listen: false)
        .deleteNotification(notificationId);
  }
  
  // Mark all notifications as read
  Future<void> _markAllAsRead() async {
    await Provider.of<NotificationProvider>(context, listen: false)
        .markAllAsRead();
  }
  
  // Clear all notifications
  Future<void> _clearAllNotifications() async {
    await Provider.of<NotificationProvider>(context, listen: false)
        .clearAllNotifications();
  }
  
  // Toggle expanded notification
  void _toggleExpandedNotification(String notificationId) {
    setState(() {
      if (_expandedNotificationId == notificationId) {
        _expandedNotificationId = null;
      } else {
        _expandedNotificationId = notificationId;
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Mark all as read
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
          ),
          
          // Clear all
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear all',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Notifications'),
                  content: const Text(
                    'Are you sure you want to clear all notifications? '
                    'This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () {
                        _clearAllNotifications();
                        Navigator.of(context).pop();
                      },
                      child: const Text('CLEAR ALL'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'Important'),
          ],
          indicatorColor: AppTheme.accentColor,
          labelColor: AppTheme.accentColor,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: Consumer<NotificationProvider>(
                builder: (context, notificationProvider, _) {
                  final allNotifications = notificationProvider.notifications;
                  
                  if (allNotifications.isEmpty) {
                    return const Center(
                      child: Text(
                        'No notifications',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16.0,
                        ),
                      ),
                    );
                  }
                  
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // All notifications
                      _buildNotificationList(allNotifications),
                      
                      // Unread notifications
                      _buildNotificationList(
                        allNotifications.where(
                          (n) => n.status == NotificationStatus.unread
                        ).toList(),
                      ),
                      
                      // Important notifications
                      _buildNotificationList(
                        allNotifications.where(
                          (n) => n.priority == NotificationPriority.high || 
                                n.priority == NotificationPriority.urgent
                        ).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
  
  // Build notification list
  Widget _buildNotificationList(List<AppNotification> notifications) {
    if (notifications.isEmpty) {
      return const Center(
        child: Text(
          'No notifications',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16.0,
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return NotificationCard(
          notification: notification,
          isExpanded: _expandedNotificationId == notification.id,
          onTap: () {
            _markAsRead(notification.id);
            _toggleExpandedNotification(notification.id);
          },
          onDismiss: () => _deleteNotification(notification.id),
        );
      },
    );
  }
}
