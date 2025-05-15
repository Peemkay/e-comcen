import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_theme.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final AuthService _authService = AuthService();
  final SettingsService _settingsService = SettingsService();
  bool _isLoading = true;
  String? _errorMessage;
  
  // Security settings
  bool _enforceStrongPasswords = true;
  bool _enableTwoFactorAuth = false;
  bool _requirePasswordChange = true;
  int _passwordExpiryDays = 90;
  bool _preventPasswordReuse = true;
  int _passwordHistoryCount = 5;
  bool _enableIpRestriction = false;
  List<String> _allowedIpAddresses = [];
  String _newIpAddress = '';
  bool _enableEncryption = true;
  String _encryptionLevel = 'AES-256';
  
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
      // Check if user has permission to access security settings
      if (!_authService.hasPermission(Permission.manageUserPrivileges)) {
        setState(() {
          _errorMessage = 'You do not have permission to access security settings';
          _isLoading = false;
        });
        return;
      }
      
      // Load settings from service
      final settings = await _settingsService.getSecuritySettings();
      
      setState(() {
        _enforceStrongPasswords = settings.enforceStrongPasswords;
        _enableTwoFactorAuth = settings.enableTwoFactorAuth;
        _requirePasswordChange = settings.requirePasswordChange;
        _passwordExpiryDays = settings.passwordExpiryDays;
        _preventPasswordReuse = settings.preventPasswordReuse;
        _passwordHistoryCount = settings.passwordHistoryCount;
        _enableIpRestriction = settings.enableIpRestriction;
        _allowedIpAddresses = List.from(settings.allowedIpAddresses);
        _enableEncryption = settings.enableEncryption;
        _encryptionLevel = settings.encryptionLevel;
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
      // Check if user has permission to modify security settings
      if (!_authService.hasPermission(Permission.manageUserPrivileges)) {
        setState(() {
          _errorMessage = 'You do not have permission to modify security settings';
          _isLoading = false;
        });
        return;
      }
      
      // Create settings object
      final settings = SecuritySettings(
        enforceStrongPasswords: _enforceStrongPasswords,
        enableTwoFactorAuth: _enableTwoFactorAuth,
        requirePasswordChange: _requirePasswordChange,
        passwordExpiryDays: _passwordExpiryDays,
        preventPasswordReuse: _preventPasswordReuse,
        passwordHistoryCount: _passwordHistoryCount,
        enableIpRestriction: _enableIpRestriction,
        allowedIpAddresses: _allowedIpAddresses,
        enableEncryption: _enableEncryption,
        encryptionLevel: _encryptionLevel,
      );
      
      // Save settings
      await _settingsService.saveSecuritySettings(settings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security settings saved successfully'),
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
  
  void _addIpAddress() {
    if (_newIpAddress.isEmpty) return;
    
    // Simple IP validation
    final ipRegex = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');
    if (!ipRegex.hasMatch(_newIpAddress)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid IP address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      if (!_allowedIpAddresses.contains(_newIpAddress)) {
        _allowedIpAddresses.add(_newIpAddress);
      }
      _newIpAddress = '';
    });
  }
  
  void _removeIpAddress(String ip) {
    setState(() {
      _allowedIpAddresses.remove(ip);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
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
                        // Security Classification Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.security, color: Colors.red),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'These settings control critical security features of the application. Changes should only be made by authorized personnel.',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Password Policy Section
                        _buildSectionHeader('Password Policy', FontAwesomeIcons.lock),
                        const SizedBox(height: 16),
                        
                        // Enforce Strong Passwords
                        SwitchListTile(
                          title: const Text('Enforce Strong Passwords'),
                          subtitle: const Text('Require complex passwords with minimum requirements'),
                          value: _enforceStrongPasswords,
                          onChanged: (value) {
                            setState(() {
                              _enforceStrongPasswords = value;
                            });
                          },
                        ),
                        
                        // Require Password Change
                        SwitchListTile(
                          title: const Text('Require Periodic Password Change'),
                          subtitle: const Text('Force users to change passwords periodically'),
                          value: _requirePasswordChange,
                          onChanged: (value) {
                            setState(() {
                              _requirePasswordChange = value;
                            });
                          },
                        ),
                        
                        // Password Expiry Days
                        if (_requirePasswordChange) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Password Expiry (days)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              initialValue: _passwordExpiryDays.toString(),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a value';
                                }
                                final days = int.tryParse(value);
                                if (days == null || days < 1) {
                                  return 'Please enter a valid number greater than 0';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                final days = int.tryParse(value);
                                if (days != null && days > 0) {
                                  setState(() {
                                    _passwordExpiryDays = days;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Prevent Password Reuse
                        SwitchListTile(
                          title: const Text('Prevent Password Reuse'),
                          subtitle: const Text('Prevent users from reusing previous passwords'),
                          value: _preventPasswordReuse,
                          onChanged: (value) {
                            setState(() {
                              _preventPasswordReuse = value;
                            });
                          },
                        ),
                        
                        // Password History Count
                        if (_preventPasswordReuse) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Password History Count',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.history),
                              ),
                              initialValue: _passwordHistoryCount.toString(),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a value';
                                }
                                final count = int.tryParse(value);
                                if (count == null || count < 1) {
                                  return 'Please enter a valid number greater than 0';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                final count = int.tryParse(value);
                                if (count != null && count > 0) {
                                  setState(() {
                                    _passwordHistoryCount = count;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        const Divider(),
                        
                        // Authentication Section
                        _buildSectionHeader('Authentication', FontAwesomeIcons.userShield),
                        const SizedBox(height: 16),
                        
                        // Enable Two-Factor Authentication
                        SwitchListTile(
                          title: const Text('Enable Two-Factor Authentication'),
                          subtitle: const Text('Require additional verification during login'),
                          value: _enableTwoFactorAuth,
                          onChanged: (value) {
                            setState(() {
                              _enableTwoFactorAuth = value;
                            });
                          },
                        ),
                        
                        const Divider(),
                        
                        // Access Control Section
                        _buildSectionHeader('Access Control', FontAwesomeIcons.shieldHalved),
                        const SizedBox(height: 16),
                        
                        // Enable IP Restriction
                        SwitchListTile(
                          title: const Text('Enable IP Restriction'),
                          subtitle: const Text('Restrict access to specific IP addresses'),
                          value: _enableIpRestriction,
                          onChanged: (value) {
                            setState(() {
                              _enableIpRestriction = value;
                            });
                          },
                        ),
                        
                        // IP Address List
                        if (_enableIpRestriction) ...[
                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Allowed IP Addresses:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // IP Address Input
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Add IP Address',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.computer),
                                      hintText: 'e.g., 192.168.1.1',
                                    ),
                                    onChanged: (value) {
                                      _newIpAddress = value;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _addIpAddress,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // IP Address Chips
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _allowedIpAddresses.map((ip) {
                                return Chip(
                                  label: Text(ip),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () => _removeIpAddress(ip),
                                  backgroundColor: AppTheme.primaryColor.withAlpha(50),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        const Divider(),
                        
                        // Data Protection Section
                        _buildSectionHeader('Data Protection', FontAwesomeIcons.shieldHeart),
                        const SizedBox(height: 16),
                        
                        // Enable Encryption
                        SwitchListTile(
                          title: const Text('Enable Data Encryption'),
                          subtitle: const Text('Encrypt sensitive data in the database'),
                          value: _enableEncryption,
                          onChanged: (value) {
                            setState(() {
                              _enableEncryption = value;
                            });
                          },
                        ),
                        
                        // Encryption Level
                        if (_enableEncryption) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Encryption Level',
                                border: OutlineInputBorder(),
                              ),
                              value: _encryptionLevel,
                              items: ['AES-128', 'AES-192', 'AES-256', 'RSA-2048']
                                  .map((level) => DropdownMenuItem(
                                        value: level,
                                        child: Text(level),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _encryptionLevel = value;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                            'Are you sure you want to reset all security settings to their default values?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _settingsService.resetSecuritySettings();
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
