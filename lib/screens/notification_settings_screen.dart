import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final AuthService _authService = AuthService();
  final SettingsService _settingsService = SettingsService();
  bool _isLoading = true;
  String? _errorMessage;
  
  // Notification settings
  bool _enablePushNotifications = true;
  bool _enableEmailNotifications = true;
  bool _enableSoundAlerts = true;
  bool _enableVibration = true;
  bool _showNotificationPreview = true;
  
  // Notification types
  bool _notifyNewDispatch = true;
  bool _notifyDispatchUpdates = true;
  bool _notifyDispatchDelivered = true;
  bool _notifyDispatchDelayed = true;
  bool _notifySystemUpdates = false;
  bool _notifySecurityAlerts = true;
  
  // Do Not Disturb
  bool _enableDoNotDisturb = false;
  TimeOfDay _doNotDisturbStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _doNotDisturbEnd = const TimeOfDay(hour: 7, minute: 0);
  
  // Form key
  final _formKey = GlobalKey<FormState>();
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Load settings from service
      final settings = await _settingsService.getNotificationSettings();
      
      setState(() {
        _enablePushNotifications = settings.enablePushNotifications;
        _enableEmailNotifications = settings.enableEmailNotifications;
        _enableSoundAlerts = settings.enableSoundAlerts;
        _enableVibration = settings.enableVibration;
        _showNotificationPreview = settings.showNotificationPreview;
        
        _notifyNewDispatch = settings.notifyNewDispatch;
        _notifyDispatchUpdates = settings.notifyDispatchUpdates;
        _notifyDispatchDelivered = settings.notifyDispatchDelivered;
        _notifyDispatchDelayed = settings.notifyDispatchDelayed;
        _notifySystemUpdates = settings.notifySystemUpdates;
        _notifySecurityAlerts = settings.notifySecurityAlerts;
        
        _enableDoNotDisturb = settings.enableDoNotDisturb;
        _doNotDisturbStart = settings.doNotDisturbStart;
        _doNotDisturbEnd = settings.doNotDisturbEnd;
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading settings: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Create settings object
      final settings = NotificationSettings(
        enablePushNotifications: _enablePushNotifications,
        enableEmailNotifications: _enableEmailNotifications,
        enableSoundAlerts: _enableSoundAlerts,
        enableVibration: _enableVibration,
        showNotificationPreview: _showNotificationPreview,
        
        notifyNewDispatch: _notifyNewDispatch,
        notifyDispatchUpdates: _notifyDispatchUpdates,
        notifyDispatchDelivered: _notifyDispatchDelivered,
        notifyDispatchDelayed: _notifyDispatchDelayed,
        notifySystemUpdates: _notifySystemUpdates,
        notifySecurityAlerts: _notifySecurityAlerts,
        
        enableDoNotDisturb: _enableDoNotDisturb,
        doNotDisturbStart: _doNotDisturbStart,
        doNotDisturbEnd: _doNotDisturbEnd,
      );
      
      // Save settings
      await _settingsService.saveNotificationSettings(settings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving settings: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _selectDoNotDisturbStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _doNotDisturbStart,
    );
    if (picked != null && picked != _doNotDisturbStart) {
      setState(() {
        _doNotDisturbStart = picked;
      });
    }
  }
  
  Future<void> _selectDoNotDisturbEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _doNotDisturbEnd,
    );
    if (picked != null && picked != _doNotDisturbEnd) {
      setState(() {
        _doNotDisturbEnd = picked;
      });
    }
  }
  
  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSettings,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSettings,
            tooltip: 'Save',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSettings,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // General Notification Settings
                        _buildSectionHeader('General Settings', Icons.notifications),
                        const SizedBox(height: 16),
                        
                        // Enable Push Notifications
                        SwitchListTile(
                          title: const Text('Enable Push Notifications'),
                          subtitle: const Text('Receive notifications on your device'),
                          value: _enablePushNotifications,
                          onChanged: (value) {
                            setState(() {
                              _enablePushNotifications = value;
                            });
                          },
                        ),
                        
                        // Enable Email Notifications
                        SwitchListTile(
                          title: const Text('Enable Email Notifications'),
                          subtitle: const Text('Receive notifications via email'),
                          value: _enableEmailNotifications,
                          onChanged: (value) {
                            setState(() {
                              _enableEmailNotifications = value;
                            });
                          },
                        ),
                        
                        // Enable Sound Alerts
                        SwitchListTile(
                          title: const Text('Enable Sound Alerts'),
                          subtitle: const Text('Play sound when notifications arrive'),
                          value: _enableSoundAlerts,
                          onChanged: (value) {
                            setState(() {
                              _enableSoundAlerts = value;
                            });
                          },
                        ),
                        
                        // Enable Vibration
                        SwitchListTile(
                          title: const Text('Enable Vibration'),
                          subtitle: const Text('Vibrate when notifications arrive'),
                          value: _enableVibration,
                          onChanged: (value) {
                            setState(() {
                              _enableVibration = value;
                            });
                          },
                        ),
                        
                        // Show Notification Preview
                        SwitchListTile(
                          title: const Text('Show Notification Preview'),
                          subtitle: const Text('Show content preview in notifications'),
                          value: _showNotificationPreview,
                          onChanged: (value) {
                            setState(() {
                              _showNotificationPreview = value;
                            });
                          },
                        ),
                        
                        const Divider(),
                        
                        // Notification Types
                        _buildSectionHeader('Notification Types', Icons.category),
                        const SizedBox(height: 16),
                        
                        // New Dispatch
                        SwitchListTile(
                          title: const Text('New Dispatch'),
                          subtitle: const Text('Notify when a new dispatch is created'),
                          value: _notifyNewDispatch,
                          onChanged: (value) {
                            setState(() {
                              _notifyNewDispatch = value;
                            });
                          },
                        ),
                        
                        // Dispatch Updates
                        SwitchListTile(
                          title: const Text('Dispatch Updates'),
                          subtitle: const Text('Notify when a dispatch is updated'),
                          value: _notifyDispatchUpdates,
                          onChanged: (value) {
                            setState(() {
                              _notifyDispatchUpdates = value;
                            });
                          },
                        ),
                        
                        // Dispatch Delivered
                        SwitchListTile(
                          title: const Text('Dispatch Delivered'),
                          subtitle: const Text('Notify when a dispatch is delivered'),
                          value: _notifyDispatchDelivered,
                          onChanged: (value) {
                            setState(() {
                              _notifyDispatchDelivered = value;
                            });
                          },
                        ),
                        
                        // Dispatch Delayed
                        SwitchListTile(
                          title: const Text('Dispatch Delayed'),
                          subtitle: const Text('Notify when a dispatch is delayed'),
                          value: _notifyDispatchDelayed,
                          onChanged: (value) {
                            setState(() {
                              _notifyDispatchDelayed = value;
                            });
                          },
                        ),
                        
                        // System Updates
                        SwitchListTile(
                          title: const Text('System Updates'),
                          subtitle: const Text('Notify about system updates and maintenance'),
                          value: _notifySystemUpdates,
                          onChanged: (value) {
                            setState(() {
                              _notifySystemUpdates = value;
                            });
                          },
                        ),
                        
                        // Security Alerts
                        SwitchListTile(
                          title: const Text('Security Alerts'),
                          subtitle: const Text('Notify about security-related events'),
                          value: _notifySecurityAlerts,
                          onChanged: (value) {
                            setState(() {
                              _notifySecurityAlerts = value;
                            });
                          },
                        ),
                        
                        const Divider(),
                        
                        // Do Not Disturb
                        _buildSectionHeader('Do Not Disturb', Icons.do_not_disturb_on),
                        const SizedBox(height: 16),
                        
                        // Enable Do Not Disturb
                        SwitchListTile(
                          title: const Text('Enable Do Not Disturb'),
                          subtitle: const Text('Silence notifications during specified hours'),
                          value: _enableDoNotDisturb,
                          onChanged: (value) {
                            setState(() {
                              _enableDoNotDisturb = value;
                            });
                          },
                        ),
                        
                        if (_enableDoNotDisturb) ...[
                          const SizedBox(height: 16),
                          
                          // Do Not Disturb Start Time
                          ListTile(
                            title: const Text('Start Time'),
                            subtitle: Text(_formatTimeOfDay(_doNotDisturbStart)),
                            trailing: const Icon(Icons.access_time),
                            onTap: _selectDoNotDisturbStartTime,
                          ),
                          
                          // Do Not Disturb End Time
                          ListTile(
                            title: const Text('End Time'),
                            subtitle: Text(_formatTimeOfDay(_doNotDisturbEnd)),
                            trailing: const Icon(Icons.access_time),
                            onTap: _selectDoNotDisturbEndTime,
                          ),
                        ],
                        
                        const SizedBox(height: 32),
                        
                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveSettings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Save Settings',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Reset to Defaults Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Reset to Defaults'),
                                        content: const Text(
                                            'Are you sure you want to reset all notification settings to their default values?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _settingsService.resetNotificationSettings();
                                              _loadSettings();
                                            },
                                            style: TextButton.styleFrom(
                                                foregroundColor: Colors.red),
                                            child: const Text('Reset'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                            child: const Text('Reset to Defaults'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }
}
