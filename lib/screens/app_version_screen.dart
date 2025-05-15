import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../services/settings_service.dart';

class AppVersionScreen extends StatefulWidget {
  const AppVersionScreen({super.key});

  @override
  State<AppVersionScreen> createState() => _AppVersionScreenState();
}

class _AppVersionScreenState extends State<AppVersionScreen> {
  bool _isLoading = true;
  bool _isCheckingForUpdates = false;
  bool _updateAvailable = false;
  String _appVersion = '';
  String _buildNumber = '';
  String _packageName = '';
  String _latestVersion = '';
  String _deviceInfo = '';
  String _osVersion = '';
  List<VersionHistoryItem> _versionHistory = [];

  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _loadVersionHistory();
  }

  Future<void> _loadAppInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get package info
      final packageInfo = await PackageInfo.fromPlatform();

      // Get device info
      final deviceInfo = await _getDeviceInfo();

      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
        _packageName = packageInfo.packageName;
        _deviceInfo = deviceInfo['deviceName'] ?? 'Unknown';
        _osVersion = deviceInfo['osVersion'] ?? 'Unknown';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _appVersion = AppConstants.appVersion;
        _buildNumber = '1';
        _packageName = 'ng.mil.nasignal.ecomcen';
        _deviceInfo = 'Unknown';
        _osVersion = 'Unknown';
        _isLoading = false;
      });
    }
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    final Map<String, String> deviceData = <String, String>{};

    try {
      if (Platform.isWindows) {
        deviceData['deviceName'] = 'Windows PC';
        deviceData['osVersion'] = 'Windows ${Platform.operatingSystemVersion}';
      } else {
        deviceData['deviceName'] = 'Unknown Device';
        deviceData['osVersion'] = Platform.operatingSystem;
      }
    } catch (e) {
      deviceData['deviceName'] = 'Unknown Device';
      deviceData['osVersion'] = 'Unknown OS';
    }

    return deviceData;
  }

  Future<void> _loadVersionHistory() async {
    try {
      final history = await _settingsService.getVersionHistory();
      setState(() {
        _versionHistory = List<VersionHistoryItem>.from(history);
      });
    } catch (e) {
      setState(() {
        _versionHistory = _getDefaultVersionHistory();
      });
    }
  }

  List<VersionHistoryItem> _getDefaultVersionHistory() {
    return [
      VersionHistoryItem(
        version: '2.5.0',
        releaseDate: DateTime(2023, 6, 15),
        changes: [
          'Added comprehensive user role management',
          'Implemented enhanced dispatch tracking features',
          'Added support for Nigerian languages',
          'Improved security features',
          'Fixed various bugs and performance issues',
        ],
      ),
      VersionHistoryItem(
        version: '2.0.0',
        releaseDate: DateTime(2023, 3, 10),
        changes: [
          'Complete UI redesign',
          'Added dispatch management system',
          'Implemented user authentication',
          'Added reporting features',
          'Improved performance and stability',
        ],
      ),
      VersionHistoryItem(
        version: '1.5.0',
        releaseDate: DateTime(2022, 11, 25),
        changes: [
          'Added support for multiple dispatch types',
          'Implemented basic tracking features',
          'Improved user interface',
          'Added basic reporting',
          'Fixed various bugs',
        ],
      ),
      VersionHistoryItem(
        version: '1.0.0',
        releaseDate: DateTime(2022, 7, 5),
        changes: [
          'Initial release',
          'Basic dispatch functionality',
          'User management',
          'Simple reporting',
        ],
      ),
    ];
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingForUpdates = true;
    });

    try {
      // Simulate checking for updates
      await Future.delayed(const Duration(seconds: 2));

      // For demo purposes, we'll pretend there's an update available
      setState(() {
        _updateAvailable = true;
        _latestVersion = '2.6.0';
        _isCheckingForUpdates = false;
      });
    } catch (e) {
      setState(() {
        _updateAvailable = false;
        _isCheckingForUpdates = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking for updates: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadUpdate() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Downloading Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Downloading update... Please wait.'),
          ],
        ),
      ),
    );

    // Simulate download
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.pop(context); // Close the download dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update Downloaded'),
          content: const Text(
              'The update has been downloaded. The application will restart to install the update.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _updateAvailable = false;
                  _appVersion = _latestVersion;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Update installed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Version'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Info Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                AppConstants.logoPath,
                                width: 80,
                                height: 80,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppConstants.appName,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    Text(
                                      AppConstants.appFullName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            'v$_appVersion',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Build $_buildNumber',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),

                          // System Information
                          const Text(
                            'System Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('Package Name', _packageName),
                          _buildInfoRow('Device', _deviceInfo),
                          _buildInfoRow('Operating System', _osVersion),
                          _buildInfoRow('Platform', AppConstants.appPlatform),

                          const SizedBox(height: 16),

                          // Check for Updates Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(_isCheckingForUpdates
                                  ? Icons.hourglass_empty
                                  : Icons.system_update),
                              label: Text(_isCheckingForUpdates
                                  ? 'Checking...'
                                  : 'Check for Updates'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: _isCheckingForUpdates
                                  ? null
                                  : _checkForUpdates,
                            ),
                          ),

                          // Update Available Notice
                          if (_updateAvailable) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.new_releases,
                                          color: Colors.green),
                                      SizedBox(width: 8),
                                      Text(
                                        'Update Available!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'A new version ($_latestVersion) is available. You are currently using version $_appVersion.',
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _downloadUpdate,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Download Update'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Version History
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Version History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Version History List
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _versionHistory.length,
                            itemBuilder: (context, index) {
                              final item = _versionHistory[index];
                              final isCurrentVersion =
                                  item.version == _appVersion;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isCurrentVersion
                                              ? AppTheme.primaryColor
                                              : Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          'v${item.version}',
                                          style: TextStyle(
                                            color: isCurrentVersion
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${item.releaseDate.day}/${item.releaseDate.month}/${item.releaseDate.year}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (isCurrentVersion) ...[
                                        const SizedBox(width: 8),
                                        const Text(
                                          '(Current)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: item.changes.map((change) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('• '),
                                              Expanded(child: Text(change)),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  if (index < _versionHistory.length - 1)
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
                                      child: Divider(),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Copyright Notice
                  Center(
                    child: Text(
                      '© ${AppConstants.currentYear} ${AppConstants.appOrganization}. All rights reserved.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class VersionHistoryItem {
  final String version;
  final DateTime releaseDate;
  final List<String> changes;

  VersionHistoryItem({
    required this.version,
    required this.releaseDate,
    required this.changes,
  });
}
