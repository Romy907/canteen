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
      appBar: AppBar(title: Text("Notification Settings")),
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
