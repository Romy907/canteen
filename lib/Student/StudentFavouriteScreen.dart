import 'package:canteen/Student/CheckOutScreen.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class StudentFavouriteScreen extends StatefulWidget {
  final List<Map<String, dynamic>> favoriteItems;
  final Function(List<Map<String, dynamic>>)? onFavoritesUpdated;
  final Function(Map<String, dynamic>)? onAddToCart;
  final Function(Map<String, dynamic>)? onBuyNow;

  const StudentFavouriteScreen({
    Key? key,
    required this.favoriteItems,
    this.onFavoritesUpdated,
    this.onAddToCart,
    this.onBuyNow,
  }) : super(key: key);

  @override
  _StudentFavouriteScreenState createState() => _StudentFavouriteScreenState();
}

class _StudentFavouriteScreenState extends State<StudentFavouriteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Map<String, dynamic>> _favoriteItems;
  String _searchQuery = '';

  // Current timestamp from user input
  final String _currentTimestamp = '2025-03-06 08:11:44';
  final String _username = 'navin280123';

  @override
  void initState() {
    super.initState();
    _favoriteItems = List.from(widget.favoriteItems);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _removeFromFavorites(int index) {
    final removedItem = _favoriteItems[index];
    setState(() {
      _favoriteItems.removeAt(index);
    });

    // Update parent if callback provided
    if (widget.onFavoritesUpdated != null) {
      widget.onFavoritesUpdated!(_favoriteItems);
    }

    // Show snackbar with undo option
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removedItem['name']} removed from favorites'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              _favoriteItems.insert(index, removedItem);
            });
            if (widget.onFavoritesUpdated != null) {
              widget.onFavoritesUpdated!(_favoriteItems);
            }
          },
        ),
      ),
    );
  }

 

  void _buyNow(Map<String, dynamic> item) {
    // bool inCart =
    //     widget.cartItems.any((item) => item['name'] == foodItem['name']);
    // if (!inCart) {
    //   setState(() {
    //     widget.cartItems.add(foodItem);
    //     widget.updateCounts();
    //   });
    // }

    // Navigate directly to checkout with this item
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CheckOutScreen(
          items: [item],
          isBuyNow: true,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_searchQuery.isEmpty) return _favoriteItems;

    return _favoriteItems
        .where((item) =>
            item['name']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            item['category']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            if (_favoriteItems.isNotEmpty) _buildHeader(),
            Expanded(
              child: _favoriteItems.isEmpty
                  ? _buildEmptyState()
                  : _filteredItems.isEmpty
                      ? _buildNoSearchResultsState()
                      : _buildFavoritesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Favorites',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_favoriteItems.length} items saved',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (_favoriteItems.isNotEmpty)
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear Favorites'),
                        content: const Text(
                            'Are you sure you want to clear all items from favorites?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _favoriteItems.clear();
                              });
                              if (widget.onFavoritesUpdated != null) {
                                widget.onFavoritesUpdated!(_favoriteItems);
                              }
                              Navigator.pop(context);
                            },
                            child: const Text('Clear All',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_sweep_outlined,
                      color: Colors.redAccent),
                  tooltip: 'Clear all favorites',
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_favoriteItems.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search favorites...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: Colors.grey[400], size: 20),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    // Calculate responsive grid based on screen width
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 600 ? 3 : 2;
    final childAspectRatio = width > 600 ? 0.85 : 0.78;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 800));
        setState(() {});
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredItems.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final delay = index * 0.1;
              final animation = CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  delay.clamp(0.0, 0.9),
                  (delay + 0.6).clamp(0.0, 1.0),
                  curve: Curves.easeOutQuad,
                ),
              );

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildFavoriteItem(context, _filteredItems[index], index),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteItem(
      BuildContext context, Map<String, dynamic> item, int index) {
    // Format price string properly
    final price = item["price"] is String
        ? item["price"].toString().startsWith('₹')
            ? item["price"]
            : "₹${item["price"]}"
        : "₹${item["price"].toString()}";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Image Section
            Stack(
              children: [
                SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: Image.asset(
                    item["image"],
                    fit: BoxFit.cover,
                  ),
                ),

                // Veg/Non-veg indicator & Category
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category - with overflow handling
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item["category"] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        // Veg/Non-veg indicator
                        Container(
                          padding: const EdgeInsets.all(3),
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.circle,
                            color: (item["type"] ?? '') == 'Veg'
                                ? Colors.green
                                : Colors.red,
                            size: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Remove from favorites button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _removeFromFavorites(index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Item details section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food name
                    Text(
                      item["name"],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Price
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Action buttons
                    Row(
                      children: [
                        // Buy Now button
                        Expanded(
                          child: _buildActionButton(
                            label: "Buy Now",
                            icon: Icons.shopping_bag_outlined,
                            color: Colors.orange[700]!,
                            onPressed: () => _buyNow(item),
                          ),
                        ),
                       
                        
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build action buttons
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 100,
              color: Colors.red.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              "No favorites yet",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "Items you mark as favorites will appear here",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No matching favorites",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try a different search term",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
