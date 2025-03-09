import 'package:canteen/Student/CheckOutScreen.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class StudentHomeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> favoriteItems;
  final List<Map<String, dynamic>> cartItems;
  final List<Map<String, dynamic>> foodItems;
  final Function updateCounts;

  const StudentHomeScreen({
    Key? key,
    required this.favoriteItems,
    required this.cartItems,
    required this.foodItems,
    required this.updateCounts,
  }) : super(key: key);

  @override
  _StudentHomeScreenState createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> with SingleTickerProviderStateMixin {
  String selectedCategory = 'All';
  late List<String> categories;
  String searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    categories = ['All'];
    categories.addAll(
      widget.foodItems
          .map((item) => item['category'] as String)
          .toSet()
          .toList(),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredFoodItems {
    return widget.foodItems
        .where((item) => 
            (selectedCategory == 'All' || item['category'] == selectedCategory) &&
            (searchQuery.isEmpty || 
             item['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()))
        )
        .toList();
  }

  void _toggleFavorite(Map<String, dynamic> foodItem) {
    bool isFavorite = widget.favoriteItems.any((item) => item['name'] == foodItem['name']);
    
    setState(() {
      if (isFavorite) {
        widget.favoriteItems.removeWhere((item) => item['name'] == foodItem['name']);
      } else {
        widget.favoriteItems.add(foodItem);
      }
      widget.updateCounts();
    });
  }

  void _toggleCart(Map<String, dynamic> foodItem) {
    bool inCart = widget.cartItems.any((item) => item['name'] == foodItem['name']);
    
    setState(() {
      if (inCart) {
        widget.cartItems.removeWhere((item) => item['name'] == foodItem['name']);
      } else {
        widget.cartItems.add(foodItem);
      }
      widget.updateCounts();
    });
  }
  
 void _buyNow(Map<String, dynamic> foodItem) {
  // Add to cart if not already added
  bool inCart = widget.cartItems.any((item) => item['name'] == foodItem['name']);
  if (!inCart) {
    setState(() {
      widget.cartItems.add(foodItem);
      widget.updateCounts();
    });
  }
  
  // Navigate directly to checkout with this item
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => CheckOutScreen(
        items: [foodItem],
        isBuyNow: true,
      ),
    ),
  );
}

  Widget _buildFoodCard(Map<String, dynamic> foodItem) {
    bool isFavorite = widget.favoriteItems.any((item) => item['name'] == foodItem['name']);
    bool inCart = widget.cartItems.any((item) => item['name'] == foodItem['name']);
    
    return Hero(
      tag: 'food-${foodItem['name']}',
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image container with overlays
              Stack(
                children: [
                  // Food image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: AspectRatio(
                      aspectRatio: 1.5,
                      child: Image.asset(
                        foodItem['image'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  
                  // Favorite button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(foodItem),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isFavorite 
                              ? Colors.red.withAlpha(229) 
                              : Colors.white.withAlpha(229),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFavorite ? Colors.white : Colors.red,
                        ),
                      ),
                    ),
                  ),
                  
                  // Gradient overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withAlpha(178),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        
                        children: [
                          // Category pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withAlpha(204),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              foodItem['category'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          // Veg/Non-veg indicator
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(204),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: foodItem['type'] == 'Veg' ? Colors.green : Colors.red,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  foodItem['type'],
                                  style: TextStyle(
                                    color: foodItem['type'] == 'Veg' ? Colors.green[800] : Colors.red[800],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Content area
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food name
                    Text(
                      foodItem['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 0),
                    
                    // Price
                    Text(
                      "₹${foodItem['price']}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Buy Now and Add to Cart buttons row
                    Row(
                      children: [
                        // Buy Now button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _buyNow(foodItem),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange[700],
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withAlpha(76),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Buy Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Add to Cart button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _toggleCart(foodItem),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: inCart ? Colors.green : Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: (inCart ? Colors.green : Theme.of(context).primaryColor).withAlpha(76),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    inCart ? Icons.check : Icons.shopping_cart,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    inCart ? 'Added' : 'Add',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_state.png', // Add this image to your assets
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            "No food items found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? "Try a different search term"
                : "Try selecting a different category",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar with search
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and user greeting
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Campus Cuisine",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "What would you like to eat today?",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                     
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search for food...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey[400]),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Categories list
            Container(
              height: 60,
              padding: const EdgeInsets.only(left: 16),
              margin: const EdgeInsets.only(top: 16),
              child: FadeTransition(
                opacity: _animation,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).primaryColor 
                              : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300]!,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Theme.of(context).primaryColor.withAlpha(76),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Food items grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: filteredFoodItems.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7, // Adjusted for the new button
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: filteredFoodItems.length,
                        itemBuilder: (context, index) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(
                                  0.4 + (index / filteredFoodItems.length) * 0.6,
                                  1.0,
                                  curve: Curves.easeOut,
                                ),
                              ),
                            ),
                            child: _buildFoodCard(filteredFoodItems[index]),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}