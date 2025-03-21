import 'package:flutter/material.dart';
import 'ContactUsScreen.dart';
import 'FAQScreen.dart';
import 'FeedbackScreen.dart';
import 'PrivacyPolicyScreen.dart';

class HelpAndSupportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
  title: const Text('Help & Support'),
  backgroundColor: Colors.white,
  foregroundColor: Colors.black87,
  elevation: 1,
  leading: IconButton(
    icon: Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black87),
    ),
    onPressed: () => Navigator.of(context).pop(),
  ),
),

      body: ListView(
        children: [
          _buildSupportOption(
            context,
            icon: Icons.phone,
            title: 'Contact Us',
            subtitle: 'Call or email our support team',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ContactUsScreen()),
            ),
          ),
          _buildSupportOption(
            context,
            icon: Icons.help_outline,
            title: 'FAQs',
            subtitle: 'Frequently Asked Questions',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FAQScreen()),
            ),
          ),
          _buildSupportOption(
            context,
            icon: Icons.feedback,
            title: 'Send Feedback',
            subtitle: 'Share your experience',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FeedbackScreen()),
            ),
          ),
          _buildSupportOption(
            context,
            icon: Icons.policy,
            title: 'Privacy Policy',
            subtitle: 'Read our policies',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
