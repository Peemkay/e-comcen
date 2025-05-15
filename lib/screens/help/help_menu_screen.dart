import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';

/// Screen that displays help and support options
class HelpMenuScreen extends StatelessWidget {
  const HelpMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(isSmallScreen),
            const SizedBox(height: 24),

            // Help options
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
                      'Help Resources',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildHelpItem(
                      'User Guide',
                      'View comprehensive user documentation',
                      FontAwesomeIcons.bookOpen,
                      () => _navigateToScreen(context, '/help/guide'),
                    ),
                    _buildHelpItem(
                      'Video Tutorials',
                      'Watch step-by-step video guides',
                      FontAwesomeIcons.video,
                      () => _navigateToScreen(context, '/help/tutorials'),
                    ),
                    _buildHelpItem(
                      'Frequently Asked Questions',
                      'Find answers to common questions',
                      FontAwesomeIcons.circleQuestion,
                      () => _showFAQs(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Support options
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
                      'Contact Support',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildHelpItem(
                      'Email Support',
                      'Send an email to our support team',
                      FontAwesomeIcons.envelope,
                      () => _launchEmail(),
                    ),
                    _buildHelpItem(
                      'Phone Support',
                      'Call our support hotline',
                      FontAwesomeIcons.phone,
                      () => _launchPhone(),
                    ),
                    _buildHelpItem(
                      'Report a Bug',
                      'Submit a bug report',
                      FontAwesomeIcons.bug,
                      () => _showBugReportDialog(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // About section
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
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildHelpItem(
                      'About E-COMCEN',
                      'Learn more about the application',
                      FontAwesomeIcons.circleInfo,
                      () => _navigateToScreen(context, '/about'),
                    ),
                    _buildHelpItem(
                      'Terms & Conditions',
                      'View terms of service',
                      FontAwesomeIcons.fileContract,
                      () => _navigateToScreen(context, '/terms'),
                    ),
                    _buildHelpItem(
                      'Privacy Policy',
                      'View our privacy policy',
                      FontAwesomeIcons.shield,
                      () => _navigateToScreen(context, '/privacy'),
                    ),
                    _buildHelpItem(
                      'Version Information',
                      'App version: ${AppConstants.appVersion}',
                      FontAwesomeIcons.code,
                      () => _showVersionInfo(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          FontAwesomeIcons.headset,
          size: isSmallScreen ? 48 : 64,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          'How can we help you?',
          style: TextStyle(
            fontSize: isSmallScreen ? 22 : 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Find help resources and contact support',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHelpItem(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(
                icon,
                size: 18,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  void _showFAQs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            const Center(
              child: Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              'How do I create a new dispatch?',
              'To create a new dispatch, navigate to the Dispatches screen from the dashboard, then tap on the "+" button in the bottom right corner. Fill in the required information and tap "Submit".',
            ),
            _buildFAQItem(
              'How do I track a dispatch?',
              'You can track a dispatch by tapping on the search icon in the app bar or by using the "Track Dispatch" card on the dashboard. Enter the reference number of the dispatch you want to track.',
            ),
            _buildFAQItem(
              'How do I change my password?',
              'To change your password, go to your profile by tapping on your profile icon in the app bar, then select "Change Password" from the Account Actions section.',
            ),
            _buildFAQItem(
              'Can I use the app offline?',
              'Yes, the app is designed to work offline. Your data will be synchronized when you reconnect to the internet.',
            ),
            _buildFAQItem(
              'How do I add attachments to a dispatch?',
              'When creating or editing a dispatch, you can add attachments by tapping on the "Add Attachment" button in the attachments section of the form.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@nasignal.mil.ng',
      queryParameters: {
        'subject': 'E-COMCEN Support Request',
        'body': 'App Version: ${AppConstants.appVersion}\n\nPlease describe your issue:\n\n',
      },
    );

    try {
      await launchUrl(emailUri);
    } catch (e) {
      debugPrint('Could not launch email: $e');
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: '+2348012345678',
    );

    try {
      await launchUrl(phoneUri);
    } catch (e) {
      debugPrint('Could not launch phone: $e');
    }
  }

  void _showBugReportDialog(BuildContext context) {
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please describe the issue you encountered:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe the bug...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Submit bug report
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bug report submitted. Thank you!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showVersionInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Version Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Version: ${AppConstants.appVersion}'),
            const SizedBox(height: 8),
            const Text('Build Date: 2023-07-15'),
            const SizedBox(height: 8),
            const Text('Platform: Windows'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
