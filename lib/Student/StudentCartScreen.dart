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

    if (cartItems.isEmpty) {
      Navigator.pop(context, cartItems); // ✅ Return updated cart
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: cartItems.isEmpty
          ? const Center(child: Text("Your cart is empty!"))
          : ListView.builder(
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
                        Text("Price: ${item["price"]}"),
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
                            
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
