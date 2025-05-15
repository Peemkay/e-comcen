import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../constants/app_theme.dart';

/// A badge that shows the number of unread notifications
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final double size;
  final Color? badgeColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final bool showZero;
  final bool showBadge;
  final int? count;

  const NotificationBadge({
    super.key,
    required this.child,
    this.size = 18.0,
    this.badgeColor,
    this.textColor,
    this.onTap,
    this.showZero = false,
    this.showBadge = true,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        // Use provided count or get from provider
        final badgeCount = count ?? notificationProvider.unreadCount;

        // Don't show badge if count is 0 and showZero is false, or if showBadge is false
        if ((badgeCount == 0 && !showZero) || !showBadge) {
          return GestureDetector(
            onTap: onTap,
            child: child,
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: onTap,
              child: child,
            ),
            Positioned(
              right: -5,
              top: -5,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    color: badgeColor ?? AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(size / 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51), // 0.2 opacity
                        blurRadius: 1.0,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    minWidth: size,
                    minHeight: size,
                  ),
                  child: Center(
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: TextStyle(
                        color: textColor ?? Colors.white,
                        fontSize: size * 0.6,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
