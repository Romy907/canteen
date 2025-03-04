import 'package:flutter/material.dart';

class Order {
  final String itemName;
  final double price;
  final String date;
  final int quantity;

  Order({
    required this.itemName,
    required this.price,
    required this.date,
    required this.quantity,
  });
}

class MyOrdersScreen extends StatefulWidget {
  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<Order> orderHistory = [
    Order(itemName: 'Burger', price: 50, date: '2025-02-18', quantity: 2),
    Order(itemName: 'Pizza', price: 110, date: '2025-02-15', quantity: 1),
    Order(itemName: 'Soda', price: 70, date: '2025-02-12', quantity: 3),
    Order(itemName: 'Pasta', price: 75, date: '2025-02-10', quantity: 2),
  ];

  String _selectedFilter = 'None';
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilterOptions(context),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetFilter,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView.builder(
          itemCount: _filteredHistory().length,
          itemBuilder: (context, index) {
            final order = _filteredHistory()[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color:  const Color.fromARGB(255, 241, 233, 233),
              child: ListTile(
                leading: CircleAvatar(
                   backgroundColor:   Colors.blue ,
                  child: Text('${order.quantity}',
                  style: TextStyle(color: const Color.fromARGB(255, 19, 19, 19), fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(order.itemName,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Date: ${order.date} - ₹${order.price.toStringAsFixed(2)}'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.date_range),
              title: Text('Sort by Date'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedFilter = 'Date';
                  orderHistory.sort((a, b) => b.date.compareTo(a.date));
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.monetization_on),
              title: Text('Sort by Price (High to Low)'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedFilter = 'Price';
                  orderHistory.sort((a, b) => b.price.compareTo(a.price));
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart),
              title: Text('Sort by Quantity (High to Low)'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedFilter = 'Quantity';
                  orderHistory.sort((a, b) => b.quantity.compareTo(a.quantity));
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _resetFilter() {
    setState(() {
      _selectedFilter = 'None';
      orderHistory = [
        Order(itemName: 'Burger', price: 50, date: '2025-02-18', quantity: 2),
        Order(itemName: 'Pizza', price: 110, date: '2025-02-15', quantity: 1),
        Order(itemName: 'Soda', price: 70, date: '2025-02-12', quantity: 3),
        Order(itemName: 'Pasta', price: 75, date: '2025-02-10', quantity: 2),
      ];
    });
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(Duration(seconds: 2)); 
    setState(() {
      orderHistory.add(
        Order(itemName: 'New Item', price: 100, date: '2025-02-20', quantity: 1),
      );
      _isRefreshing = false;
    });
  }

  List<Order> _filteredHistory() {
    return orderHistory;
  }
}