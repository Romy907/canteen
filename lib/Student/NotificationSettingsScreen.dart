import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool isNotificationEnabled = true;
  bool isEmailNotificationEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
  title: const Text("Notification Settings"),
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
    SwitchListTile(
      title: Text("Enable Notifications"),
      value: isNotificationEnabled,
      onChanged: (value) {
        setState(() {
          isNotificationEnabled = value;
        });
      },
    ),
    SwitchListTile(
      title: Text("Enable Email Notifications"),
      value: isEmailNotificationEnabled,
      onChanged: (value) {
        setState(() {
          isEmailNotificationEnabled = value;
        });
      },
    ),
  ],
),
    );
  }
}
