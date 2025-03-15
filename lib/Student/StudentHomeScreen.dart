import 'package:canteen/Student/CheckOutScreen.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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

class _StudentHomeScreenState extends State<StudentHomeScreen>
    with SingleTickerProviderStateMixin {
  String selectedCategory = 'All';
  late List<String> categories = ['All'];
  String searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isLoading = true;

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
    print("Initial food items: ${widget.foodItems.length}");
    _updateCategories();

    // Set loading state based on whether we have items
    setState(() {
      _isLoading = widget.foodItems.isEmpty;
    });
  }

  void _updateCategories() {
    if (widget.foodItems.isEmpty) {
      setState(() {
        categories = ['All'];
      });
      return;
    }

    // Extract unique categories from food items
    final Set<String> uniqueCategories =
        widget.foodItems.map((item) => item['category'] as String).toSet();

    setState(() {
      categories = ['All', ...uniqueCategories];
      _isLoading = false; // Data is loaded
    });
    print("Categories updated: $categories");
  }

  @override
  void didUpdateWidget(StudentHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if food items have changed
    if (widget.foodItems != oldWidget.foodItems) {
      print("Food items updated: ${widget.foodItems.length}");

      setState(() {
        // If we're getting new data, show loading state briefly
        _isLoading = widget.foodItems.isEmpty;
      });

      _updateCategories();
    }
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
            (selectedCategory == 'All' ||
                item['category'] == selectedCategory) &&
            (searchQuery.isEmpty ||
                item['name']
                    .toString()
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase())))
        .toList();
  }

  void _toggleFavorite(Map<String, dynamic> foodItem) {
    bool isFavorite =
        widget.favoriteItems.any((item) => item['name'] == foodItem['name']);

    setState(() {
      if (isFavorite) {
        widget.favoriteItems
            .removeWhere((item) => item['name'] == foodItem['name']);
      } else {
        widget.favoriteItems.add(foodItem);
      }
      widget.updateCounts();
    });
  }

  void _toggleCart(Map<String, dynamic> foodItem) {
    bool inCart =
        widget.cartItems.any((item) => item['name'] == foodItem['name']);

    setState(() {
      if (inCart) {
        widget.cartItems
            .removeWhere((item) => item['name'] == foodItem['name']);
      } else {
        widget.cartItems.add(foodItem);
      }
      widget.updateCounts();
    });
  }

  void _buyNow(Map<String, dynamic> foodItem) {
    // Add to cart if not already added
    bool inCart =
        widget.cartItems.any((item) => item['name'] == foodItem['name']);
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

  // SHIMMER WIDGETS

  Widget _buildCategoryShimmer() {
    return Container(
      height: 60,
      padding: const EdgeInsets.only(left: 16),
      margin: const EdgeInsets.only(top: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 5, // Show 5 shimmer placeholders
          itemBuilder: (_, __) => Container(
            width: 100,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFoodCardShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image placeholder
            AspectRatio(
              aspectRatio: 1.5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
            ),

            // Content area
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title placeholder
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price placeholder
                  Container(
                    width: 80,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Buttons placeholder
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
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
    );
  }

  Widget _buildFoodItemsShimmer() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: 6, // Show 6 shimmer placeholders
      itemBuilder: (_, __) => _buildFoodCardShimmer(),
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> foodItem) {
    bool isFavorite =
        widget.favoriteItems.any((item) => item['name'] == foodItem['name']);
    bool inCart =
        widget.cartItems.any((item) => item['name'] == foodItem['name']);

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
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: AspectRatio(
                      aspectRatio: 1.5,
                      child: Image.network(
                        foodItem['image'],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              color: Colors.white,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.broken_image,
                                color: Colors.grey[400], size: 50),
                          );
                        },
                      ),
                    ),
                  ),

                  // Rest of your Stack elements...
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).primaryColor.withAlpha(204),
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
                                  color: foodItem['isVegetarian'] == false
                                      ? Colors.green
                                      : Colors.red,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
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
                    const SizedBox(height: 8),
                    if (foodItem.containsKey('hasDiscount') &&
                        foodItem['hasDiscount'] == true) ...[
                      Row(
                        children: [
                          Text(
                            '₹${foodItem['price'] ?? 0}',
                            style: TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\₹${((num.tryParse(foodItem['price']?.toString() ?? '0') ?? 0) * (1 - (num.tryParse(foodItem['discount']?.toString() ?? '0') ?? 0) / 100)).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        '\₹${foodItem['price'] ?? 0}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
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
                                color: inCart
                                    ? Colors.green
                                    : Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: (inCart
                                            ? Colors.green
                                            : Theme.of(context).primaryColor)
                                        .withAlpha(76),
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
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.no_food,
              size: 100,
              color: Colors.grey[400],
            ),
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
            // App bar with search - Always show this part
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
                              fontSize: 20,
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
                                icon:
                                    Icon(Icons.clear, color: Colors.grey[400]),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Categories list - Show shimmer or actual categories
            _isLoading
                ? _buildCategoryShimmer()
                : Container(
                    height: 30,
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
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
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withAlpha(76),
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
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

            // Food items grid - Show shimmer, empty state, or actual items
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoading
                    ? _buildFoodItemsShimmer()
                    : filteredFoodItems.isEmpty
                        ? _buildEmptyState()
                        : GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
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
                                      0.4 +
                                          (index / filteredFoodItems.length) *
                                              0.6,
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
