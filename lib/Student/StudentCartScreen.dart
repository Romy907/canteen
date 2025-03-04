import 'package:flutter/material.dart';

class StudentCartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(List<Map<String, dynamic>>) onCartUpdated; // ✅ Callback

  const StudentCartScreen({super.key, required this.cartItems, required this.onCartUpdated});

  @override
  _StudentCartScreenState createState() => _StudentCartScreenState();
}

class _StudentCartScreenState extends State<StudentCartScreen> {
  late List<Map<String, dynamic>> cartItems;

  @override
  void initState() {
    super.initState();
    cartItems = widget.cartItems.map((item) {
      return {
        ...item,
        "quantity": item.containsKey("quantity") ? item["quantity"] : 1,
        "price": item["price"] is String ? double.parse(item["price"]) : item["price"], // Ensure price is a number
      };
    }).toList();
  }

  // ✅ Update cart in StudentHomeScreen
  void _updateCart() {
    widget.onCartUpdated(cartItems);
  }

  // ✅ Increase Quantity
  void _increaseQuantity(int index) {
    setState(() {
      cartItems[index]["quantity"] += 1;
    });
    _updateCart();
  }

  // ✅ Decrease Quantity
  void _decreaseQuantity(int index) {
    setState(() {
      if (cartItems[index]["quantity"] > 1) {
        cartItems[index]["quantity"] -= 1;
      } else {
        _removeItem(index);
      }
    });
    _updateCart();
  }

  // ✅ Remove Item from Cart
  void _removeItem(int index) {
    setState(() {
      cartItems.removeAt(index);
    });
    _updateCart();
  }

  // ✅ Calculate Total Amount
  double _getTotalAmount() {
    return cartItems.fold(0.0, (total, item) => total + (item["price"] * item["quantity"]));
  }

  // ✅ Calculate Total Items
  int _getTotalItems() {
    return cartItems.fold(0, (total, item) => total + (item["quantity"] as int));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Cart"),
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text("Your cart is empty!"))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.blue, // text color
                      minimumSize: Size(200, 40), // button size
                    ),
                    onPressed: () {
                      // Handle proceed to buy action
                    },
                    child: Text(
                      "Proceed to Buy (${_getTotalItems()} items)",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          leading: Image.asset(
                            item["image"],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(item["name"]),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Price: ₹${item["price"]}"),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  // ✅ Decrease Quantity Button
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () => _decreaseQuantity(index),
                                  ),
                                  Text(
                                    "${item["quantity"]}",
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  // ✅ Increase Quantity Button
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                    onPressed: () => _increaseQuantity(index),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.black),
                                    onPressed: () => _removeItem(index),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // ✅ Total Amount
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Amount : ",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          "₹${_getTotalAmount().toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}