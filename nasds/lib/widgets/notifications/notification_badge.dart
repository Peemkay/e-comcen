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
  
  const NotificationBadge({
    Key? key,
    required this.child,
    this.size = 18.0,
    this.badgeColor,
    this.textColor,
    this.onTap,
    this.showZero = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        final count = notificationProvider.unreadCount;
        
        if (count == 0 && !showZero) {
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
                      count > 99 ? '99+' : count.toString(),
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
