import 'package:flutter/material.dart';
import 'package:nasds/constants/app_theme.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  // Terms and conditions text
  final String _termsText = '''
Nigerian Army School of Signals (NASDS) Application Terms and Conditions

1. Introduction
   These terms and conditions govern your use of the Nigerian Army School of Signals (NASDS)
application.

2. Acceptable Use
   The application is to be used for official purposes only.

3. Security
   Users must maintain the confidentiality of their login credentials.

4. Data Privacy
   All information processed through the application is subject to military data handling protocols.

5. Updates
   The application may be updated periodically to improve functionality and security.

6. Termination
   Access may be revoked for violations of these terms or security protocols.
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms and Conditions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(_termsText),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Save functionality will be implemented in a future update.'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
