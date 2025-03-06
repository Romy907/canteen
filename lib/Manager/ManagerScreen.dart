import 'package:canteen/Manager/ManagerHome.dart';
import 'package:canteen/Manager/ManagerOrderList.dart';
import 'package:canteen/Manager/ManagerProfile.dart';
import 'package:canteen/Manager/ManagerReport.dart';
import 'package:flutter/material.dart';
import 'package:canteen/Firebase/FirebaseManager.dart';
import 'package:canteen/Login/loginscreen.dart';

class ManagerScreen extends StatefulWidget {
  @override
  _ManagerScreenState createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  int _selectedIndex = 0;
  int pendingOrderCount = 0;

  @override
  void initState() {
    super.initState();
    // This is where you would fetch pending orders count from Firebase
    // For demo purposes, I'm setting a static value
    pendingOrderCount = 5;
  }

  List<Widget> _widgetOptions() => <Widget>[
        ManagerHome(
          updatePendingOrderCount: (count) {
            setState(() {
              pendingOrderCount = count;
            });
          },
        ),
        ManagerReport(),
        ManagerOrderList(),
        ManagerProfile(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                "Canteen Manager",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            Spacer(),
          ],
        ),
        actions: [
          _buildIcon(Icons.notifications, pendingOrderCount, 
              () => setState(() => _selectedIndex = 2)),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseManager().logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _widgetOptions().elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
          BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(Icons.receipt_long),
                  if (pendingOrderCount > 0)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                      ),
                    )
                ],
              ),
              label: 'Orders'
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.blue,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildIcon(IconData icon, int count, VoidCallback onTap) {
    return Stack(
      children: [
        IconButton(icon: Icon(icon), onPressed: onTap),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: CircleAvatar(
                radius: 8, backgroundColor: Colors.red, child: Text('$count')),
          ),
      ],
    );
  }
}