import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _isLoading = true;
  String _privacyContent = '';
  
  @override
  void initState() {
    super.initState();
    _loadPrivacyContent();
  }
  
  Future<void> _loadPrivacyContent() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load privacy policy from assets
      final String content = await rootBundle.loadString('assets/legal/privacy_policy.txt');
      
      setState(() {
        _privacyContent = content;
        _isLoading = false;
      });
    } catch (e) {
      // If file not found, use default content
      setState(() {
        _privacyContent = _getDefaultPrivacyContent();
        _isLoading = false;
      });
    }
  }
  
  String _getDefaultPrivacyContent() {
    return '''
PRIVACY POLICY FOR E-COMCEN APPLICATION

Last Updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

1. INTRODUCTION

The Nigerian Army Signal Corps ("we," "us," or "our") is committed to protecting the privacy and security of your information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our E-COMCEN application ("the Application").

Please read this Privacy Policy carefully. By accessing or using the Application, you acknowledge that you have read, understood, and agree to be bound by this Privacy Policy.

2. INFORMATION WE COLLECT

2.1 Personal Information
We may collect personal information that you provide directly to us, including:
- Name and rank
- Army identification number
- Unit and corps
- Contact information (email address, phone number)
- Login credentials (username and password)
- Profile information

2.2 Usage Information
We automatically collect certain information about your use of the Application, including:
- Log data (e.g., access times, pages viewed, system activity, hardware settings)
- Device information (e.g., device type, operating system, unique device identifiers)
- Location information (with your consent)
- Network information

2.3 Dispatch Information
We collect information related to dispatches created, managed, or tracked through the Application, including:
- Dispatch content and metadata
- Sender and recipient information
- Tracking and delivery information
- Status updates

3. HOW WE USE YOUR INFORMATION

We use the information we collect for various purposes, including:
- Providing, maintaining, and improving the Application
- Processing and tracking dispatches
- Authenticating users and managing accounts
- Ensuring the security and integrity of the Application
- Analyzing usage patterns and optimizing performance
- Complying with legal obligations
- Responding to your requests and inquiries
- Sending administrative messages and updates

4. INFORMATION SHARING AND DISCLOSURE

4.1 Within the Nigerian Army
We may share your information with authorized personnel within the Nigerian Army on a need-to-know basis for operational purposes.

4.2 Third-Party Service Providers
We may engage trusted third-party service providers to perform functions on our behalf, such as hosting, data storage, and analytics. These providers have access to your information only to perform these tasks on our behalf and are obligated to protect your information.

4.3 Legal Requirements
We may disclose your information if required to do so by law or in response to valid requests by public authorities (e.g., a court or government agency).

4.4 Security and Protection
We may disclose your information when we believe in good faith that disclosure is necessary to protect our rights, protect your safety or the safety of others, investigate fraud, or respond to a security incident.

5. DATA SECURITY

We implement appropriate technical and organizational measures to protect the security, confidentiality, and integrity of your information. However, no method of transmission over the Internet or electronic storage is 100% secure, and we cannot guarantee absolute security.

6. DATA RETENTION

We will retain your information only for as long as necessary to fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required or permitted by law.

7. YOUR RIGHTS AND CHOICES

Depending on your location and applicable laws, you may have certain rights regarding your information, such as:
- Accessing, correcting, or deleting your information
- Restricting or objecting to our use of your information
- Receiving a copy of your information in a structured, machine-readable format
- Withdrawing consent where our processing is based on your consent

To exercise these rights, please contact your system administrator or the data protection officer.

8. CHANGES TO THIS PRIVACY POLICY

We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on the Application. You are advised to review this Privacy Policy periodically for any changes.

9. CONTACT US

If you have any questions about this Privacy Policy, please contact us at:

Nigerian Army Signal Corps
Headquarters, Nigerian Army
Abuja, Nigeria
Email: privacy@nasignal.mil.ng

10. SECURITY CLASSIFICATION

This Application is classified as SECRET. All information within the Application must be handled in accordance with applicable security protocols and regulations.
''';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Security Classification Banner
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.security, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'OFFICIAL: This document contains privacy information for the E-COMCEN application.',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // App Info
                  Row(
                    children: [
                      Image.asset(
                        AppConstants.logoPath,
                        width: 60,
                        height: 60,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.appName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              AppConstants.appFullName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Version ${AppConstants.appVersion}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Privacy Policy Content
                  const Text(
                    'PRIVACY POLICY',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last Updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Privacy Content
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SelectableText(
                      _privacyContent,
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.print),
                        label: const Text('Print'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Printing functionality coming soon'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_alt),
                        label: const Text('Save PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PDF export functionality coming soon'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Contact Information
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryColor.withAlpha(50)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'If you have any questions about this Privacy Policy, please contact:',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Nigerian Army Signal Corps\nHeadquarters, Nigerian Army\nAbuja, Nigeria\nEmail: privacy@nasignal.mil.ng',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Copyright Notice
                  Center(
                    child: Text(
                      '© ${AppConstants.currentYear} ${AppConstants.appOrganization}. All rights reserved.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
