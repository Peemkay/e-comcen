import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/device_management_provider.dart';
import '../providers/translation_provider.dart';
import '../models/device_info.dart';
import '../constants/app_theme.dart';
import '../constants/app_constants.dart';
import '../widgets/app_bar/custom_app_bar.dart';
import 'device_detail_screen.dart';

/// Screen for managing connected devices
class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshDevices();
  }

  Future<void> _refreshDevices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<DeviceManagementProvider>(context, listen: false)
          .refreshDevices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing devices: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeDevice(DeviceInfo device) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Provider.of<TranslationProvider>(context, listen: false)
            .translate('remove_device')),
        content: Text(Provider.of<TranslationProvider>(context, listen: false)
            .translate('remove_device_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(Provider.of<TranslationProvider>(context, listen: false)
                .translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(Provider.of<TranslationProvider>(context, listen: false)
                .translate('remove')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get provider before async operation
      final deviceProvider =
          Provider.of<DeviceManagementProvider>(context, listen: false);

      // Perform async operation
      final success = await deviceProvider.removeDevice(device.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  Provider.of<TranslationProvider>(context, listen: false)
                      .translate('device_removed')),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  Provider.of<TranslationProvider>(context, listen: false)
                      .translate('error_removing_device')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _setAsPrimary(DeviceInfo device) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success =
          await Provider.of<DeviceManagementProvider>(context, listen: false)
              .setDeviceAsPrimary(device.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  Provider.of<TranslationProvider>(context, listen: false)
                      .translate('primary_device_set')),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  Provider.of<TranslationProvider>(context, listen: false)
                      .translate('error_setting_primary')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _viewDeviceDetails(DeviceInfo device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceDetailScreen(device: device),
      ),
    );
  }

  void _addNewDevice() {
    Navigator.pushNamed(
      context,
      AppConstants.devicePairingRoute,
    ).then((_) => _refreshDevices());
  }

  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat.yMd().add_jm().format(dateTime);
  }

  String _getTimeSince(int timestamp) {
    final now = DateTime.now();
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat.yMd().format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final translationProvider = Provider.of<TranslationProvider>(context);
    final deviceProvider = Provider.of<DeviceManagementProvider>(context);
    final currentDevice = deviceProvider.currentDevice;
    final devices = deviceProvider.userDevices;

    return Scaffold(
      appBar: CustomAppBar(
        title: translationProvider.translate('my_devices'),
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshDevices,
              child: devices.isEmpty
                  ? _buildEmptyState(translationProvider)
                  : _buildDeviceList(
                      devices, currentDevice, translationProvider),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewDevice,
        tooltip: translationProvider.translate('add_device'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(TranslationProvider translationProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices,
            size: 80,
            color: Colors.grey.withAlpha(128), // 0.5 * 255 = 127.5 ≈ 128
          ),
          const SizedBox(height: 16),
          Text(
            translationProvider.translate('no_devices'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            translationProvider.translate('add_device_instructions'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addNewDevice,
            icon: const Icon(Icons.add),
            label: Text(translationProvider.translate('add_device')),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(
    List<DeviceInfo> devices,
    DeviceInfo? currentDevice,
    TranslationProvider translationProvider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        final isCurrentDevice =
            currentDevice != null && device.id == currentDevice.id;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: device.isPrimary
                ? BorderSide(color: AppTheme.primaryColor, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () => _viewDeviceDetails(device),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device header
                  Row(
                    children: [
                      _buildDeviceIcon(device),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              device.model,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrentDevice)
                        Chip(
                          label: Text(
                            translationProvider.translate('current'),
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: AppTheme.primaryColor
                              .withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
                          side: BorderSide(
                            color: AppTheme.primaryColor
                                .withAlpha(77), // 0.3 * 255 = 76.5 ≈ 77
                          ),
                        ),
                    ],
                  ),
                  const Divider(),

                  // Device details
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              Icons.access_time,
                              translationProvider.translate('last_active'),
                              _getTimeSince(
                                  device.lastSeen ?? device.connectedAt),
                            ),
                            const SizedBox(height: 4),
                            _buildDetailRow(
                              Icons.calendar_today,
                              translationProvider.translate('connected_on'),
                              _formatTimestamp(device.connectedAt),
                            ),
                            if (device.isPrimary) ...[
                              const SizedBox(height: 4),
                              _buildDetailRow(
                                Icons.star,
                                translationProvider.translate('primary_device'),
                                translationProvider.translate('yes'),
                                iconColor: Colors.amber,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Actions
                      Column(
                        children: [
                          if (!device.isPrimary)
                            IconButton(
                              icon: const Icon(Icons.star_border),
                              onPressed: () => _setAsPrimary(device),
                              tooltip: translationProvider
                                  .translate('set_as_primary'),
                              color: Colors.amber,
                            ),
                          if (!isCurrentDevice)
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeDevice(device),
                              tooltip: translationProvider
                                  .translate('remove_device'),
                              color: Colors.red,
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceIcon(DeviceInfo device) {
    IconData iconData;
    Color iconColor;

    switch (device.platform.toLowerCase()) {
      case 'android':
        iconData = Icons.phone_android;
        iconColor = Colors.green;
        break;
      case 'ios':
        iconData = Icons.phone_iphone;
        iconColor = Colors.blue;
        break;
      case 'windows':
        iconData = Icons.computer;
        iconColor = Colors.blue;
        break;
      case 'macos':
        iconData = Icons.laptop_mac;
        iconColor = Colors.grey;
        break;
      case 'linux':
        iconData = Icons.laptop;
        iconColor = Colors.orange;
        break;
      case 'web':
        iconData = Icons.web;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.devices_other;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        size: 28,
        color: iconColor,
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor ?? Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
