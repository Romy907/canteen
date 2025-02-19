import 'package:canteen/Firebase/FirebaseManager.dart';
import 'package:canteen/Student/StudentFavouriteScreen.dart';
import 'package:canteen/Student/StudentHomeScreen.dart';
import 'package:canteen/Student/StudentCartScreen.dart';
import 'package:canteen/Student/StudentProfileScreen.dart';
import 'package:canteen/Login/loginscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentScreen extends StatefulWidget {
  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> cartItems = [];
  List<Map<String, dynamic>> favoriteItems = [];
  List<Map<String, dynamic>> foodItems = [
    {
      "image": "assets/img/rajmachawal.jpeg",
      "name": "Rajma Chawal",
      "price": "Rs.50",
      "rating": "5.0",
      "calories": "100 cal",
      "isFavorite": false,
      "category": "Main course",
    },
    {
      "image": "assets/img/momo.jpeg",
      "name": "Momos",
      "price": "Rs.70",
      "rating": "4.5",
      "calories": "85 cal",
      "isFavorite": false,
      "category": "Fast Food",
    },
    {
      "image": "assets/img/fried_rice.jpeg",
      "name": "Fried Rice",
      "price": "Rs.75",
      "rating": "4.8",
      "calories": "110 cal",
      "isFavorite": false,
      "category": "Fast Food",
    },
    {
      "image": "assets/img/chholebhature.jpeg",
      "name": "Chhole Bhature",
      "price": "Rs.80",
      "rating": "4.7",
      "calories": "95 cal",
      "isFavorite": false,
      "category": "Main course",
    },
    {
      "image": "assets/img/pizza.jpeg",
      "name": "Pizza",
      "price": "Rs.110",
      "rating": "4.7",
      "calories": "95 cal",
      "isFavorite": false,
      "category": "Fast Food",
    },
    {
      "image": "assets/img/salad.jpeg",
      "name": "Salad",
      "price": "Rs.30",
      "rating": "4.7",
      "calories": "95 cal",
      "isFavorite": false,
      "category": "Main course",
    },
    {
      "image": "assets/img/chilli potato.jpeg",
      "name": "Chilli Potato",
      "price": "Rs.90",
      "rating": "4.5",
      "calories": "70 cal",
      "isFavorite": false,
      "category": "Fast Food",
    },
    {
      "image": "assets/img/manchurian.jpeg",
      "name": "Manchurian",
      "price": "Rs.70",
      "rating": "4.7",
      "calories": "90 cal",
      "isFavorite": false,
      "category": "Fast Food",
    },
    {
      "image": "assets/img/samosa.jpeg",
      "name": "Samosa",
      "price": "Rs.20",
      "rating": "4.5",
      "calories": "50 cal",
      "isFavorite": false,
      "category": "Fast Food",
    },
    {
      "image": "assets/img/spring rolls.jpeg",
      "name": "Spring Roll",
      "price": "Rs.65",
      "rating": "4.7",
      "calories": "60 cal",
      "isFavorite": false,
      "category": "Fast Food",
    },
    {
      "image": "assets/img/veg noodles.jpeg",
      "name": "Veg Noodles",
      "price": "Rs.50",
      "rating": "4.7",
      "calories": "95 cal",
      "isFavorite": false,
      "category": "Fast Food",
    },
    {
      "image": "assets/img/veg rolls.jpeg",
      "name": "Veg Roll",
      "price": "Rs.80",
      "rating": "4.7",
      "calories": "95 cal",
      "isFavorite": false,
      "category": "Fast Food",
    },
    {
      "image": "assets/img/chocolate shakes.jpeg",
      "name": "Chocolate shake",
      "price": "Rs.70",
      "rating": "4.3",
      "calories": "80 cal",
      "isFavorite": false,
      "category": "Drinks",
    },
    {
      "image": "assets/img/cold drinks.jpeg",
      "name": "Cold Drinks",
      "price": "Rs.20",
      "rating": "4.7",
      "calories": "30 cal",
      "isFavorite": false,
      "category": "Drinks",
    },
    {
      "image": "assets/img/icecream.jpeg",
      "name": "Ice Cream",
      "price": "Rs.40",
      "rating": "4.7",
      "calories": "95 cal",
      "isFavorite": false,
      "category": "Dessert",
    },
    {
      "image": "assets/img/lassi.jpeg",
      "name": "Lassi",
      "price": "Rs.40",
      "rating": "4.7",
      "calories": "95 cal",
      "isFavorite": false,
      "category": "Drinks",
    },
    {
      "image": "assets/img/paneer.jpeg",
      "name": "Paneer Nan",
      "price": "Rs.90",
      "rating": "4.7",
      "calories": "100 cal",
      "isFavorite": false,
      "category": "Main course",
    },
    {
      "image": "assets/img/pastry.jpeg",
      "name": "Pastry",
      "price": "Rs.50",
      "rating": "4.7",
      "calories": "70 cal",
      "isFavorite": false,
      "category": "Dessert",
    },
  ];

  List<Widget> _widgetOptions() => <Widget>[
    StudentHomeScreen(
      cartItems: cartItems,
      foodItems: foodItems,
      favoriteItems: favoriteItems,
    ),
    StudentCartScreen(
      cartItems: cartItems,
      onCartUpdated: (updatedCartItems) {
        setState(() {
          cartItems = updatedCartItems;
        });
      },
    ),
    StudentFavouriteScreen(
      favoriteItems: favoriteItems,
    ),
    StudentProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6C63FF),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              try {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('userRole');

                // Ensure Firebase is initialized before logout
                if (Firebase.apps.isNotEmpty) {
                  await FirebaseManager().logout();
                }

                // Navigate to login screen
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Logout failed: $e")),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB993D6), Color(0xFF8CA6DB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _widgetOptions().elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            backgroundColor: Color(0xFF6C63FF),
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            backgroundColor: Color(0xFF6C63FF),
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            backgroundColor: Color(0xFF6C63FF),
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            backgroundColor: Color(0xFF6C63FF),
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 20, 1, 37),
        onTap: _onItemTapped,
      ),
    );
  }
}