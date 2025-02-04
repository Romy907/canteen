import 'package:canteen/FirebaseManager.dart';
import 'package:canteen/loginscreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
        title: Text('Student Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async{
              // Add your logout logic here
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('userRole');
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
        child: Text('Welcome to the Student Home Screen!'),
      ),
    );
  }
}