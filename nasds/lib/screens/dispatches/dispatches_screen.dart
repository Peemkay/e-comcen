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
    // Get responsive values
    final isSmallScreen = ResponsiveUtil.isMobile(context);
    final gridColumns = ResponsiveUtil.getGridColumns(context);
    final spacing = ResponsiveUtil.getSpacing(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'E-COMCEN Dispatches',
          style: TextStyle(
            fontSize: ResponsiveUtil.getFontSize(context, 18),
          ),
        ),
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
                  behavior: SnackBarBehavior.floating,
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
          padding: ResponsiveUtil.getScreenPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Dispatch Categories',
                style: TextStyle(
                  fontSize: ResponsiveUtil.getFontSize(context, 22),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: spacing * 0.5),
              Text(
                'Select a category to manage dispatches',
                style: TextStyle(
                  fontSize: ResponsiveUtil.getFontSize(context, 14),
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: spacing * 1.5),

              // Dispatch Category Cards
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridColumns,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio:
                        ResponsiveUtil.getCardAspectRatio(context),
                  ),
                  itemCount: _getDispatchCategories().length,
                  itemBuilder: (context, index) {
                    final category = _getDispatchCategories()[index];
                    return _buildDispatchCategoryCard(
                      title: category['title'] as String,
                      icon: category['icon'] as IconData,
                      color: category['color'] as Color,
                      count: category['count'] as int,
                      description: category['description'] as String?,
                      onTap: () =>
                          _navigateToScreen(category['screen'] as Widget),
                    );
                  },
                ),
              ),

              // Summary Section
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.symmetric(vertical: spacing * 0.5),
                child: Padding(
                  padding: EdgeInsets.all(spacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dispatch Summary',
                        style: TextStyle(
                          fontSize: ResponsiveUtil.getFontSize(context, 16),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      SizedBox(height: spacing * 0.75),

                      // For mobile: use a grid with 2 columns
                      isSmallScreen
                          ? GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              childAspectRatio: 1.8,
                              mainAxisSpacing: spacing * 0.5,
                              crossAxisSpacing: spacing * 0.5,
                              children: _buildSummaryItems(),
                            )
                          // For larger screens: use a row
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: _buildSummaryItems(),
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

  // Get dispatch categories data
  List<Map<String, dynamic>> _getDispatchCategories() {
    return [
      {
        'title': 'Incoming Dispatch',
        'icon': FontAwesomeIcons.envelopeOpenText,
        'color': Colors.blue,
        'count': _dispatchService.getIncomingDispatches().length,
        'description': 'Manage incoming dispatches from other units',
        'screen': const IncomingDispatchScreen(),
      },
      {
        'title': 'TRANSIT',
        'icon': FontAwesomeIcons.paperPlane,
        'color': Colors.green,
        'count': _dispatchService.getOutgoingDispatches().length,
        'description': 'Manage outgoing dispatches to other units',
        'screen': const OutgoingDispatchScreen(),
      },
      {
        'title': 'Local Dispatch',
        'icon': FontAwesomeIcons.buildingUser,
        'color': Colors.orange,
        'count': _dispatchService.getLocalDispatches().length,
        'description': 'Manage dispatches within the unit',
        'screen': const LocalDispatchScreen(),
      },
      {
        'title': 'External Dispatch',
        'icon': FontAwesomeIcons.globe,
        'color': Colors.purple,
        'count': _dispatchService.getExternalDispatches().length,
        'description': 'Manage dispatches to external organizations',
        'screen': const ExternalDispatchScreen(),
      },
      {
        'title': 'COMCEN Log',
        'icon': FontAwesomeIcons.clipboardList,
        'color': Colors.red,
        'count': _dispatchService.getComcenLogs().length,
        'description': 'View communication center logs',
        'screen': const ComcenLogScreen(),
      },
      {
        'title': 'Track Dispatch',
        'icon': FontAwesomeIcons.magnifyingGlass,
        'color': Colors.teal,
        'count': 0,
        'description': 'Track dispatches by reference number',
        'screen': const DispatchTrackingDialog(),
      },
    ];
  }

  // Build summary items
  List<Widget> _buildSummaryItems() {
    return [
      _buildSummaryItem(
        'Total',
        _dispatchService.getIncomingDispatches().length +
            _dispatchService.getOutgoingDispatches().length +
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
    ];
  }

  Widget _buildDispatchCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
    String? description,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get responsive values
        final isSmallScreen = ResponsiveUtil.isMobile(context);
        final iconSize = ResponsiveUtil.getIconSize(context, factor: 1.2);
        final spacing = ResponsiveUtil.getSpacing(context);

        // Adjust text sizes based on available width
        final titleSize = ResponsiveUtil.getFontSize(
            context, constraints.maxWidth < 180 ? 13 : 15);
        final countSize = ResponsiveUtil.getFontSize(context, 13);
        final descSize = ResponsiveUtil.getFontSize(context, 11);

        return Card(
          elevation: 2,
          shadowColor: color.withAlpha(40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withAlpha(15),
                    Colors.white,
                  ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon with background
                    Container(
                      padding: EdgeInsets.all(spacing * 0.75),
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: iconSize,
                        color: color,
                      ),
                    ),
                    SizedBox(height: spacing * 0.75),

                    // Title with count badge
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (count > 0) ...[
                          SizedBox(width: spacing * 0.5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              count.toString(),
                              style: TextStyle(
                                fontSize: countSize,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Description
                    if (description != null && !isSmallScreen) ...[
                      SizedBox(height: spacing * 0.5),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: descSize,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Action hint
                    SizedBox(height: spacing * 0.75),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          FontAwesomeIcons.arrowRight,
                          size: 10,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'View',
                          style: TextStyle(
                            fontSize: descSize,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(
      String title, int count, IconData icon, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get responsive values
        final iconSize = ResponsiveUtil.getIconSize(context, factor: 0.8);
        final spacing = ResponsiveUtil.getSpacing(context);

        // Adjust text sizes based on available width
        final countSize = ResponsiveUtil.getFontSize(context, 16);
        final titleSize = ResponsiveUtil.getFontSize(context, 12);

        return Container(
          padding: EdgeInsets.all(spacing * 0.5),
          decoration: BoxDecoration(
            color: color.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withAlpha(30),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with subtle background
              Container(
                padding: EdgeInsets.all(spacing * 0.5),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: iconSize,
                ),
              ),
              SizedBox(height: spacing * 0.5),

              // Count with animation effect
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: count),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: countSize,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  );
                },
              ),

              SizedBox(height: spacing * 0.25),

              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        );
      },
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
