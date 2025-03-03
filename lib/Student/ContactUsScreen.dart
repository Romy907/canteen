import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  final String supportPhoneNumber = "+1234567890"; // Replace with actual support number
  final String supportEmail = "support@canteenapp.com"; // Replace with actual support email

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Us'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildContactOption(
              icon: Icons.phone,
              title: 'Call Us',
              subtitle: supportPhoneNumber,
              onTap: () => _launchPhoneDialer(supportPhoneNumber),
            ),
            _buildContactOption(
              icon: Icons.email,
              title: 'Email Us',
              subtitle: supportEmail,
              onTap: () => _launchEmail(supportEmail),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _launchPhoneDialer(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint("Could not launch $url");
    }
  }

  void _launchEmail(String email) async {
    final Uri url = Uri.parse('mailto:$email?subject=Support%20Request');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint("Could not launch $url");
    }
  }
}
