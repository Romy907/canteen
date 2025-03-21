import 'package:canteen/Student/ChangePassword.dart';
import 'package:canteen/Student/NotificationSettingsScreen.dart';
import 'package:flutter/material.dart';
import 'LanguageSelectionScreen.dart'; // Import the Language Selection Screen

class StudentSettingScreen extends StatefulWidget {
  @override
  _StudentSettingScreenState createState() => _StudentSettingScreenState();
}

class _StudentSettingScreenState extends State<StudentSettingScreen> {
  String _selectedLanguage = "English"; // Default language

  void _changePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChangePassword()),
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

  void _openLanguageSettings() async {
    final selectedLang = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LanguageSelectionScreen(),
      ),
    );

    if (selectedLang != null && selectedLang != _selectedLanguage) {
      setState(() {
        _selectedLanguage = selectedLang; // Update language after returning
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
  title: const Text("Settings"),
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
          _buildSettingOption(
            context,
            icon: Icons.language,
            title: "Language ", // Show selected language
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
