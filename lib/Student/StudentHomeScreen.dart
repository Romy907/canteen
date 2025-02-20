// StudentHomeScreen.dart
import 'package:flutter/material.dart';

class StudentHomeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> favoriteItems;
  final List<Map<String, dynamic>> cartItems;
  final List<Map<String, dynamic>> foodItems;
  final Function updateCounts;

  StudentHomeScreen({
    required this.favoriteItems,
    required this.cartItems,
    required this.foodItems,
    required this.updateCounts,
  });

  @override
  _StudentHomeScreenState createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String selectedCategory = 'All';
  late List<String> categories;

  @override
  void initState() {
    super.initState();
    categories = ['All'];
    categories.addAll(
      widget.foodItems
          .map((item) => item['category'] as String)
          .toSet()
          .toList(),
    );
  }

  List<Map<String, dynamic>> get filteredFoodItems {
    return selectedCategory == 'All'
        ? widget.foodItems
        : widget.foodItems
            .where((item) => item['category'] == selectedCategory)
            .toList();
  }

  Widget buildFoodCard(Map<String, dynamic> foodItem) {
    bool isFavorite =
        widget.favoriteItems.any((item) => item['name'] == foodItem['name']);
    bool inCart =
        widget.cartItems.any((item) => item['name'] == foodItem['name']);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Section
          SizedBox(
            height: 130,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.asset(
                    foodItem['image'],
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isFavorite) {
                            widget.favoriteItems.removeWhere(
                                (item) => item['name'] == foodItem['name']);
                          } else {
                            widget.favoriteItems.add(foodItem);
                          }
                          widget.updateCounts();
                        });
                      },
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withAlpha(175),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      foodItem['category'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.circle,
                      color:
                          foodItem['type'] == 'Veg' ? Colors.green : Colors.red,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12,0,12,0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food Name & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          foodItem['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "₹${foodItem['price']}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 0),
                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: inCart
                            ? Colors.green
                            : const Color.fromARGB(255, 20, 22, 131),
                      ),
                      onPressed: () {
                        setState(() {
                          if (inCart) {
                            widget.cartItems.removeWhere(
                                (item) => item['name'] == foodItem['name']);
                          } else {
                            widget.cartItems.add(foodItem);
                          }
                          widget.updateCounts();
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            inCart ? Icons.check_circle : Icons.shopping_cart,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            inCart ? 'Added' : 'Add to Cart',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((String category) {
                  bool isSelected = selectedCategory == category;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[200],
                        borderRadius: BorderRadius.circular(
                            16), // Increased border radius
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7, // Adjusted aspect ratio
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: filteredFoodItems.length,
                itemBuilder: (context, index) =>
                    buildFoodCard(filteredFoodItems[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
