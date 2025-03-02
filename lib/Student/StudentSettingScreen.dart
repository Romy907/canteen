import 'package:flutter/material.dart';

class StudentSettingScreen extends StatefulWidget {
  @override
  _StudentSettingScreenState createState() => _StudentSettingScreenState();
}

class _StudentSettingScreenState extends State<StudentSettingScreen> {
  bool isDarkMode = false;

  void _changePassword() {
    // Navigate to Change Password Screen
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Account"),
        content: Text("Are you sure you want to delete your account? This action cannot be undone."),
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

  void _toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
      // Apply theme change logic if using a theme provider
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.lock),
            title: Text("Change Password"),
            onTap: _changePassword,
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text("Delete Account", style: TextStyle(color: Colors.red)),
            onTap: _deleteAccount,
          ),
          SwitchListTile(
            title: Text("Dark Mode"),
            value: isDarkMode,
            onChanged: _toggleTheme,
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text("Notification Settings"),
            onTap: () {
              // Navigate to notification settings screen
            },
          ),
        ],
      ),
    );
  }
}
