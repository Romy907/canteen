import 'package:flutter/material.dart';
import 'dart:ui';
import 'CheckOutScreen.dart';

class StudentCartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(List<Map<String, dynamic>>) onCartUpdated;

  const StudentCartScreen({
    Key? key,
    required this.cartItems,
    required this.onCartUpdated,
  }) : super(key: key);

  @override
  _StudentCartScreenState createState() => _StudentCartScreenState();
}

class _StudentCartScreenState extends State<StudentCartScreen>
    with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> cartItems;
  late AnimationController _animationController;
  final Map<int, Animation<double>> _itemAnimations = {};

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize cart items with proper data types
    cartItems = widget.cartItems.map((item) {
      return {
        ...item,
        "quantity": item.containsKey("quantity") ? item["quantity"] : 1,
        "price": _parsePrice(item["price"]),
      };
    }).toList();

    // Set up animations for each cart item
    _setupItemAnimations();
  }

  // Helper method to safely parse price
  double _parsePrice(dynamic price) {
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      try {
        return double.parse(price.replaceAll(RegExp(r'[^\d.]'), ''));
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  void _setupItemAnimations() {
    for (var i = 0; i < cartItems.length; i++) {
      _itemAnimations[i] = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(0.0, 0.8, curve: Curves.easeOut),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Update cart in StudentHomeScreen
  void _updateCart() {
    widget.onCartUpdated(cartItems);
  }

  // Increase Quantity
  void _increaseQuantity(int index) {
    setState(() {
      cartItems[index]["quantity"] = (cartItems[index]["quantity"] as int) + 1;
    });
    _updateCart();
  }

  // Decrease Quantity
  void _decreaseQuantity(int index) {
    setState(() {
      if (cartItems[index]["quantity"] > 1) {
        cartItems[index]["quantity"] =
            (cartItems[index]["quantity"] as int) - 1;
      } else {
        _showRemoveConfirmation(index);
      }
    });
    _updateCart();
  }

  // Show confirmation dialog before removing item
  void _showRemoveConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('Remove Item'),
        content: Text('Remove ${cartItems[index]["name"]} from your cart?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _removeItem(index);
            },
          ),
        ],
      ),
    );
  }

  // Remove Item from Cart with animation
  void _removeItem(int index) {
    // Animate out
    _itemAnimations[index] = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward(from: 0.0).then((_) {
      setState(() {
        cartItems.removeAt(index);
        // Reset animations
        _itemAnimations.clear();
        for (var i = 0; i < cartItems.length; i++) {
          _itemAnimations[i] = Tween<double>(begin: 1.0, end: 0.0).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(0.0, 0.8, curve: Curves.easeOut),
            ),
          );
        }
      });
      _updateCart();
      _animationController.reset();
    });
  }

  // Calculate Total Amount
  double _getTotalAmount() {
    return cartItems.fold(
        0.0,
        (total, item) =>
            total + (_parsePrice(item["price"]) * (item["quantity"] as int)));
  }

  // Calculate Total Items
  int _getTotalItems() {
    return cartItems.fold(
        0, (total, item) => total + (item["quantity"] as int));
  }

  // Proceed to checkout
  void _proceedToCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CheckOutScreen(
          items: cartItems,
          isBuyNow: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: cartItems.isEmpty ? _buildEmptyCartState() : _buildCartContent(),
    );
  }

  Widget _buildEmptyCartState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: Colors.grey[300],
          ),
          SizedBox(height: 24),
          Text(
            "Your cart is empty",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          Text(
            "Looks like you haven't added any items yet",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        // Cart items counter and info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.shopping_bag_outlined,
                  color: Theme.of(context).primaryColor),
              SizedBox(width: 12),
              Text(
                "${_getTotalItems()} ${_getTotalItems() == 1 ? 'item' : 'items'} in your cart",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),

              Spacer(), // Add spacer to push the clear button to the right

              // Clear cart button
              if (cartItems.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    constraints: BoxConstraints.tightFor(width: 40, height: 40),
                    icon: Icon(Icons.delete_outline,
                        color: Colors.red[700], size: 20),
                    tooltip: 'Clear cart',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text('Clear Cart'),
                          content: Text(
                              'Are you sure you want to remove all items from your cart?'),
                          actions: [
                            TextButton(
                              child: Text('Cancel'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              child: Text(
                                'Clear All',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                setState(() {
                                  cartItems.clear();
                                });
                                _updateCart();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // Cart items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            physics: const BouncingScrollPhysics(),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return Dismissible(
                key: Key(item["name"]),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _removeItem(index);
                },
                confirmDismiss: (direction) async {
                  bool? result = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Text('Remove Item'),
                      content: Text('Remove ${item["name"]} from your cart?'),
                      actions: [
                        TextButton(
                          child: Text('Cancel'),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        TextButton(
                          child: Text(
                            'Remove',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    ),
                  );
                  return result ?? false;
                },
                child: _buildCartItem(item, index),
              );
            },
          ),
        ),

        // Bottom checkout bar
        _buildCheckoutBar(),
      ],
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Food image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                item["image"],
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),

            // Food details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Food Type Indicator
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: item["type"] == "Veg"
                              ? Colors.green[50]
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: item["type"] == "Veg"
                                ? Colors.green
                                : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.circle,
                          color:
                              item["type"] == "Veg" ? Colors.green : Colors.red,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item["name"],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Category
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item["category"],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price and quantity controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Text(
                        "₹${_parsePrice(item["price"]).toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),

                      // Quantity controls
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            _buildQuantityButton(
                              icon: Icons.remove,
                              onPressed: () => _decreaseQuantity(index),
                              isDecrease: true,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                "${item["quantity"]}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _buildQuantityButton(
                              icon: Icons.add,
                              onPressed: () => _increaseQuantity(index),
                              isDecrease: false,
                            ),
                          ],
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

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDecrease,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDecrease ? Colors.red[50] : Colors.green[50],
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDecrease ? Colors.red : Colors.green,
        ),
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Price details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Subtotal:",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    "₹${_getTotalAmount().toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Taxes & Charges:",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    "₹${(_getTotalAmount() * 0.05).toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Container(
                height: 1,
                color: Colors.grey[300],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "₹${(_getTotalAmount() + (_getTotalAmount() * 0.05)).toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Checkout button
              ElevatedButton(
                onPressed: _proceedToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Proceed to Checkout",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
