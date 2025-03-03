import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Privacy Policy')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Policies',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Divider(thickness: 1, height: 20),
                  Text(
                    'We take your privacy seriously. Your personal data is never shared with third parties.',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '🔹 **Data Collection:** We collect necessary user information such as name, contact details, and order history for service improvement.\n\n'
                    '🔹 **Secure Payments:** Transactions are processed through encrypted and secure payment gateways.\n\n'
              
                    '🔹 **Third-Party Services:** Some features may rely on third-party APIs, but no personal data is shared without consent.\n\n'
                    '🔹 **User Rights:** You can request data deletion or modification anytime.\n\n'
                    '🔹 **Data Storage:** Your data is securely stored and regularly audited for safety.\n\n'
                    '🔹 **Policy Updates:** Our policies are updated periodically to align with legal requirements and best practices.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'For more details, contact support.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
