import 'package:canteen/Student/ChangePassword.dart';
import 'package:canteen/Student/NotificationSettingsScreen.dart';
import 'package:flutter/material.dart';

class StudentSettingScreen extends StatefulWidget {
  @override
  _StudentSettingScreenState createState() => _StudentSettingScreenState();
}

class _StudentSettingScreenState extends State<StudentSettingScreen> {
  String _selectedLanguage = "English"; // Default language

  void _changePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Account"),
        content: Text("Are you sure you want to delete your account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // Perform account deletion logic here
              Navigator.pop(context);
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openLanguageSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Select Language"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text("English"),
                value: "English",
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: Text("Hindi"),
                value: "Hindi",
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  Navigator.pop(context);
                  // You can add logic here to apply the selected language
                });
              },
              child: Text("OK"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: ListView(
        children: [
          _buildSettingOption(
            context,
            icon: Icons.language,
            title: "Language ($_selectedLanguage)", // Show selected language
            onTap: _openLanguageSettings,
          ),
          _buildSettingOption(
            context,
            icon: Icons.lock,
            title: "Change Password",
            onTap: _changePassword,
          ),
          _buildSettingOption(
            context,
            icon: Icons.delete,
            title: "Delete Account",
            onTap: _deleteAccount,
          ),
          _buildSettingOption(
            context,
            icon: Icons.notifications,
            title: "Notification Settings",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationSettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color iconColor = Colors.blue,
    Color textColor = Colors.black,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
