import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../services/dispatch_service.dart';
import '../../widgets/dispatch_tracking_dialog.dart';
import 'incoming_dispatch_screen.dart';
import 'outgoing_dispatch_screen.dart';
import 'local_dispatch_screen.dart';
import 'external_dispatch_screen.dart';
import 'comcen_log_screen.dart';

class DispatchesScreen extends StatefulWidget {
  const DispatchesScreen({super.key});

  @override
  State<DispatchesScreen> createState() => _DispatchesScreenState();
}

class _DispatchesScreenState extends State<DispatchesScreen> {
  final DispatchService _dispatchService = DispatchService();

  @override
  void initState() {
    super.initState();
    // Initialize the dispatch service with sample data
    _dispatchService.initialize();
  }

  // Show dispatch tracking dialog
  void _showTrackingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const DispatchTrackingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-COMCEN Dispatches'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          // Track dispatch button
          IconButton(
            icon: const Icon(FontAwesomeIcons.magnifyingGlass, size: 18),
            onPressed: () => _showTrackingDialog(context),
            tooltip: 'Track Dispatch',
          ),

          // Help button
          IconButton(
            icon: const Icon(FontAwesomeIcons.circleQuestion, size: 18),
            onPressed: () {
              // Show help
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help feature coming soon'),
                ),
              );
            },
            tooltip: 'Help',
          ),

          // Version info in the app bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'v${AppConstants.appVersion}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Dispatch Categories',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a category to manage dispatches',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Dispatch Category Cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildDispatchCategoryCard(
                      title: 'Incoming Dispatch',
                      icon: FontAwesomeIcons.envelopeOpenText,
                      color: Colors.blue,
                      count: _dispatchService.getIncomingDispatches().length,
                      onTap: () =>
                          _navigateToScreen(const IncomingDispatchScreen()),
                    ),
                    _buildDispatchCategoryCard(
                      title: 'Outgoing Dispatch',
                      icon: FontAwesomeIcons.paperPlane,
                      color: Colors.green,
                      count: _dispatchService.getOutgoingDispatches().length,
                      onTap: () =>
                          _navigateToScreen(const OutgoingDispatchScreen()),
                    ),
                    _buildDispatchCategoryCard(
                      title: 'Local Dispatch',
                      icon: FontAwesomeIcons.buildingUser,
                      color: Colors.orange,
                      count: _dispatchService.getLocalDispatches().length,
                      onTap: () =>
                          _navigateToScreen(const LocalDispatchScreen()),
                    ),
                    _buildDispatchCategoryCard(
                      title: 'External Dispatch',
                      icon: FontAwesomeIcons.globe,
                      color: Colors.purple,
                      count: _dispatchService.getExternalDispatches().length,
                      onTap: () =>
                          _navigateToScreen(const ExternalDispatchScreen()),
                    ),
                    _buildDispatchCategoryCard(
                      title: 'COMCEN Log',
                      icon: FontAwesomeIcons.clipboardList,
                      color: Colors.red,
                      count: _dispatchService.getComcenLogs().length,
                      onTap: () => _navigateToScreen(const ComcenLogScreen()),
                    ),
                  ],
                ),
              ),

              // Summary Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dispatch Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem(
                            'Total',
                            _dispatchService.getIncomingDispatches().length +
                                _dispatchService
                                    .getOutgoingDispatches()
                                    .length +
                                _dispatchService.getLocalDispatches().length +
                                _dispatchService.getExternalDispatches().length,
                            FontAwesomeIcons.envelopesBulk,
                            AppTheme.primaryColor,
                          ),
                          _buildSummaryItem(
                            'Pending',
                            _countPendingDispatches(),
                            FontAwesomeIcons.clock,
                            Colors.orange,
                          ),
                          _buildSummaryItem(
                            'Completed',
                            _countCompletedDispatches(),
                            FontAwesomeIcons.checkDouble,
                            Colors.green,
                          ),
                          _buildSummaryItem(
                            'Urgent',
                            _countUrgentDispatches(),
                            FontAwesomeIcons.bolt,
                            Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDispatchCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 40,
                    color: color,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withAlpha(51), // 0.2 opacity
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      String title, int count, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) {
      // Refresh the state when returning from the screen
      setState(() {});
    });
  }

  int _countPendingDispatches() {
    int count = 0;

    count += _dispatchService
        .getIncomingDispatches()
        .where((d) =>
            d.status.toLowerCase() == 'pending' ||
            d.status.toLowerCase() == 'in progress')
        .length;

    count += _dispatchService
        .getOutgoingDispatches()
        .where((d) =>
            d.status.toLowerCase() == 'pending' ||
            d.status.toLowerCase() == 'in progress')
        .length;

    count += _dispatchService
        .getLocalDispatches()
        .where((d) =>
            d.status.toLowerCase() == 'pending' ||
            d.status.toLowerCase() == 'in progress')
        .length;

    count += _dispatchService
        .getExternalDispatches()
        .where((d) =>
            d.status.toLowerCase() == 'pending' ||
            d.status.toLowerCase() == 'in progress')
        .length;

    return count;
  }

  int _countCompletedDispatches() {
    int count = 0;

    count += _dispatchService
        .getIncomingDispatches()
        .where((d) =>
            d.status.toLowerCase() == 'completed' ||
            d.status.toLowerCase() == 'delivered' ||
            d.status.toLowerCase() == 'received')
        .length;

    count += _dispatchService
        .getOutgoingDispatches()
        .where((d) =>
            d.status.toLowerCase() == 'completed' ||
            d.status.toLowerCase() == 'delivered')
        .length;

    count += _dispatchService
        .getLocalDispatches()
        .where((d) => d.status.toLowerCase() == 'completed')
        .length;

    count += _dispatchService
        .getExternalDispatches()
        .where((d) => d.status.toLowerCase() == 'completed')
        .length;

    return count;
  }

  int _countUrgentDispatches() {
    int count = 0;

    count += _dispatchService
        .getIncomingDispatches()
        .where((d) =>
            d.priority.toLowerCase() == 'urgent' ||
            d.priority.toLowerCase() == 'flash')
        .length;

    count += _dispatchService
        .getOutgoingDispatches()
        .where((d) =>
            d.priority.toLowerCase() == 'urgent' ||
            d.priority.toLowerCase() == 'flash')
        .length;

    count += _dispatchService
        .getLocalDispatches()
        .where((d) =>
            d.priority.toLowerCase() == 'urgent' ||
            d.priority.toLowerCase() == 'flash')
        .length;

    count += _dispatchService
        .getExternalDispatches()
        .where((d) =>
            d.priority.toLowerCase() == 'urgent' ||
            d.priority.toLowerCase() == 'flash')
        .length;

    return count;
  }
}
