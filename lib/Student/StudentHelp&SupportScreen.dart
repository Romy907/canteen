import 'package:flutter/material.dart';

class HelpAndSupportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support'),
      ),
      body: ListView(
        children: [
          _buildSupportOption(
            context,
            icon: Icons.phone,
            title: 'Contact Us',
            subtitle: 'Call our support team',
            onTap: () {
          
            },
          ),
          _buildSupportOption(
            context,
            icon: Icons.email,
            title: 'Email Support',
            subtitle: 'Send us an email',
            onTap: () {
            
            },
          ),
          _buildSupportOption(
            context,
            icon: Icons.help_outline,
            title: 'FAQs',
            subtitle: 'Frequently Asked Questions',
            onTap: () {
            
            },
          ),
          _buildSupportOption(
            context,
            icon: Icons.feedback,
            title: 'Send Feedback',
            subtitle: 'Share your experience',
            onTap: () {
              
            },
          ),
          _buildSupportOption(
            context,
            icon: Icons.policy,
            title: 'Privacy Policy',
            subtitle: 'Read our policies',
            onTap: () {
              
            },
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
