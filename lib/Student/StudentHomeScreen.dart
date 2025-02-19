import 'package:canteen/Student/StudentCartScreen.dart';
import 'package:flutter/material.dart';

class StudentHomeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> favoriteItems;
  List<Map<String, dynamic>> cartItems;
  final List<Map<String, dynamic>> foodItems;

  StudentHomeScreen({
    required this.favoriteItems,
    required this.cartItems,
    required this.foodItems,
  });

  @override
  _StudentHomeScreenState createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String selectedCategory = "All";

  void _toggleFavorite(Map<String, dynamic> item) {
    setState(() {
      if (widget.favoriteItems.contains(item)) {
        widget.favoriteItems.remove(item);
      } else {
        widget.favoriteItems.add(item);
      }
    });
  }

  Widget _buildCategoryChips() {
    List<String> categories = [
      "All",
      "Main course",
      "Fast Food",
      "Dessert",
      "Drinks",
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((category) {
          bool isSelected = selectedCategory == category;
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
        ? widget.foodItems
        : widget.foodItems
            .where((item) => item["category"] == selectedCategory)
            .toList();

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
                  height: 88, // Increased height
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _toggleFavorite(item),
                  child: Icon(
                    widget.favoriteItems.contains(item)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: widget.favoriteItems.contains(item)
                        ? const Color.fromARGB(255, 211, 103, 96)
                        : const Color.fromARGB(255, 222, 10, 10),
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
                  const Spacer(), // Pushes button to bottom
                  // Centered Add to Cart Button
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(174, 216, 153, 236),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: () {
                        setState(() {
                          bool isAlreadyInCart = widget.cartItems.any(
                              (cartItem) => cartItem["name"] == item["name"]);

                          if (!isAlreadyInCart) {
                            widget.cartItems.add(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${item["name"]} added to cart"),
                                duration: const Duration(seconds: 2),
                                action: SnackBarAction(
                                  label: "View Cart",
                                  textColor:
                                      const Color.fromARGB(255, 247, 247, 247),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentCartScreen(
                                          cartItems: widget.cartItems,
                                          onCartUpdated: (updatedCartItems) {
                                            setState(() {
                                              widget.cartItems =
                                                  updatedCartItems;
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "${item["name"]} is already in the cart!"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  child: _buildFoodGrid(constraints),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: widget.cartItems.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: Colors.deepPurple,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text("View Cart (${widget.cartItems.length})"),
              onPressed: () async {
                final updatedCart = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentCartScreen(
                      cartItems: widget.cartItems,
                      onCartUpdated: (updatedCartItems) {
                        setState(() {
                          widget.cartItems = updatedCartItems;
                        });
                      },
                    ),
                  ),
                );

                if (updatedCart != null) {
                  setState(() {
                    widget.cartItems = updatedCart;
                  });
                }
              },
            )
          : null,
    );
  }
}