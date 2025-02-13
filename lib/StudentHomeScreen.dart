import 'package:canteen/CartScreen.dart';
import 'package:canteen/FirebaseManager.dart';
import 'package:canteen/loginscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  _StudentHomeScreenState createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  List<Map<String, dynamic>> cartItems = [];
  
  // ✅ Selected category (default = All)
  String selectedCategory = "All";

  // ✅ Food Items with Category Tags
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.logout, color: Colors.black),
      onPressed: () async {
        try {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove('userRole');

          // ✅ Ensure Firebase is initialized before logout
          if (Firebase.apps.isNotEmpty) {
            await FirebaseManager().logout();
          }

          // ✅ Navigate to login screen
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
body: LayoutBuilder(
        builder: (context, constraints) {
        
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildCategoryChips(),
                const SizedBox(height: 10),
               Expanded(
                child: Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16),
               child: _buildFoodGrid(constraints), // No need to pass constraints
               ),
            ),
              ],
            
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
       // ✅ Persistent Floating "View Cart" Button
    floatingActionButton: cartItems.isNotEmpty
        ? FloatingActionButton.extended(
            backgroundColor: Colors.deepPurple,
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            label: Text("View Cart (${cartItems.length})"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          )
        : null, // Hide if cart is empty
  );
}
    
  

  Widget _buildCategoryChips() {
     List<String> categories = [
      "All",
      "Main course",
      "Fast Food",
      "Dessert",
      "Drinks",
      "Tea",
      "Coffee"
    ];


    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((category) {
           bool isSelected = selectedCategory == category;
          List<Map<String, dynamic>> filteredItems = selectedCategory == "All"
              ? foodItems
              : foodItems.where((item) => item["category"] == selectedCategory).toList();
      
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  selectedCategory = category;
                });
              },
              selectedColor: const Color.fromARGB(255, 189, 65, 182), 

              backgroundColor: Colors.purple.shade100,
           labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFoodGrid(BoxConstraints constraints) {
    int crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;
    double aspectRatio = constraints.maxWidth < 600 ? 0.7 : 0.8;

    List<Map<String, dynamic>> filteredItems = selectedCategory == "All"
        ? foodItems
        : foodItems.where((item) => item["category"] == selectedCategory).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        itemCount: filteredItems.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
        ),
        itemBuilder: (context, index) {
          return _buildFoodCard(filteredItems[index]);
        },
      ),
    );
  }

 Widget _buildFoodCard(Map<String, dynamic> item) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image with Heart Icon Overlay
        Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.asset(
                item["image"],
                width: double.infinity,
                height: 88, // ✅ Increased height
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    item["isFavorite"] = !item["isFavorite"];
                  });
                },
                child: Icon(
                  item["isFavorite"] ? Icons.favorite : Icons.favorite_border,
                  color: item["isFavorite"] ? Colors.red : Colors.grey,
                ),
              ),
            ),
          ],
        ),

        // Expanded Column to Avoid Overflow
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  item["name"],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),

                // Rating & Price Row
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 16),
                    Text(
                      item["rating"],
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    
                    const SizedBox(width: 6),
                
                    Text(
                      "• ${item["price"]}",
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Spacer(), // ✅ Pushes button to bottom

                // Centered Add to Cart Button
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(174, 216, 153, 236),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onPressed: () {
                      setState(() {
                         bool isAlreadyInCart = cartItems.any((cartItem) => cartItem["name"] == item["name"]);

                        if (!isAlreadyInCart) {
                       ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${item["name"]} added to cart"),
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: "View Cart",
                                textColor: const Color.fromARGB(255, 247, 247, 247),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CartScreen()),
                                  );
                                },
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${item["name"]} is already in the cart!"),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      });
                    },
                    child: const Text("Add to Cart"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: const Color.fromARGB(255, 65, 63, 63),
      showUnselectedLabels: true,
      onTap: (index) {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: "Cart",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Profile",
        ),
      ],
    );
  }
}
