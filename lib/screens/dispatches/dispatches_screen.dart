import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../services/dispatch_service.dart';
import '../../utils/responsive_util.dart';
import '../../widgets/dispatch_tracking_dialog.dart';
import 'incoming_dispatch_screen.dart';
import 'outgoing_dispatch_screen.dart';
import 'local_dispatch_screen.dart';
import 'external_dispatch_screen.dart';
import 'comcen_log_screen.dart';
import 'trash_dispatch_screen.dart';
import 'track_dispatch_screen.dart';

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
              const SizedBox(height: 24),

              // Dispatch Category Cards - reduced size
              Expanded(
                child: GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10, // Reduced spacing
                  mainAxisSpacing: 10, // Reduced spacing
                  childAspectRatio: ResponsiveUtil.getValueForScreenType(
                    context: context,
                    mobile: 0.9, // Increased for better fit
                    tablet: 0.85, // Increased for better fit
                    desktop: 0.95, // Increased for better fit
                  ),
                  children: [
                    _buildDispatchCategoryCard(
                      title: 'Incoming Dispatch',
                      icon: FontAwesomeIcons.envelopeOpenText,
                      color: Colors.blue,
                      count: _dispatchService.getIncomingDispatches().length,
                      description:
                          'Transit incoming from other external units to the unit',
                      onTap: () =>
                          _navigateToScreen(const IncomingDispatchScreen()),
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

              // Summary Section - reduced size
              Card(
                elevation: 1, // Reduced elevation
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Smaller radius
                ),
                margin:
                    const EdgeInsets.symmetric(vertical: 8), // Smaller margin
                child: Padding(
                  padding: ResponsiveUtil.getValueForScreenType<EdgeInsets>(
                    context: context,
                    mobile: const EdgeInsets.all(8.0), // Reduced padding
                    tablet: const EdgeInsets.all(10.0), // Reduced padding
                    desktop: const EdgeInsets.all(12.0), // Reduced padding
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Prevent expansion
                    children: [
                      Text(
                        'Dispatch Summary',
                        style: TextStyle(
                          fontSize: ResponsiveUtil.getFontSize(
                              context, 16), // Smaller font
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8), // Reduced spacing
                      ResponsiveUtil.isMobile(context)
                          // For mobile: use a grid with 2 columns - optimized layout
                          ? GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              childAspectRatio: 1.8, // Increased for better fit
                              mainAxisSpacing: 4, // Reduced spacing
                              crossAxisSpacing: 4, // Reduced spacing
                              padding: EdgeInsets.zero, // Remove padding
                              children: [
                                _buildSummaryItem(
                                  'Total',
                                  _dispatchService
                                          .getIncomingDispatches()
                                          .length +
                                      _dispatchService
                                          .getOutgoingDispatches()
                                          .length +
                                      _dispatchService
                                          .getLocalDispatches()
                                          .length +
                                      _dispatchService
                                          .getExternalDispatches()
                                          .length,
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
                            )
                          // For tablet/desktop: use a more compact row
                          : Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .spaceEvenly, // More even spacing
                              crossAxisAlignment:
                                  CrossAxisAlignment.start, // Align to top
                              children: [
                                _buildSummaryItem(
                                  'Total',
                                  _dispatchService
                                          .getIncomingDispatches()
                                          .length +
                                      _dispatchService
                                          .getOutgoingDispatches()
                                          .length +
                                      _dispatchService
                                          .getLocalDispatches()
                                          .length +
                                      _dispatchService
                                          .getExternalDispatches()
                                          .length,
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
    return LayoutBuilder(builder: (context, constraints) {
      // Adjust sizes based on available width
      final isSmallCard = constraints.maxWidth < 180;
      final isMediumCard = constraints.maxWidth < 250 && !isSmallCard;

      // Responsive sizes - reduced overall
      final iconSize = ResponsiveUtil.getValueForScreenType<double>(
        context: context,
        mobile: isSmallCard ? 24 : (isMediumCard ? 28 : 32),
        tablet: isMediumCard ? 32 : 36,
        desktop: 40,
      );

      final titleFontSize = ResponsiveUtil.getValueForScreenType<double>(
        context: context,
        mobile: isSmallCard ? 12 : (isMediumCard ? 13 : 14),
        tablet: 14,
        desktop: 16,
      );

      final descriptionFontSize = ResponsiveUtil.getValueForScreenType<double>(
        context: context,
        mobile: isSmallCard ? 9 : (isMediumCard ? 10 : 11),
        tablet: 11,
        desktop: 12,
      );

      final countFontSize = ResponsiveUtil.getValueForScreenType<double>(
        context: context,
        mobile: isSmallCard ? 10 : (isMediumCard ? 11 : 12),
        tablet: 12,
        desktop: 14,
      );

      // Responsive padding - reduced overall
      final cardPadding = ResponsiveUtil.getValueForScreenType<EdgeInsets>(
        context: context,
        mobile: isSmallCard
            ? const EdgeInsets.all(6.0)
            : (isMediumCard
                ? const EdgeInsets.all(8.0)
                : const EdgeInsets.all(10.0)),
        tablet: const EdgeInsets.all(12.0),
        desktop: const EdgeInsets.all(16.0),
      );

      return Card(
        elevation: 2, // Reduced elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Smaller radius
        ),
        margin: const EdgeInsets.all(4), // Smaller margin
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8), // Match card radius
          child: Padding(
            padding: cardPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Prevent expansion
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color: color,
                ),
                SizedBox(height: isSmallCard ? 4 : 6), // Reduced spacing
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1, // Limit to one line
                  overflow: TextOverflow.ellipsis, // Handle overflow
                ),
                if (description != null) ...[
                  SizedBox(height: isSmallCard ? 2 : 4), // Reduced spacing
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: descriptionFontSize,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: isSmallCard ? 2 : 2, // Limit lines
                    overflow: TextOverflow.ellipsis, // Handle overflow
                  ),
                ],
                SizedBox(height: isSmallCard ? 4 : 6), // Reduced spacing
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallCard ? 6 : 8, // Reduced padding
                    vertical: isSmallCard ? 1 : 2, // Reduced padding
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(51), // 0.2 opacity
                    borderRadius: BorderRadius.circular(
                        isSmallCard ? 6 : 8), // Smaller radius
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: countFontSize,
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
    });
  }

  Widget _buildSummaryItem(
      String title, int count, IconData icon, Color color) {
    return LayoutBuilder(builder: (context, constraints) {
      // Determine if we're in a small container
      final isSmallContainer = constraints.maxWidth < 100;
      final isMediumContainer = constraints.maxWidth < 150 && !isSmallContainer;

      // Responsive sizes - reduced overall
      final iconSize = ResponsiveUtil.getValueForScreenType<double>(
        context: context,
        mobile: isSmallContainer ? 16 : (isMediumContainer ? 18 : 20),
        tablet: 22,
        desktop: 24,
      );

      final countFontSize = ResponsiveUtil.getValueForScreenType<double>(
        context: context,
        mobile: isSmallContainer ? 12 : (isMediumContainer ? 14 : 15),
        tablet: 16,
        desktop: 18,
      );

      final titleFontSize = ResponsiveUtil.getValueForScreenType<double>(
        context: context,
        mobile: isSmallContainer ? 9 : (isMediumContainer ? 10 : 11),
        tablet: 11,
        desktop: 12,
      );

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Prevent expansion
        children: [
          Icon(
            icon,
            color: color,
            size: iconSize,
          ),
          SizedBox(height: isSmallContainer ? 2 : 4), // Reduced spacing
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: countFontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: isSmallContainer ? 1 : 2), // Reduced spacing
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1, // Limit to one line
            overflow: TextOverflow.ellipsis, // Handle overflow
          ),
        ],
      );
    });
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
