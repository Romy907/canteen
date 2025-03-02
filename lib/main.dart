import 'package:canteen/Manager/ManagerScreen.dart';
import 'package:canteen/Student/StudentScreen.dart';
import 'package:canteen/Login/loginscreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
} 

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      debugShowCheckedModeBanner: false,
      title: 'canteen',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    home: FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
        } else {
      final prefs = snapshot.data as SharedPreferences;
      final role = prefs.getString('userRole');
      if (role == 'student') {
        return StudentScreen();
      } else if (role == 'manager') {
        return ManagerScreen();
      } else {
        return LoginScreen();
      }
        }
      },
    ),
    );
  }
}
