import 'package:canteen/Student/StudentUniversitySearch.dart';
import 'package:flutter/material.dart';
import 'package:canteen/Student/StudentHomeScreen.dart';
import 'package:canteen/Student/StudentCartScreen.dart';
import 'package:canteen/Student/StudentFavouriteScreen.dart';
import 'package:canteen/Student/StudentProfileScreen.dart';

class StudentScreen extends StatefulWidget {
  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  int _selectedIndex = 0;
  int cartCount = 0;
  int favoriteCount = 0;
  String location = "New York"; 
  List<Map<String, dynamic>> cartItems = [];
  List<Map<String, dynamic>> favoriteItems = [];
  List<Map<String, dynamic>> foodItems = [
    {
      "image": "assets/img/momo.jpeg",
      "name": "Momos",
      "price": "70",
      "category": "Fast Food",
      "type": "Non-Veg"
    },
    {
      "image": "assets/img/pizza.jpeg",
      "name": "Pizza",
      "price": "110",
      "category": "Fast Food",
      "type": "Veg"
    },
    {
      "image": "assets/img/lassi.jpeg",
      "name": "Lassi",
      "price": "80",
      "category": "Fast Food",
      "type": "Veg"
    },
    {
      "image": "assets/img/icecream.jpeg",
      "name": "Ice Cream",
      "price": "40",
      "category": "Dessert",
      "type": "Veg"
    },
  ];

  void _updateCounts() {
    setState(() {
      cartCount = cartItems.length;
      favoriteCount = favoriteItems.length;
    });
  }

  List<Widget> _widgetOptions() => <Widget>[
        StudentHomeScreen(
          cartItems: cartItems,
          foodItems: foodItems,
          favoriteItems: favoriteItems,
          updateCounts: _updateCounts,
        ),
        StudentCartScreen(
          cartItems: cartItems,
          onCartUpdated: (updatedCartItems) {
            setState(() {
              cartItems = updatedCartItems;
              _updateCounts();
            });
          },
        ),
        StudentFavouriteScreen(favoriteItems: favoriteItems),
        StudentProfileScreen(),
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
              "Canteen",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: () {
              // Handle location icon tap
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StudentUniversitySearch(
                    onUniversitySelected: (selectedUniversity) {
                      setState(() {
                        location = selectedUniversity;
                      });
                    },
                  )),
                );
              },
              child: Icon(Icons.location_on, color: const Color.fromARGB(255, 0, 0, 0)),
            ),
            SizedBox(width: 5),
            GestureDetector(
              onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StudentUniversitySearch(
                onUniversitySelected: (selectedUniversity) {
                  setState(() {
                  location = selectedUniversity;
                  });
                },
                )),
              );
              },
              child: Container(
              constraints: BoxConstraints(maxWidth: 100), // Adjust the maxWidth as needed
              child: Text(
                location,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0), fontSize: 16),
              ),
              ),
            ),
          ],
        ),
        actions: [
          _buildIcon(Icons.favorite, favoriteCount,
              () => setState(() => _selectedIndex = 2)),
          _buildIcon(Icons.shopping_cart, cartCount,
              () => setState(() => _selectedIndex = 1)),
        ],
      ),
      body: _widgetOptions().elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Favourites'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.blue,
        onTap: (index) => setState(() => _selectedIndex = index),
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
