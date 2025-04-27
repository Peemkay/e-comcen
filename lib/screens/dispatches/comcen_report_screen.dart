import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../models/dispatch.dart';
import '../../services/dispatch_service.dart';

class ComcenReportScreen extends StatefulWidget {
  const ComcenReportScreen({super.key});

  @override
  State<ComcenReportScreen> createState() => _ComcenReportScreenState();
}

class _ComcenReportScreenState extends State<ComcenReportScreen> {
  final DispatchService _dispatchService = DispatchService();
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;
  String _timeRange = 'Last 7 Days';
  final List<String> _timeRanges = ['Last 24 Hours', 'Last 7 Days', 'Last 30 Days', 'All Time'];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final report = await _dispatchService.generateCommunicationStateReport();
      
      if (mounted) {
        setState(() {
          _reportData = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication State Report'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.arrowsRotate),
            onPressed: _loadReport,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportData == null
              ? const Center(
                  child: Text(
                    'No report data available',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildTimeRangeSelector(),
                      const SizedBox(height: 16),
                      _buildStatisticsCard(),
                      const SizedBox(height: 16),
                      _buildRecentLogsCard(),
                      const SizedBox(height: 16),
                      _buildGenerateReportButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final status = _reportData!['currentStatus'] as String;
    final lastChecked = _reportData!['lastChecked'] as DateTime;
    final lastCheckedBy = _reportData!['lastCheckedBy'] as String;
    
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'Operational':
        statusColor = Colors.green;
        statusIcon = FontAwesomeIcons.circleCheck;
        break;
      case 'Down':
        statusColor = Colors.red;
        statusIcon = FontAwesomeIcons.circleXmark;
        break;
      case 'Intermittent':
        statusColor = Colors.orange;
        statusIcon = FontAwesomeIcons.circleExclamation;
        break;
      case 'Under Maintenance':
        statusColor = Colors.blue;
        statusIcon = FontAwesomeIcons.screwdriverWrench;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = FontAwesomeIcons.circleQuestion;
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FontAwesomeIcons.towerBroadcast, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Current Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last checked: ${DateFormat('dd MMM yyyy HH:mm').format(lastChecked)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'By: $lastCheckedBy',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _timeRanges.map((range) {
                  final isSelected = _timeRange == range;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(range),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _timeRange = range;
                          });
                        }
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: AppTheme.primaryColor.withAlpha(50),
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final uptimePercentage = _reportData!['uptimePercentage'] as double;
    final totalChecks = _reportData!['totalChecks'] as int;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Uptime',
                  '${uptimePercentage.toStringAsFixed(1)}%',
                  FontAwesomeIcons.arrowUp,
                  Colors.green,
                ),
                _buildStatItem(
                  'Checks',
                  '$totalChecks',
                  FontAwesomeIcons.clipboardCheck,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Downtime',
                  '${(100 - uptimePercentage).toStringAsFixed(1)}%',
                  FontAwesomeIcons.arrowDown,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentLogsCard() {
    final logs = _reportData!['logs'] as List<DispatchLog>;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Communication Logs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            logs.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No communication logs found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length > 5 ? 5 : logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return ListTile(
                        leading: const Icon(FontAwesomeIcons.towerBroadcast, size: 20),
                        title: Text(log.action),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy HH:mm').format(log.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              log.notes,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        trailing: Text(
                          log.performedBy,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    },
                  ),
            if (logs.length > 5)
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: () {
                    // Show all logs in a dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('All Communication Logs'),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              final log = logs[index];
                              return ListTile(
                                leading: const Icon(FontAwesomeIcons.towerBroadcast, size: 20),
                                title: Text(log.action),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('dd MMM yyyy HH:mm').format(log.timestamp),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      log.notes,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  log.performedBy,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(FontAwesomeIcons.list, size: 16),
                  label: const Text('View All Logs'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateReportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Show a dialog indicating the report is being generated
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Generate Report'),
              content: const Text('This would generate a detailed communication state report for the selected time period. The report would be available for download or sharing.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report generation functionality would be implemented here'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Generate'),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: const Icon(FontAwesomeIcons.fileExport),
        label: const Text('Generate Detailed Report'),
      ),
    );
  }
}
