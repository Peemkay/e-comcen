import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../models/dispatch_tracking.dart';
import '../../services/dispatch_service.dart';

class DispatchTrackingScreen extends StatefulWidget {
  final String dispatchId;
  final String dispatchType;

  const DispatchTrackingScreen({
    super.key,
    required this.dispatchId,
    required this.dispatchType,
  });

  @override
  State<DispatchTrackingScreen> createState() => _DispatchTrackingScreenState();
}

class _DispatchTrackingScreenState extends State<DispatchTrackingScreen> {
  final DispatchService _dispatchService = DispatchService();
  late List<EnhancedDispatchLog> _logs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrackingLogs();
  }

  Future<void> _loadTrackingLogs() async {
    setState(() => _isLoading = true);
    _logs = await _dispatchService.getDispatchTrackingLogs(
      widget.dispatchId,
      widget.dispatchType,
    );
    setState(() => _isLoading = false);
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return Colors.green;
      case 'updated':
        return Colors.blue;
      case 'received':
        return Colors.purple;
      case 'sent':
        return Colors.orange;
      case 'delivered':
        return Colors.teal;
      case 'completed':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTrackingCard(EnhancedDispatchLog log) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getActionColor(log.action)
                        .withAlpha(51), // 0.2 opacity (51/255)
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    log.action,
                    style: TextStyle(
                      color: _getActionColor(log.action),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd MMM yyyy HH:mm').format(log.timestamp),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Handler Information
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.userTag,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  '${log.performedBy.rank} ${log.performedBy.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${log.performedBy.role})',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.buildingUser,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  log.performedBy.department,
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),

            if (log.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                log.notes,
                style: const TextStyle(fontSize: 14),
              ),
            ],

            if (log.oldStatus != null && log.newStatus != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.rightLeft,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Status changed from ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    log.oldStatus!.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ' to ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    log.newStatus!.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],

            if (log.location != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.locationDot,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(log.location!),
                ],
              ),
            ],

            if (log.attachments != null && log.attachments!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: log.attachments!.map((attachment) {
                  return Chip(
                    avatar: const Icon(
                      FontAwesomeIcons.paperclip,
                      size: 12,
                    ),
                    label: Text(attachment),
                    backgroundColor: Colors.grey[200],
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatch Tracking'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.rotate),
            onPressed: _loadTrackingLogs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.clockRotateLeft,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No tracking information available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return _buildTrackingCard(_logs[index]);
                  },
                ),
    );
  }
}
