import 'package:canteen/Services/StudentMenuServices.dart';
import 'package:canteen/Student/StudentUniversitySearch.dart';
import 'package:flutter/material.dart';
import 'package:canteen/Student/StudentHomeScreen.dart';
import 'package:canteen/Student/StudentCartScreen.dart';
import 'package:canteen/Student/StudentFavouriteScreen.dart';
import 'package:canteen/Student/StudentProfileScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentScreen extends StatefulWidget {
  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  int _selectedIndex = 0;
  int cartCount = 0;
  int favoriteCount = 0;
  String location = "";
  List<Map<String, dynamic>> cartItems = [];
  List<Map<String, dynamic>> favoriteItems = [];
  List<Map<String, dynamic>> foodItems = [];

  @override
  void initState() {
    super.initState();
    // Load initial data
    _setSelectedUniversity();
    _fetchFoodItems();
  }

  void _updateCounts() {
    setState(() {
      cartCount = cartItems.length;
      favoriteCount = favoriteItems.length;
    });
  }

  Future<void> _setSelectedUniversity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      location = prefs.getString('selectedUniversity') ?? "";
      print("Current location set to: $location");
    });
  }

  Future<void> _saveSelectedUniversity(String university) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedUniversity', university);
    print("Saved location to SharedPreferences: $university");
  }

  Future<void> _fetchFoodItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedIds = prefs.getString('stores');
    RegExp regExp = RegExp(r'\d+');
    List<String> ids = regExp.allMatches(storedIds!).map((match) => match.group(0)!).toList();
    print("Store IDs: $ids");
    
    try {
      List<Map<String, dynamic>> items = await StudentMenuServices().getMenuItems(ids);
      setState(() {
        foodItems = items;
        print("Fetched ${foodItems.length} food items");
      });
    } catch (e) {
      print("Error fetching food items: $e");
    }
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

  void _navigateToUniversitySearch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentUniversitySearch(
          onUniversitySelected: (selectedUniversity) async {
            // This callback might not be needed since we're handling the result below
            // But keeping it for backward compatibility
          },
        ),
      ),
    );
    
    // Handle the result when returning from StudentUniversitySearch
    if (result != null && result is String) {
      setState(() {
        location = result;
      });
      await _saveSelectedUniversity(result);
      await _fetchFoodItems(); // Refresh food items based on new location
    }
  }

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
              onTap: _navigateToUniversitySearch,
              child: Icon(Icons.location_on, color: const Color.fromARGB(255, 0, 0, 0)),
            ),
            SizedBox(width: 5),
            GestureDetector(
              onTap: _navigateToUniversitySearch,
              child: Container(
                constraints: BoxConstraints(maxWidth: 100),
                child: Text(
                  location.isEmpty ? "Select Location" : location,
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