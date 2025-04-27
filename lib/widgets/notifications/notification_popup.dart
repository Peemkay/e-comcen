import 'package:flutter/material.dart';
import '../../models/notification.dart';
import '../../constants/app_theme.dart';

/// A popup that displays a notification
class NotificationPopup extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final Duration displayDuration;
  
  const NotificationPopup({
    Key? key,
    required this.notification,
    this.onTap,
    this.onDismiss,
    this.displayDuration = const Duration(seconds: 5),
  }) : super(key: key);
  
  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Create animations
    _slideAnimation = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    
    // Start animation
    _controller.forward();
    
    // Auto-dismiss after duration
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  // Dismiss the popup
  void _dismiss() {
    _controller.reverse().then((_) {
      if (widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: _slideAnimation.value,
          left: 16.0,
          right: 16.0,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(12.0),
              color: Colors.white,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: widget.notification.priority.color.withAlpha(51), // 0.2 opacity
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type icon
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: widget.notification.type.color.withAlpha(51), // 0.2 opacity
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Icon(
                          widget.notification.type.icon,
                          color: widget.notification.type.color,
                          size: 24.0,
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              widget.notification.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            
                            // Body
                            Text(
                              widget.notification.body,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14.0,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            // Actions
                            if (widget.notification.actions != null && 
                                widget.notification.actions!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Wrap(
                                  spacing: 8.0,
                                  children: widget.notification.actions!.map((action) {
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
                                        if (widget.onTap != null) {
                                          widget.onTap!();
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Close button
                      GestureDetector(
                        onTap: _dismiss,
                        child: Container(
                          padding: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16.0,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
