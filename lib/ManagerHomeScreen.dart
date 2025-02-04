import 'package:canteen/FirebaseManager.dart';
import 'package:canteen/loginscreen.dart';
import 'package:flutter/material.dart';

class ManagerHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manager Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async{
              // Add your logout logic here
              await FirebaseManager().logout();
              Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
          );
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome to the Manager Home Screen!'),
      ),
    );
  }
}