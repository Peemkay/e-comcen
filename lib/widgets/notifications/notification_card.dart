import 'package:flutter/material.dart';
import '../../models/notification.dart';
import '../../constants/app_theme.dart';

/// A card that displays a notification
class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool isExpanded;
  
  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
    this.isExpanded = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) {
        if (onDismiss != null) {
          onDismiss!();
        }
      },
      child: Card(
        elevation: 2.0,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
            color: notification.status == NotificationStatus.unread
                ? notification.priority.color.withAlpha(51) // 0.2 opacity
                : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Type icon
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: notification.type.color.withAlpha(51), // 0.2 opacity
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        notification.type.icon,
                        color: notification.type.color,
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    
                    // Title and time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.status == NotificationStatus.unread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 16.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            notification.timeElapsed,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Priority indicator
                    if (notification.priority != NotificationPriority.normal)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: notification.priority.color.withAlpha(51), // 0.2 opacity
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              notification.priority.icon,
                              color: notification.priority.color,
                              size: 12.0,
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              notification.priority.displayName,
                              style: TextStyle(
                                color: notification.priority.color,
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                // Body
                Padding(
                  padding: const EdgeInsets.only(
                    left: 40.0,
                    top: 8.0,
                    right: 8.0,
                  ),
                  child: Text(
                    notification.body,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14.0,
                    ),
                    maxLines: isExpanded ? null : 2,
                    overflow: isExpanded ? null : TextOverflow.ellipsis,
                  ),
                ),
                
                // Actions
                if (notification.actions != null && notification.actions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 40.0,
                      top: 12.0,
                      right: 8.0,
                    ),
                    child: Wrap(
                      spacing: 8.0,
                      children: notification.actions!.map((action) {
                        return ActionChip(
                          label: Text(action.label),
                          backgroundColor: action.isDefault
                              ? AppTheme.primaryColor.withAlpha(51) // 0.2 opacity
                              : Colors.grey.shade200,
                          labelStyle: TextStyle(
                            color: action.isDefault
                                ? AppTheme.primaryColor
                                : Colors.grey.shade700,
                            fontWeight: action.isDefault
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onPressed: () {
                            // Handle action
                            if (onTap != null) {
                              onTap!();
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),
                
                // Status indicator
                if (notification.status == NotificationStatus.unread)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.only(top: 4.0, right: 4.0),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
