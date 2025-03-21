import 'package:canteen/Firebase/FirebaseManager.dart';
import 'package:canteen/Login/loginscreen.dart';
import 'package:canteen/Student/MyOrdersScreen.dart';
import 'package:canteen/Student/StudentHelp&SupportScreen.dart';
import 'package:canteen/Student/StudentInviteFriendScreen.dart';
import 'package:canteen/Student/StudentSettingScreen.dart';
import 'package:canteen/Student/StudentEditProfileScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  _StudentProfileScreenState createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  File? _profileImage;
  String name = '';
  String email = '';
  String phone = '';
  String campus = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? imagePath = prefs.getString('profile_image');
    if (imagePath != null) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
    setState(() {
      name = prefs.getString('name') ?? 'Not Available';
      email = prefs.getString('email') ?? 'nicolasadams@gmail.com';
      phone = prefs.getString('phone') ?? '';
      campus = prefs.getString('campus') ?? '';
    });
  }

  Future<void> _confirmLogout(BuildContext context) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Logout', style: TextStyle(color: Colors.black)),
            content: Text(
              'Are you sure you want to logout from your account?',
              style: TextStyle(color: Colors.grey),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 236, 136, 136),
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await FirebaseManager().logout();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : AssetImage('assets/images/logo.png') as ImageProvider,
                child: _profileImage == null
                    ? Icon(Icons.person, size: 50, color: Colors.grey)
                    : null,
              ),
            ),
          ),
          SizedBox(height: 10),
          Text(
            name,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            email,
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => StudentEditProfileScreen(profileImage: _profileImage),
                    ),
                  )
                  .then((_) => _loadProfileData());
            },
            child: Text(
              'Edit Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 10),
          _buildProfileOption(context, Icons.history, 'My Orders'),
          SizedBox(height: 10),
          _buildProfileOption(context, Icons.help_outline, 'Help & Support'),
          SizedBox(height: 10),
          _buildProfileOption(context, Icons.settings, 'Settings'),
          SizedBox(height: 10),
          _buildProfileOption(context, Icons.person_add, 'Invite a Friend'),
          SizedBox(height: 10),
          _buildProfileOption(context, Icons.logout, 'Logout', isLogout: true),
        ],
      ),
    ),
  );
}


  Widget _buildProfileOption(BuildContext context, IconData icon, String title, {bool isLogout = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isLogout ? Colors.red.withAlpha(10) : Colors.black.withAlpha(15),
        borderRadius: BorderRadius.circular(25),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        leading: Icon(icon, color: isLogout ? Colors.red : Colors.black),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isLogout ? Colors.red : Colors.black,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          switch (title) {
            case 'My Orders':
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => MyOrdersScreen()),
              );
              break;
            case 'Help & Support':
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => HelpAndSupportScreen()),
              );
              break;
            case 'Settings':
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => StudentSettingScreen()),
              );
              break;
            case 'Invite a Friend':
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => StudentInviteFriendScreen()),
              );
              break;
            case 'Logout':
              _confirmLogout(context);
              break;
          }
        },
      ),
    );
  }
}
