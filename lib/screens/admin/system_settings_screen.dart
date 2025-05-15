import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final AuthService _authService = AuthService();
  final SettingsService _settingsService = SettingsService();
  bool _isLoading = true;
  String? _errorMessage;
  
  // System settings
  bool _enableAutoBackup = true;
  String _backupFrequency = 'Daily';
  bool _enableDataCompression = true;
  bool _enableDebugMode = false;
  int _sessionTimeoutMinutes = 30;
  int _maxLoginAttempts = 5;
  int _lockoutDurationMinutes = 30;
  bool _enableAuditLogging = true;
  
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
      // Check if user has permission to access system settings
      if (!_authService.hasPermission(Permission.manageAdmin)) {
        setState(() {
          _errorMessage = 'You do not have permission to access system settings';
          _isLoading = false;
        });
        return;
      }
      
      // Load settings from service
      final settings = await _settingsService.getSystemSettings();
      
      setState(() {
        _enableAutoBackup = settings.enableAutoBackup;
        _backupFrequency = settings.backupFrequency;
        _enableDataCompression = settings.enableDataCompression;
        _enableDebugMode = settings.enableDebugMode;
        _sessionTimeoutMinutes = settings.sessionTimeoutMinutes;
        _maxLoginAttempts = settings.maxLoginAttempts;
        _lockoutDurationMinutes = settings.lockoutDurationMinutes;
        _enableAuditLogging = settings.enableAuditLogging;
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
      // Check if user has permission to modify system settings
      if (!_authService.hasPermission(Permission.manageAdmin)) {
        setState(() {
          _errorMessage = 'You do not have permission to modify system settings';
          _isLoading = false;
        });
        return;
      }
      
      // Create settings object
      final settings = SystemSettings(
        enableAutoBackup: _enableAutoBackup,
        backupFrequency: _backupFrequency,
        enableDataCompression: _enableDataCompression,
        enableDebugMode: _enableDebugMode,
        sessionTimeoutMinutes: _sessionTimeoutMinutes,
        maxLoginAttempts: _maxLoginAttempts,
        lockoutDurationMinutes: _lockoutDurationMinutes,
        enableAuditLogging: _enableAuditLogging,
      );
      
      // Save settings
      await _settingsService.saveSystemSettings(settings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('System settings saved successfully'),
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
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
                        // Backup Settings Section
                        _buildSectionHeader('Backup Settings', Icons.backup),
                        const SizedBox(height: 16),
                        
                        // Enable Auto Backup
                        SwitchListTile(
                          title: const Text('Enable Automatic Backup'),
                          subtitle: const Text('Automatically backup system data'),
                          value: _enableAutoBackup,
                          onChanged: (value) {
                            setState(() {
                              _enableAutoBackup = value;
                            });
                          },
                        ),
                        
                        // Backup Frequency
                        if (_enableAutoBackup) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Backup Frequency',
                                border: OutlineInputBorder(),
                              ),
                              value: _backupFrequency,
                              items: ['Hourly', 'Daily', 'Weekly', 'Monthly']
                                  .map((frequency) => DropdownMenuItem(
                                        value: frequency,
                                        child: Text(frequency),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _backupFrequency = value;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Enable Data Compression
                        SwitchListTile(
                          title: const Text('Enable Data Compression'),
                          subtitle: const Text('Compress data to save storage space'),
                          value: _enableDataCompression,
                          onChanged: (value) {
                            setState(() {
                              _enableDataCompression = value;
                            });
                          },
                        ),
                        
                        const Divider(),
                        
                        // Debug Settings Section
                        _buildSectionHeader('Debug Settings', Icons.bug_report),
                        const SizedBox(height: 16),
                        
                        // Enable Debug Mode
                        SwitchListTile(
                          title: const Text('Enable Debug Mode'),
                          subtitle: const Text('Show additional debug information'),
                          value: _enableDebugMode,
                          onChanged: (value) {
                            setState(() {
                              _enableDebugMode = value;
                            });
                          },
                        ),
                        
                        const Divider(),
                        
                        // Security Settings Section
                        _buildSectionHeader('Security Settings', Icons.security),
                        const SizedBox(height: 16),
                        
                        // Session Timeout
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Session Timeout (minutes)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.timer),
                            ),
                            initialValue: _sessionTimeoutMinutes.toString(),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a value';
                              }
                              final timeout = int.tryParse(value);
                              if (timeout == null || timeout < 1) {
                                return 'Please enter a valid number greater than 0';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              final timeout = int.tryParse(value);
                              if (timeout != null && timeout > 0) {
                                setState(() {
                                  _sessionTimeoutMinutes = timeout;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Max Login Attempts
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Maximum Login Attempts',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.login),
                            ),
                            initialValue: _maxLoginAttempts.toString(),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a value';
                              }
                              final attempts = int.tryParse(value);
                              if (attempts == null || attempts < 1) {
                                return 'Please enter a valid number greater than 0';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              final attempts = int.tryParse(value);
                              if (attempts != null && attempts > 0) {
                                setState(() {
                                  _maxLoginAttempts = attempts;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Lockout Duration
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Lockout Duration (minutes)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock_clock),
                            ),
                            initialValue: _lockoutDurationMinutes.toString(),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a value';
                              }
                              final duration = int.tryParse(value);
                              if (duration == null || duration < 1) {
                                return 'Please enter a valid number greater than 0';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              final duration = int.tryParse(value);
                              if (duration != null && duration > 0) {
                                setState(() {
                                  _lockoutDurationMinutes = duration;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Enable Audit Logging
                        SwitchListTile(
                          title: const Text('Enable Audit Logging'),
                          subtitle: const Text('Log all user actions for security auditing'),
                          value: _enableAuditLogging,
                          onChanged: (value) {
                            setState(() {
                              _enableAuditLogging = value;
                            });
                          },
                        ),
                        
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
                                            'Are you sure you want to reset all system settings to their default values?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _settingsService.resetSystemSettings();
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
