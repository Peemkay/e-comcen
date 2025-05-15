import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<FAQItem> _faqItems = [
    FAQItem(
      question: 'How do I create a new dispatch?',
      answer:
          'To create a new dispatch, navigate to the Dispatches screen from the main dashboard. Then, tap on the "+" button in the bottom right corner. Fill in the required information in the form and tap "Create Dispatch".',
    ),
    FAQItem(
      question: 'How do I track a dispatch?',
      answer:
          'You can track a dispatch by tapping on the magnifying glass icon in the app bar. Enter the dispatch reference number in the search field and tap "Track". The system will display the current status and location of the dispatch.',
    ),
    FAQItem(
      question: 'How do I change my password?',
      answer:
          'To change your password, go to Settings > Security > Change Password. Enter your current password, then enter and confirm your new password. Tap "Save" to update your password.',
    ),
    FAQItem(
      question: 'What do the different dispatch statuses mean?',
      answer:
          'Pending: Dispatch has been created but not yet processed.\nIn Transit: Dispatch is on its way to the destination.\nDelivered: Dispatch has been successfully delivered.\nReturned: Dispatch has been returned to sender.\nCancelled: Dispatch has been cancelled.',
    ),
    FAQItem(
      question: 'How do I generate reports?',
      answer:
          'To generate reports, navigate to the Reports screen from the main dashboard. Select the type of report you want to generate, specify the date range and other parameters, then tap "Generate Report". You can view, download, or print the generated report.',
    ),
    FAQItem(
      question: 'How do I add a new user to the system?',
      answer:
          'Only administrators can add new users. If you have admin privileges, go to Settings > User Management > Add User. Fill in the required information and assign appropriate permissions, then tap "Create User".',
    ),
    FAQItem(
      question: 'What should I do if I forget my password?',
      answer:
          'If you forget your password, tap on "Forgot Password" on the login screen. Enter your username and follow the instructions to reset your password. If you continue to have issues, please contact your system administrator.',
    ),
    FAQItem(
      question: 'How do I update my profile information?',
      answer:
          'To update your profile information, go to Settings > Profile. Tap on the "Edit" button, make the necessary changes, and tap "Save" to update your profile.',
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  List<FAQItem> _filteredFaqItems = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredFaqItems = List.from(_faqItems);
    _searchController.addListener(_filterFAQs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFAQs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFaqItems = List.from(_faqItems);
      } else {
        _filteredFaqItems = _faqItems
            .where((item) =>
                item.question.toLowerCase().contains(query) ||
                item.answer.toLowerCase().contains(query))
            .toList();
      }
    });
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

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch email client'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: '+2348012345678',
    );

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchWebsite() async {
    final Uri websiteUri = Uri.parse('https://www.nasignal.mil.ng/support');

    if (await canLaunchUrl(websiteUri)) {
      await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch website'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showVideoTutorial(String title, String videoUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text(
            'This feature will launch a video tutorial in your browser. Would you like to continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final Uri uri = Uri.parse(videoUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not launch video tutorial'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Watch Tutorial'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search FAQs...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                autofocus: true,
              )
            : const Text('Help & Support'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
            tooltip: _isSearching ? 'Clear Search' : 'Search FAQs',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Support Section
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
                    const SizedBox(height: 16),
                    const Text(
                      'If you need assistance, please contact our support team:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.email, color: AppTheme.primaryColor),
                      title: const Text('Email Support'),
                      subtitle: const Text('support@nasignal.mil.ng'),
                      onTap: _launchEmail,
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone, color: AppTheme.primaryColor),
                      title: const Text('Phone Support'),
                      subtitle: const Text('+234 801 234 5678'),
                      onTap: _launchPhone,
                    ),
                    ListTile(
                      leading: const Icon(Icons.language, color: AppTheme.primaryColor),
                      title: const Text('Online Support'),
                      subtitle: const Text('www.nasignal.mil.ng/support'),
                      onTap: _launchWebsite,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Video Tutorials Section
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
                      'Video Tutorials',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Watch video tutorials to learn how to use the app:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.play_circle_fill, color: AppTheme.primaryColor),
                      title: const Text('Getting Started'),
                      subtitle: const Text('Learn the basics of E-COMCEN'),
                      onTap: () => _showVideoTutorial(
                        'Getting Started',
                        'https://www.nasignal.mil.ng/tutorials/getting-started',
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.play_circle_fill, color: AppTheme.primaryColor),
                      title: const Text('Creating Dispatches'),
                      subtitle: const Text('How to create and manage dispatches'),
                      onTap: () => _showVideoTutorial(
                        'Creating Dispatches',
                        'https://www.nasignal.mil.ng/tutorials/creating-dispatches',
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.play_circle_fill, color: AppTheme.primaryColor),
                      title: const Text('Tracking Dispatches'),
                      subtitle: const Text('How to track dispatches in real-time'),
                      onTap: () => _showVideoTutorial(
                        'Tracking Dispatches',
                        'https://www.nasignal.mil.ng/tutorials/tracking-dispatches',
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.play_circle_fill, color: AppTheme.primaryColor),
                      title: const Text('Generating Reports'),
                      subtitle: const Text('How to generate and export reports'),
                      onTap: () => _showVideoTutorial(
                        'Generating Reports',
                        'https://www.nasignal.mil.ng/tutorials/generating-reports',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // FAQs Section
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
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_filteredFaqItems.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No FAQs match your search criteria.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredFaqItems.length,
                        itemBuilder: (context, index) {
                          return ExpansionTile(
                            title: Text(
                              _filteredFaqItems[index].question,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(_filteredFaqItems[index].answer),
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
            
            // User Manual Section
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
                      'User Manual',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Download the complete user manual for detailed instructions:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.file_download, color: AppTheme.primaryColor),
                      title: const Text('E-COMCEN User Manual'),
                      subtitle: const Text('PDF format, 5.2 MB'),
                      onTap: () async {
                        final Uri uri = Uri.parse('https://www.nasignal.mil.ng/downloads/ecomcen-manual.pdf');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not download user manual'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.file_download, color: AppTheme.primaryColor),
                      title: const Text('Quick Start Guide'),
                      subtitle: const Text('PDF format, 1.8 MB'),
                      onTap: () async {
                        final Uri uri = Uri.parse('https://www.nasignal.mil.ng/downloads/ecomcen-quickstart.pdf');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not download quick start guide'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Feedback Section
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
                      'Send Feedback',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'We value your feedback! Let us know how we can improve the app:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.feedback),
                        label: const Text('Send Feedback'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          final Uri emailUri = Uri(
                            scheme: 'mailto',
                            path: 'feedback@nasignal.mil.ng',
                            queryParameters: {
                              'subject': 'E-COMCEN Feedback',
                              'body': 'App Version: ${AppConstants.appVersion}\n\nMy feedback:\n\n',
                            },
                          );

                          if (await canLaunchUrl(emailUri)) {
                            await launchUrl(emailUri);
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not launch email client'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
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
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}
