import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../services/dispatch_service.dart';
import '../../utils/responsive_util.dart';
import '../../widgets/dispatch_tracking_dialog.dart';
import 'outgoing_dispatch_screen.dart';
import 'local_dispatch_screen.dart';
import 'external_dispatch_screen.dart';
import 'comcen_log_screen.dart';
import 'trash_dispatch_screen.dart';
import 'track_dispatch_screen.dart';
import 'in_out_file_screen.dart';

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
    // Determine if we're on a mobile device
    final isMobile = ResponsiveUtil.isMobile(context);

    // Determine grid columns based on screen size
    final crossAxisCount = ResponsiveUtil.getValueForScreenType<int>(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );

    // Adjust padding based on screen size
    final padding = ResponsiveUtil.getValueForScreenType<EdgeInsets>(
      context: context,
      mobile: const EdgeInsets.all(12.0),
      tablet: const EdgeInsets.all(16.0),
      desktop: const EdgeInsets.all(24.0),
    );

    // Adjust font sizes based on screen size
    final headerFontSize = ResponsiveUtil.getFontSize(context, 24);
    final subheaderFontSize = ResponsiveUtil.getFontSize(context, 16);

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-COMCEN Dispatches'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          // Track dispatch button
          IconButton(
            icon: Icon(
              FontAwesomeIcons.magnifyingGlass,
              size: ResponsiveUtil.getIconSize(context, 18),
            ),
            onPressed: () => _showTrackingDialog(context),
            tooltip: 'Track Dispatch',
          ),

          // Help button
          IconButton(
            icon: Icon(
              FontAwesomeIcons.circleQuestion,
              size: ResponsiveUtil.getIconSize(context, 18),
            ),
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
          if (!isMobile) // Hide version on mobile to save space
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  'v${AppConstants.appVersion}',
                  style: TextStyle(
                    fontSize: ResponsiveUtil.getFontSize(context, 12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Dispatch Categories',
                style: TextStyle(
                  fontSize: headerFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a category to manage dispatches',
                style: TextStyle(
                  fontSize: subheaderFontSize,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),

              // Dispatch Category Cards
              Expanded(
                child: GridView.count(
                  physics: const ClampingScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: ResponsiveUtil.getValueForScreenType(
                    context: context,
                    mobile: 1.1,
                    tablet: 1.2,
                    desktop: 1.3,
                  ),
                  children: [
                    _buildDispatchCategoryCard(
                      title: 'IN & OUT FILE',
                      icon: FontAwesomeIcons.fileCircleCheck,
                      color: Colors.blue,
                      count: _dispatchService.getIncomingDispatches().length,
                      description:
                          'Manage incoming and outgoing file dispatches',
                      onTap: () => _navigateToScreen(const InOutFileScreen()),
                    ),
                    _buildDispatchCategoryCard(
                      title: 'TRANSIT',
                      icon: FontAwesomeIcons.paperPlane,
                      color: Colors.green,
                      count: _dispatchService.getOutgoingDispatches().length,
                      description:
                          'Transit outgoing from the unit to other external units',
                      onTap: () =>
                          _navigateToScreen(const OutgoingDispatchScreen()),
                    ),
                    _buildDispatchCategoryCard(
                      title: 'Local Dispatch',
                      icon: FontAwesomeIcons.buildingUser,
                      color: Colors.orange,
                      count: _dispatchService.getLocalDispatches().length,
                      description: 'Manage dispatches within the unit',
                      onTap: () =>
                          _navigateToScreen(const LocalDispatchScreen()),
                    ),
                    _buildDispatchCategoryCard(
                      title: 'External Dispatch',
                      icon: FontAwesomeIcons.globe,
                      color: Colors.purple,
                      count: _dispatchService.getExternalDispatches().length,
                      description: 'FOB and other organizations',
                      onTap: () =>
                          _navigateToScreen(const ExternalDispatchScreen()),
                    ),
                    _buildDispatchCategoryCard(
                      title: 'COMCEN Log',
                      icon: FontAwesomeIcons.clipboardList,
                      color: Colors.red,
                      count: _dispatchService.getComcenLogs().length,
                      description:
                          'Records on all activities and histories on daily basis',
                      onTap: () => _navigateToScreen(const ComcenLogScreen()),
                    ),
                    _buildDispatchCategoryCard(
                      title: 'Trash',
                      icon: FontAwesomeIcons.trashCan,
                      color: Colors.grey,
                      count: _dispatchService.getTrashDispatches().length,
                      description:
                          'Deleted dispatches that can be restored or permanently deleted',
                      onTap: () =>
                          _navigateToScreen(const TrashDispatchScreen()),
                    ),
                    _buildDispatchCategoryCard(
                      title: 'Track Dispatch',
                      icon: FontAwesomeIcons.magnifyingGlass,
                      color: Colors.teal,
                      count: 0,
                      description:
                          'Track dispatches by reference number or internal reference',
                      onTap: () =>
                          _navigateToScreen(const TrackDispatchScreen()),
                    ),
                  ],
                ),
              ),

              // Summary Section
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Dispatch Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
    String? description,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: color,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      String title, int count, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) {
      setState(() {});
    });
  }

  // Count pending dispatches (not completed or delivered)
  int _countPendingDispatches() {
    int count = 0;

    // Count incoming dispatches
    count += _dispatchService
        .getIncomingDispatches()
        .where((d) =>
            d.status.toLowerCase() != 'completed' &&
            d.status.toLowerCase() != 'delivered' &&
            d.status.toLowerCase() != 'received')
        .length;

    // Count outgoing dispatches
    count += _dispatchService
        .getOutgoingDispatches()
        .where((d) =>
            d.status.toLowerCase() != 'completed' &&
            d.status.toLowerCase() != 'delivered')
        .length;

    // Count local dispatches
    count += _dispatchService
        .getLocalDispatches()
        .where((d) => d.status.toLowerCase() != 'completed')
        .length;

    // Count external dispatches
    count += _dispatchService
        .getExternalDispatches()
        .where((d) => d.status.toLowerCase() != 'completed')
        .length;

    return count;
  }

  // Count completed dispatches
  int _countCompletedDispatches() {
    int count = 0;

    // Count incoming dispatches
    count += _dispatchService
        .getIncomingDispatches()
        .where((d) =>
            d.status.toLowerCase() == 'completed' ||
            d.status.toLowerCase() == 'delivered' ||
            d.status.toLowerCase() == 'received')
        .length;

    // Count outgoing dispatches
    count += _dispatchService
        .getOutgoingDispatches()
        .where((d) =>
            d.status.toLowerCase() == 'completed' ||
            d.status.toLowerCase() == 'delivered')
        .length;

    // Count local dispatches
    count += _dispatchService
        .getLocalDispatches()
        .where((d) => d.status.toLowerCase() == 'completed')
        .length;

    // Count external dispatches
    count += _dispatchService
        .getExternalDispatches()
        .where((d) => d.status.toLowerCase() == 'completed')
        .length;

    return count;
  }

  // Count urgent dispatches
  int _countUrgentDispatches() {
    int count = 0;

    // Count incoming dispatches
    count += _dispatchService
        .getIncomingDispatches()
        .where((d) =>
            d.priority.toLowerCase() == 'urgent' ||
            d.priority.toLowerCase() == 'flash')
        .length;

    // Count outgoing dispatches
    count += _dispatchService
        .getOutgoingDispatches()
        .where((d) =>
            d.priority.toLowerCase() == 'urgent' ||
            d.priority.toLowerCase() == 'flash')
        .length;

    // Count local dispatches
    count += _dispatchService
        .getLocalDispatches()
        .where((d) =>
            d.priority.toLowerCase() == 'urgent' ||
            d.priority.toLowerCase() == 'flash')
        .length;

    // Count external dispatches
    count += _dispatchService
        .getExternalDispatches()
        .where((d) =>
            d.priority.toLowerCase() == 'urgent' ||
            d.priority.toLowerCase() == 'flash')
        .length;

    return count;
  }
}
