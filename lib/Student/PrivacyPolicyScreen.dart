import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Privacy Policy')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Privacy Policy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text(
                'We take your privacy seriously. Your personal data is never shared with third parties.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '1. We collect basic user data for order processing.\n'
                '2. Payments are handled securely via trusted providers.\n'
                '3. Your data is encrypted and stored safely.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 20),
              Text('For more details, contact support.', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
