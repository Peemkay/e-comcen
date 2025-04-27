import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  bool _isLoading = true;
  String _termsContent = '';
  
  @override
  void initState() {
    super.initState();
    _loadTermsContent();
  }
  
  Future<void> _loadTermsContent() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load terms and conditions from assets
      final String content = await rootBundle.loadString('assets/legal/terms_conditions.txt');
      
      setState(() {
        _termsContent = content;
        _isLoading = false;
      });
    } catch (e) {
      // If file not found, use default content
      setState(() {
        _termsContent = _getDefaultTermsContent();
        _isLoading = false;
      });
    }
  }
  
  String _getDefaultTermsContent() {
    return '''
TERMS AND CONDITIONS FOR E-COMCEN APPLICATION

Last Updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

1. INTRODUCTION

Welcome to E-COMCEN, the Electronic Communications Center application ("the Application") operated by the Nigerian Army Signal Corps ("we," "us," or "our"). These Terms and Conditions ("Terms") govern your access to and use of the Application.

By accessing or using the Application, you agree to be bound by these Terms. If you disagree with any part of the Terms, you may not access the Application.

2. DEFINITIONS

"Application" means the E-COMCEN software application.
"User" means any person who accesses or uses the Application.
"Content" means any information, data, text, software, graphics, messages, or other materials.
"Dispatch" means any communication or document transmitted through the Application.

3. ACCESS AND USE

3.1 Authorized Use
The Application is intended solely for use by authorized personnel of the Nigerian Army Signal Corps and other approved military personnel. Unauthorized access or use is strictly prohibited.

3.2 Account Security
You are responsible for maintaining the confidentiality of your login credentials and for all activities that occur under your account. You must immediately notify us of any unauthorized use of your account or any other breach of security.

3.3 Prohibited Activities
You agree not to:
- Use the Application for any illegal purpose or in violation of any laws
- Interfere with or disrupt the operation of the Application
- Attempt to gain unauthorized access to any part of the Application
- Use the Application to transmit any viruses, malware, or other harmful code
- Share your account credentials with unauthorized individuals
- Use the Application in any manner that could damage, disable, overburden, or impair it

4. INTELLECTUAL PROPERTY

4.1 Ownership
The Application and all of its content, features, and functionality are owned by the Nigerian Army Signal Corps and are protected by copyright, trademark, and other intellectual property laws.

4.2 Limited License
We grant you a limited, non-exclusive, non-transferable, and revocable license to use the Application solely for its intended purpose and in accordance with these Terms.

5. CONFIDENTIALITY AND SECURITY

5.1 Classification
All information within the Application is classified as SECRET and must be handled in accordance with applicable security protocols and regulations.

5.2 Data Protection
You must take all reasonable measures to protect the confidentiality and security of all data accessed through the Application.

5.3 Reporting Security Incidents
You must immediately report any security incidents or suspected breaches to your commanding officer and the system administrator.

6. PRIVACY

Your use of the Application is also governed by our Privacy Policy, which is incorporated into these Terms by reference.

7. DISCLAIMER OF WARRANTIES

THE APPLICATION IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT ANY WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. WE DISCLAIM ALL WARRANTIES, INCLUDING IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.

8. LIMITATION OF LIABILITY

TO THE MAXIMUM EXTENT PERMITTED BY LAW, IN NO EVENT SHALL THE NIGERIAN ARMY SIGNAL CORPS BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING OUT OF OR RELATED TO YOUR USE OF THE APPLICATION.

9. CHANGES TO TERMS

We reserve the right to modify these Terms at any time. We will provide notice of any material changes by posting the updated Terms on the Application. Your continued use of the Application after such modifications constitutes your acceptance of the revised Terms.

10. GOVERNING LAW

These Terms shall be governed by and construed in accordance with the laws of the Federal Republic of Nigeria, without regard to its conflict of law provisions.

11. TERMINATION

We may terminate or suspend your access to the Application immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach these Terms.

12. CONTACT INFORMATION

If you have any questions about these Terms, please contact us at:

Nigerian Army Signal Corps
Headquarters, Nigerian Army
Abuja, Nigeria
Email: legal@nasignal.mil.ng

By using the E-COMCEN Application, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.
''';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
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
                            'OFFICIAL: This document contains terms and conditions for using the E-COMCEN application.',
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
                  
                  // Terms and Conditions Content
                  const Text(
                    'TERMS AND CONDITIONS',
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
                  
                  // Terms Content
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SelectableText(
                      _termsContent,
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
