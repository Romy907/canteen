
import 'package:canteen/Firebase/FirebaseManager.dart';
import 'package:canteen/Login/loginscreen.dart';
import 'package:canteen/Student/PurchaseHistoryScreen.dart';
import 'package:canteen/Student/StudentHelp&SupportScreen.dart';
import 'package:canteen/Student/StudentInviteFriendScreen.dart';
import 'package:canteen/Student/StudentSettingScreen.dart';
import 'package:flutter/material.dart';
import 'package:canteen/Student/StudentEditProfileScreen.dart';
import 'package:flutter/material.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/images/logo.png'),
            ),
            SizedBox(height: 10),
            Text(
              'Nicolas Adams',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'nicolasadams@gmail.com',
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => StudentEditProfileScreen(),
                  ),
                );
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
            _buildProfileOption(context, Icons.history, 'Purchase History'),
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
            case 'Privacy':
              break;
            case 'Purchase History':
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => PurchaseHistoryScreen()),
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
              FirebaseManager().logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
              break;
          }
        },
      ),
    );
  }
}
