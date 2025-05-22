import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_theme.dart';
import '../../services/dispatch_service.dart';
import '../../utils/responsive_util.dart';
import 'in_file_list_screen.dart';
import 'out_file_list_screen.dart';

class InOutFileScreen extends StatefulWidget {
  const InOutFileScreen({super.key});

  @override
  State<InOutFileScreen> createState() => _InOutFileScreenState();
}

class _InOutFileScreenState extends State<InOutFileScreen> {
  final DispatchService _dispatchService = DispatchService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Determine grid columns based on screen size
    final crossAxisCount = ResponsiveUtil.getValueForScreenType<int>(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 2,
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
        title: const Text('IN & OUT FILE'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Select File Type',
                style: TextStyle(
                  fontSize: headerFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose the type of file to manage',
                style: TextStyle(
                  fontSize: subheaderFontSize,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),

              // File Type Cards - more compact
              Expanded(
                child: GridView.count(
                  physics: const ClampingScrollPhysics(), // More stable physics
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10, // Reduced spacing
                  mainAxisSpacing: 10, // Reduced spacing
                  childAspectRatio: 1.4, // Increased for more compact height
                  children: [
                    _buildFileTypeCard(
                      title: 'IN FILE',
                      icon: FontAwesomeIcons.fileImport,
                      color: Colors.blue,
                      count: _dispatchService.getIncomingDispatches().length,
                      description: 'Manage incoming files from external units',
                      onTap: () => _navigateToScreen(const InFileListScreen()),
                    ),
                    _buildFileTypeCard(
                      title: 'OUT FILE',
                      icon: FontAwesomeIcons.fileExport,
                      color: Colors.green,
                      count: 0, // Will be updated when we implement OUT FILE
                      description: 'Manage outgoing files to external units',
                      onTap: () => _navigateToScreen(const OutFileListScreen()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileTypeCard({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
    String? description,
  }) {
    return Card(
      elevation: 2, // Reduced elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Smaller radius
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10), // Smaller radius
        child: Padding(
          padding: const EdgeInsets.all(12), // Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Prevent expansion
            children: [
              Icon(
                icon,
                size: 36, // Smaller icon
                color: color,
              ),
              const SizedBox(height: 8), // Reduced spacing
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16, // Smaller font
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (description != null) ...[
                const SizedBox(height: 4), // Reduced spacing
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12, // Smaller font
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8), // Reduced spacing
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, // Reduced padding
                  vertical: 2, // Reduced padding
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(51),
                  borderRadius: BorderRadius.circular(8), // Smaller radius
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 14, // Smaller font
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

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    ).then((_) => setState(() {}));
  }
}
