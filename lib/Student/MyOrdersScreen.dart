import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Order {
  final String id;
  final String itemName;
  final double price;
  final String date;
  final int quantity;
  String status;
  final String imageUrl;
  final String storeId;
  final Map<String, dynamic>? statusHistory;

  Order({
    required this.id,
    required this.itemName,
    required this.price,
    required this.date,
    required this.quantity,
    required this.status,
    required this.imageUrl,
    required this.storeId,
    this.statusHistory,
  });

  // Create Order from Firebase snapshot
  factory Order.fromSnapshot(String orderId, Map<String, dynamic> data) {
    return Order(
      id: orderId,
      itemName: data['itemName'] ?? 'Unknown Item',
      price: (data['price'] != null)
          ? double.parse(data['price'].toString())
          : 0.0,
      date: data['orderDate'] ?? DateTime.now().toString(),
      quantity: data['quantity'] ?? 1,
      status: data['status'] ?? 'pending',
      imageUrl: data['imageUrl'] ?? 'assets/images/placeholder.jpg',
      storeId: data['storeId'] ?? '',
      statusHistory: data['statusHistory'] != null
          ? Map<String, dynamic>.from(data['statusHistory'])
          : null,
    );
  }
}

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with TickerProviderStateMixin {
  late List<Order> orderHistory = [];
  late List<Order> filteredOrders = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedFilter = 'None';
  late AnimationController _animationController;
  late String _currentDate;
  late String _username;
  String? id;

  // Firebase references
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;

  // Subscription for live updates
  List<StreamSubscription<DatabaseEvent>> _subscriptions = [];

  // Status animation controller map
  Map<String, AnimationController> _statusAnimationControllers = {};

  // Filter options
  final List<Map<String, dynamic>> _filterOptions = [
    {'title': 'Date (Newest First)', 'value': 'Date', 'icon': Icons.date_range},
    {
      'title': 'Price (High to Low)',
      'value': 'Price',
      'icon': Icons.monetization_on
    },
    {
      'title': 'Quantity (High to Low)',
      'value': 'Quantity',
      'icon': Icons.shopping_cart
    },
    {'title': 'Status', 'value': 'Status', 'icon': Icons.local_shipping},
  ];

  @override
  void initState() {
    super.initState();

    // Get current date from the provided info
    _currentDate = '2025-03-29 11:33:31';
    _username = 'navin280123';

    // Initialize animation controller for UI effects
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Get user ID from Firebase Auth or SharedPreferences
    _getUserId().then((_) {
      // Load orders from Firebase
      _loadOrdersFromFirebase();
    });
  }

  Future<void> _getUserId() async {
    // Get userId from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _userId = (prefs.getString('email') ?? '$_username@examplecom')
      .replaceAll(RegExp(r'[.#$[\]]'), '');
  
  }

  @override
  void dispose() {
    _animationController.dispose();

    // Dispose all status animation controllers
    for (var controller in _statusAnimationControllers.values) {
      controller.dispose();
    }

    // Cancel all Firebase subscriptions
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }

    super.dispose();
  }

  // Load orders from Firebase
  Future<void> _loadOrdersFromFirebase() async {
  setState(() {
    _isLoading = true;
    orderHistory.clear();
  });

  try {
    // Get user email from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    String userEmail = (prefs.getString('email') ?? '$_username@examplecom')
      .replaceAll(RegExp(r'[.#$[\]]'), '');
    
    // Fetch live orders
    DatabaseEvent liveOrdersEvent = await _database
        .child('User/$userEmail/liveOrder')
        .once();
    
    // Fetch completed orders
    DatabaseEvent completedOrdersEvent = await _database
        .child('User/$userEmail/completedOrder')
        .once();
    
    // Process live orders
    if (liveOrdersEvent.snapshot.exists) {
      Map<dynamic, dynamic> liveOrdersMap = liveOrdersEvent.snapshot.value as Map;
      print(liveOrdersMap.toString());
      await _processOrders(liveOrdersMap, true);
    }
    
    // Process completed orders
    if (completedOrdersEvent.snapshot.exists) {
      Map<dynamic, dynamic> completedOrdersMap = completedOrdersEvent.snapshot.value as Map;
      print(completedOrdersMap.toString());
      await _processOrders(completedOrdersMap, false);
    }
    
    // Sort by date (newest first)
    orderHistory.sort((a, b) => b.date.compareTo(a.date));
    filteredOrders = List.from(orderHistory);
    
  } catch (e) {
    print('Error loading orders: $e');
    _createSampleOrders();
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
Future<void> _processOrders(Map<dynamic, dynamic> orderMap, bool isLive) async {
  List<Future<void>> futures = [];
  
  orderMap.forEach((orderId, storeId) {
    // For each order ID and store ID, fetch the order details
    Future<void> future = _database
        .child('$storeId/orders/$orderId')
        .once()
        .then((DatabaseEvent event) {
          if (event.snapshot.exists) {
            Map<dynamic, dynamic> orderData = event.snapshot.value as Map;
            final orderDetails = Map<String, dynamic>.from(orderData);
            
            // Create Order object
            final Order order = Order.fromSnapshot(orderId.toString(), orderDetails);
            
            // If needed, set status based on isLive
            if (!isLive && order.status != 'delivered') {
              order.status = 'delivered';
            }
            
            orderHistory.add(order);
            
            // Setup real-time listener only for live orders
            if (isLive) {
              _setupOrderStatusListener(orderId.toString(), storeId.toString());
              
              // Create animation controller for status changes
              _statusAnimationControllers[orderId.toString()] = AnimationController(
                duration: const Duration(milliseconds: 800),
                vsync: this,
              );
            }
          }
        });
    
    futures.add(future);
  });
  
  // Wait for all orders to be fetched
  await Future.wait(futures);
}
  // Set up real-time listener for order status changes
  void _setupOrderStatusListener(String orderId, String storeId) {
  final subscription = _database
      .child('$storeId/order/$orderId')
      .onValue
      .listen((event) {
    if (event.snapshot.exists) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final newStatus = data['status'] ?? 'pending';

      // Find the order and update its status if changed
      final index = orderHistory.indexWhere((order) => order.id == orderId);
      if (index != -1 && orderHistory[index].status != newStatus) {
        setState(() {
          // Get the old status for animation purposes
          final oldStatus = orderHistory[index].status;

          // Update order status
          orderHistory[index].status = newStatus;

          // Apply the same update to filtered list if it contains this order
          final filteredIndex =
              filteredOrders.indexWhere((order) => order.id == orderId);
          if (filteredIndex != -1) {
            filteredOrders[filteredIndex].status = newStatus;
          }

          // Show a notification of status change
          _showStatusChangeNotification(orderId, oldStatus, newStatus);
          _playStatusChangeAnimation(orderId);
          
          // If status changed to delivered, move from liveOrder to completedOrder
          if (newStatus == 'delivered') {
            _moveOrderToCompleted(orderId, storeId);
          }
        });
      }
    }
  });

  _subscriptions.add(subscription);
}
Future<void> _moveOrderToCompleted(String orderId, String storeId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    String userEmail = prefs.getString('email') ?? _username;
    
    // First remove from liveOrder
    await _database.child('User/$userEmail/liveOrder/$orderId').remove();
    
    // Then add to completedOrder
    await _database.child('User/$userEmail/completedOrder/$orderId').set(storeId);
  } catch (e) {
    print('Error moving order to completed: $e');
  }
}

  // Play status change animation
  void _playStatusChangeAnimation(String orderId) {
    if (_statusAnimationControllers.containsKey(orderId)) {
      _statusAnimationControllers[orderId]!.reset();
      _statusAnimationControllers[orderId]!.forward();
    }
  }

  // Show notification for status change
  void _showStatusChangeNotification(
      String orderId, String oldStatus, String newStatus) {
    final order = orderHistory.firstWhere((order) => order.id == orderId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Status Updated!',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
                'Your order for ${order.itemName} has changed from $oldStatus to $newStatus'),
          ],
        ),
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VIEW',
          onPressed: () {
            _showOrderDetails(order);
          },
        ),
        backgroundColor: _getStatusColor(newStatus),
      ),
    );
  }

  // Create sample orders for demo (will connect to real Firebase in production)
  void _createSampleOrders() {
    // Get a Firebase-compatible storeid format for our demo
    String storeId = _userId ?? '173988898092';

    orderHistory = [
      Order(
        id: 'ORD-${_generateOrderId(0)}',
        itemName: 'Double Cheese Burger',
        price: 199.00,
        date: '2025-03-04 12:35:22',
        quantity: 2,
        status: 'processing', // Set to processing for demo
        imageUrl: 'assets/images/burger.jpg',
        storeId: storeId,
        statusHistory: {
          '2025-03-04 12:35:22': 'pending',
          '2025-03-04 12:40:15': 'processing',
        },
      ),
      Order(
        id: 'ORD-${_generateOrderId(1)}',
        itemName: 'Margherita Pizza',
        price: 349.00,
        date: '2025-03-01 19:15:44',
        quantity: 1,
        status: 'delivered',
        imageUrl: 'assets/images/pizza.jpg',
        storeId: storeId,
        statusHistory: {
          '2025-03-01 19:15:44': 'pending',
          '2025-03-01 19:20:12': 'processing',
          '2025-03-01 19:45:30': 'delivered',
        },
      ),
      Order(
        id: 'ORD-${_generateOrderId(2)}',
        itemName: 'Cold Coffee',
        price: 129.00,
        date: '2025-02-25 14:20:11',
        quantity: 3,
        status: 'delivered',
        imageUrl: 'assets/images/coffee.jpg',
        storeId: storeId,
        statusHistory: {
          '2025-02-25 14:20:11': 'pending',
          '2025-02-25 14:25:30': 'processing',
          '2025-02-25 14:40:15': 'delivered',
        },
      ),
      Order(
        id: 'ORD-${_generateOrderId(3)}',
        itemName: 'Pasta Arrabiata',
        price: 249.00,
        date: '2025-02-20 20:05:38',
        quantity: 2,
        status: 'delivered',
        imageUrl: 'assets/images/pasta.jpg',
        storeId: storeId,
        statusHistory: {
          '2025-02-20 20:05:38': 'pending',
          '2025-02-20 20:10:22': 'processing',
          '2025-02-20 20:35:40': 'delivered',
        },
      ),
      Order(
        id: 'ORD-${_generateOrderId(4)}',
        itemName: 'French Fries',
        price: 99.00,
        date: '2025-02-15 13:42:17',
        quantity: 2,
        status: 'delivered',
        imageUrl: 'assets/images/fries.jpg',
        storeId: storeId,
        statusHistory: {
          '2025-02-15 13:42:17': 'pending',
          '2025-02-15 13:45:30': 'processing',
          '2025-02-15 14:00:12': 'delivered',
        },
      ),
    ];

    // Setup animation controllers for sample orders
    for (var order in orderHistory) {
      _statusAnimationControllers[order.id] = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );

      // For demo purposes, simulate status updates for the first order if it's processing
      if (order.status == 'processing') {
        _simulateStatusUpdates(order);
      }
    }

    filteredOrders = List.from(orderHistory);
  }

  // For demo: simulate status updates every few seconds
  void _simulateStatusUpdates(Order order) {
    // After 10 seconds, change status to 'on the way'
    Future.delayed(Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          String oldStatus = order.status;
          order.status = 'on the way';

          // Update in filtered list if present
          final filteredIndex =
              filteredOrders.indexWhere((o) => o.id == order.id);
          if (filteredIndex != -1) {
            filteredOrders[filteredIndex].status = 'on the way';
          }

          _showStatusChangeNotification(order.id, oldStatus, 'on the way');
          _playStatusChangeAnimation(order.id);
        });

        // After another 15 seconds, change to 'delivered'
        Future.delayed(Duration(seconds: 15), () {
          if (mounted) {
            setState(() {
              String oldStatus = order.status;
              order.status = 'delivered';

              // Update in filtered list if present
              final filteredIndex =
                  filteredOrders.indexWhere((o) => o.id == order.id);
              if (filteredIndex != -1) {
                filteredOrders[filteredIndex].status = 'delivered';
              }

              _showStatusChangeNotification(order.id, oldStatus, 'delivered');
              _playStatusChangeAnimation(order.id);
            });
          }
        });
      }
    });
  }

  // Generate a consistent order ID based on date and username
  String _generateOrderId(int index) {
    final dateComponents = _currentDate.split(' ')[0].split('-');
    final year = dateComponents[0].substring(2);
    final month = dateComponents[1];
    final day = dateComponents[2];
    return '$year$month$day-${_username.substring(0, 4).toUpperCase()}-${1000 + index}';
  }

  // Refresh data and check for new orders
  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);

    try {
      await _loadOrdersFromFirebase();
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  // Apply selected filter
  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      filteredOrders = List.from(orderHistory);

      switch (filter) {
        case 'Date':
          filteredOrders.sort((a, b) => b.date.compareTo(a.date));
          break;
        case 'Price':
          filteredOrders.sort(
              (a, b) => (b.price * b.quantity).compareTo(a.price * a.quantity));
          break;
        case 'Quantity':
          filteredOrders.sort((a, b) => b.quantity.compareTo(a.quantity));
          break;
        case 'Status':
          // Sort by status priority: processing first, then pending, then delivered
          filteredOrders.sort((a, b) {
            int getPriority(String status) {
              switch (status.toLowerCase()) {
                case 'processing':
                  return 0;
                case 'on the way':
                  return 1;
                case 'pending':
                  return 2;
                case 'delivered':
                  return 3;
                case 'cancelled':
                  return 4;
                default:
                  return 5;
              }
            }

            return getPriority(a.status).compareTo(getPriority(b.status));
          });
          break;
      }
    });
  }

  // Reset all filters
  void _resetFilter() {
    setState(() {
      _selectedFilter = 'None';
      filteredOrders = List.from(orderHistory);
      // Default sort by most recent date
      filteredOrders.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  // Format date in readable format
  String _formatDate(String dateString) {
    final DateTime date = DateTime.parse(dateString);
    final now = DateTime.parse(_currentDate);

    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (difference == 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, yyyy · h:mm a').format(date);
    }
  }

  // Show filter options in bottom sheet
  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sort Orders By',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._filterOptions.map((option) => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedFilter == option['value']
                            ? Theme.of(context).primaryColor.withAlpha(25)
                            : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        option['icon'],
                        color: _selectedFilter == option['value']
                            ? Theme.of(context).primaryColor
                            : Colors.grey[800],
                      ),
                    ),
                    title: Text(
                      option['title'],
                      style: TextStyle(
                        fontWeight: _selectedFilter == option['value']
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: _selectedFilter == option['value']
                        ? Icon(Icons.check,
                            color: Theme.of(context).primaryColor)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _applyFilter(option['value']);
                    },
                  )),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.clear_all,
                    color: Colors.red[700],
                  ),
                ),
                title: const Text('Clear Filters'),
                onTap: () {
                  Navigator.pop(context);
                  _resetFilter();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Show order details in modal bottom sheet
  void _showOrderDetails(Order order) {
    // Get screen width once for responsive layouts
    final screenWidth = MediaQuery.of(context).size.width;
    final useVerticalLayout = screenWidth < 280;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Drag indicator and header
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    // Order ID and close button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              order.id,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),

                    // Scrollable content area
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        children: [
                          const SizedBox(height: 10),

                          // Live status indicator with animation
                          _buildLiveStatusIndicator(order),

                          const SizedBox(height: 24),

                          // Item details with responsive layout
                          screenWidth < 300
                              ? _buildNarrowItemDetails(context, order)
                              : _buildWideItemDetails(context, order),

                          const Divider(height: 32),

                          // Order status timeline - new section
                          _buildOrderTimeline(order),

                          const Divider(height: 32),

                          // Order summary
                          const Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSummaryRow('Item Price',
                              '₹${order.price.toStringAsFixed(2)}'),
                          _buildSummaryRow('Quantity', '${order.quantity}'),
                          _buildSummaryRow('Item Total',
                              '₹${(order.price * order.quantity).toStringAsFixed(2)}'),
                          _buildSummaryRow('Delivery Fee', '₹25.00'),
                          _buildSummaryRow('Taxes',
                              '₹${((order.price * order.quantity) * 0.05).toStringAsFixed(2)}'),

                          const Divider(height: 24),

                          _buildSummaryRow(
                            'Total Amount',
                            '₹${((order.price * order.quantity) + 25 + (order.price * order.quantity) * 0.05).toStringAsFixed(2)}',
                            isTotal: true,
                          ),

                          const SizedBox(height: 24),

                          // Order time and delivery info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow(Icons.access_time, 'Ordered on',
                                    _formatDate(order.date)),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                    Icons.location_on,
                                    'Delivery Address',
                                    'Campus Canteen, Main Building'),
                                if (order.status.toLowerCase() ==
                                    'delivered') ...[
                                  const SizedBox(height: 12),
                                  _buildInfoRow(Icons.check_circle,
                                      'Delivered at', _getDeliveryTime(order)),
                                ]
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),

                    // Bottom buttons - fixed at bottom
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: useVerticalLayout
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _canReorder(order)
                                        ? () => _reorderItem(order)
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                    child: const Text('Reorder'),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _showHelpOptions(order),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      backgroundColor: Colors.grey[200],
                                      foregroundColor: Colors.black87,
                                      elevation: 0,
                                    ),
                                    child: const Text('Help'),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _showHelpOptions(order),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      backgroundColor: Colors.grey[200],
                                      foregroundColor: Colors.black87,
                                      elevation: 0,
                                    ),
                                    child: const Text('Help'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _canReorder(order)
                                        ? () => _reorderItem(order)
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                    child: const Text('Reorder'),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Build live status indicator with animation
  Widget _buildLiveStatusIndicator(Order order) {
    final animation = _statusAnimationControllers[order.id] ??
        AnimationController(
          duration: const Duration(milliseconds: 800),
          vsync: this,
        );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final glowValue = Tween<double>(begin: 0.0, end: 0.25)
            .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut))
            .value;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status).withOpacity(0.1 + glowValue),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _getStatusColor(order.status).withOpacity(glowValue),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _getStatusIcon(order.status),
                    color: _getStatusColor(order.status),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getStatusText(order.status),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _getStatusColor(order.status),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isActiveStatus(order.status)
                                    ? _getStatusColor(order.status)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStatusDescription(order.status),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_showStatusProgress(order.status)) ...[
                const SizedBox(height: 16),
                _buildStatusProgressBar(order.status),
              ],
            ],
          ),
        );
      },
    );
  }

  // Check if status is active and should pulse
  bool _isActiveStatus(String status) {
    return ['pending', 'processing', 'on the way']
        .contains(status.toLowerCase());
  }

  // Build a progress bar for active statuses
  Widget _buildStatusProgressBar(String status) {
    double progressValue;
    switch (status.toLowerCase()) {
      case 'pending':
        progressValue = 0.2;
        break;
      case 'processing':
        progressValue = 0.5;
        break;
      case 'on the way':
        progressValue = 0.8;
        break;
      default:
        progressValue = 1.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progressValue,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(status)),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildProgressDot('Ordered', progressValue >= 0.2, true),
            _buildProgressDot(
                'Preparing', progressValue >= 0.5, progressValue >= 0.2),
            _buildProgressDot(
                'On the way', progressValue >= 0.8, progressValue >= 0.5),
            _buildProgressDot(
                'Delivered', progressValue >= 1.0, progressValue >= 0.8),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressDot(String label, bool isActive, bool lineCompleted) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color:
                  isActive ? Theme.of(context).primaryColor : Colors.grey[300],
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Colors.grey[400]!,
                width: 2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color:
                  isActive ? Theme.of(context).primaryColor : Colors.grey[600],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Check if we should show progress bar for this status
  bool _showStatusProgress(String status) {
    return ['pending', 'processing', 'on the way', 'delivered']
        .contains(status.toLowerCase());
  }

  // Get estimated delivery time for delivered orders
  String _getDeliveryTime(Order order) {
    if (order.statusHistory != null &&
        order.statusHistory!.containsKey('delivered')) {
      return _formatDate(order.statusHistory!['delivered']);
    }

    // If we don't have status history, estimate 30 minutes after order time
    try {
      final orderTime = DateTime.parse(order.date);
      final deliveryTime = orderTime.add(Duration(minutes: 30));
      return DateFormat('MMM d, yyyy · h:mm a').format(deliveryTime);
    } catch (e) {
      return 'Unknown';
    }
  }

  // Build order timeline from status history
  Widget _buildOrderTimeline(Order order) {
    List<Map<String, String>> timeline = [];

    // If we have actual status history
    if (order.statusHistory != null && order.statusHistory!.isNotEmpty) {
      order.statusHistory!.forEach((time, status) {
        timeline.add({
          'time': time,
          'status': status,
        });
      });

      // Sort by time
      timeline.sort((a, b) => a['time']!.compareTo(b['time']!));
    } else {
      // Otherwise create estimated timeline based on current status
      timeline.add({
        'time': order.date,
        'status': 'ordered',
      });

      // Add processing timestamp if needed
      if (['processing', 'on the way', 'delivered']
          .contains(order.status.toLowerCase())) {
        final orderTime = DateTime.parse(order.date);
        final processingTime = orderTime.add(Duration(minutes: 5));
        timeline.add({
          'time': processingTime.toString(),
          'status': 'processing',
        });
      }

      // Add on the way timestamp if needed
      if (['on the way', 'delivered'].contains(order.status.toLowerCase())) {
        final orderTime = DateTime.parse(order.date);
        final onTheWayTime = orderTime.add(Duration(minutes: 15));
        timeline.add({
          'time': onTheWayTime.toString(),
          'status': 'on the way',
        });
      }

      // Add delivered timestamp if needed
      if (order.status.toLowerCase() == 'delivered') {
        final orderTime = DateTime.parse(order.date);
        final deliveredTime = orderTime.add(Duration(minutes: 30));
        timeline.add({
          'time': deliveredTime.toString(),
          'status': 'delivered',
        });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Order Timeline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: timeline.length,
          itemBuilder: (context, index) {
            final isLast = index == timeline.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getStatusColor(timeline[index]['status']!),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 50,
                        color: Colors.grey[300],
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusText(timeline[index]['status']!),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(timeline[index]['time']!),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDescription(timeline[index]['status']!),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: isLast ? 0 : 24),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Helper methods for responsive layout
  Widget _buildNarrowItemDetails(BuildContext context, Order order) {
    // Vertical layout for very narrow screens
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image centered
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              order.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 80,
                color: Colors.grey[300],
                child: const Icon(Icons.fastfood, color: Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Item details
        Text(
          order.itemName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Quantity: ${order.quantity}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Price: ₹${order.price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWideItemDetails(BuildContext context, Order order) {
    // Horizontal layout for normal screens
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            order.imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 80,
              height: 80,
              color: Colors.grey[300],
              child: const Icon(Icons.fastfood, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.itemName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Quantity: ${order.quantity}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Price: ₹${order.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Theme.of(context).primaryColor : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Build an info row with icon
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Get appropriate color based on order status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'on the way':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      case 'ordered':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  // Get appropriate icon based on order status
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle;
      case 'processing':
        return Icons.restaurant;
      case 'on the way':
        return Icons.delivery_dining;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
      case 'ordered':
        return Icons.watch_later;
      default:
        return Icons.info_outline;
    }
  }

  // Get status text for display
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'ordered':
        return 'Order Placed';
      case 'processing':
        return 'Preparing Your Order';
      case 'on the way':
        return 'On The Way';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown Status';
    }
  }

  // Get descriptive text for each status
  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'ordered':
        return 'Your order has been received and is awaiting confirmation';
      case 'processing':
        return 'Your food is being prepared by the restaurant';
      case 'on the way':
        return 'Your order is on the way to your location';
      case 'delivered':
        return 'Your order has been delivered successfully';
      case 'cancelled':
        return 'This order has been cancelled';
      default:
        return '';
    }
  }

  // Check if order can be reordered (only for delivered orders)
  bool _canReorder(Order order) {
    return order.status.toLowerCase() == 'delivered';
  }

  // Reorder functionality
  void _reorderItem(Order order) {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing your reorder...'),
              ],
            ),
          ),
        );
      },
    );

    // Simulate adding to cart
    Future.delayed(Duration(seconds: 2), () {
      // Dismiss loading dialog
      Navigator.of(context).pop();

      // Create a new order in Firebase with pending status
      if (_userId != null) {
        final newOrderId = 'ORD-${_generateOrderId(orderHistory.length)}';
        final newOrderData = {
          'itemName': order.itemName,
          'price': order.price.toString(),
          'orderDate': DateTime.now().toString(),
          'quantity': order.quantity,
          'status': 'pending',
          'imageUrl': order.imageUrl,
          'storeId': order.storeId,
          'statusHistory': {
            DateTime.now().toString(): 'pending',
          }
        };

        // Add to Firebase
        _database
            .child('users/$_userId/orders/$newOrderId')
            .set(newOrderData)
            .then((_) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Your order has been placed again!'),
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'VIEW',
                onPressed: () {
                  // Could navigate to order tracking screen
                  _refreshData();
                },
              ),
            ),
          );

          // Close order details
          Navigator.of(context).pop();

          // Refresh the orders list
          _refreshData();
        }).catchError((error) {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to place order: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    });
  }

  // Show help options for the order
  void _showHelpOptions(Order order) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How can we help?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              if (order.status.toLowerCase() != 'delivered') ...[
                _buildHelpOption(
                  context,
                  'Where is my order?',
                  'Track your current order status',
                  Icons.location_on,
                  () {
                    Navigator.pop(context);
                    // Implement order tracking screen navigation
                    // For now, just show a message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Order tracking would open here')),
                    );
                  },
                ),
              ],
              _buildHelpOption(
                context,
                'Contact Support',
                'Get help from our customer service',
                Icons.support_agent,
                () {
                  Navigator.pop(context);
                  // Implement contact support
                  _contactSupport(order);
                },
              ),
              if (order.status.toLowerCase() == 'pending' ||
                  order.status.toLowerCase() == 'processing') ...[
                _buildHelpOption(
                  context,
                  'Cancel Order',
                  'Cancel your current order',
                  Icons.cancel_outlined,
                  () {
                    Navigator.pop(context);
                    _showCancelOrderDialog(order);
                  },
                ),
              ],
              if (order.status.toLowerCase() == 'delivered') ...[
                _buildHelpOption(
                  context,
                  'Report an Issue',
                  'Report a problem with your order',
                  Icons.report_problem_outlined,
                  () {
                    Navigator.pop(context);
                    _reportIssue(order);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelpOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Contact support for an order
  void _contactSupport(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'How would you like to contact support about Order ${order.id}?'),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.call, color: Theme.of(context).primaryColor),
              title: Text('Call Support'),
              subtitle: Text('Speak directly to customer service'),
              onTap: () {
                Navigator.pop(context);
                // Simulate calling
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calling support...')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.chat, color: Theme.of(context).primaryColor),
              title: Text('Live Chat'),
              subtitle: Text('Chat with our support team'),
              onTap: () {
                Navigator.pop(context);
                // Simulate opening chat
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening live chat...')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.email, color: Theme.of(context).primaryColor),
              title: Text('Email Support'),
              subtitle: Text('Send an email regarding your order'),
              onTap: () {
                Navigator.pop(context);
                // Simulate email
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Composing email to support...')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  // Report an issue with a delivered order
  void _reportIssue(Order order) {
    final issues = [
      'Items missing from my order',
      'Food quality was poor',
      'Order was cold when delivered',
      'Wrong order was delivered',
      'Other issue'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report an Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What issue did you experience with your order?'),
            SizedBox(height: 16),
            ...issues
                .map((issue) => ListTile(
                      title: Text(issue),
                      onTap: () {
                        Navigator.pop(context);

                        // Show feedback form
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Provide Details'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                    'Please describe the issue with your order:'),
                                SizedBox(height: 16),
                                TextField(
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    hintText: 'Enter details here...',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('CANCEL'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Thank you for your feedback. We\'ll look into it right away.'),
                                      duration: Duration(seconds: 4),
                                    ),
                                  );
                                },
                                child: Text('SUBMIT'),
                              ),
                            ],
                          ),
                        );
                      },
                    ))
                .toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  // Show cancel order confirmation dialog
  void _showCancelOrderDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel this order?'),
            SizedBox(height: 16),
            Text(
              'Please note:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Once cancelled, the order cannot be restored'),
            Text('• Refund will be processed according to payment method'),
            Text('• It may take 3-5 business days for the refund to reflect'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('KEEP ORDER'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('CANCEL ORDER'),
          ),
        ],
      ),
    );
  }

  // Cancel an order in Firebase
  void _cancelOrder(Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cancelling your order...'),
            ],
          ),
        ),
      ),
    );

    // Update status in Firebase
    if (_userId != null) {
      _database.child('users/$_userId/orders/${order.id}').update({
        'status': 'cancelled',
        'statusHistory/${DateTime.now().toString()}': 'cancelled',
      }).then((_) {
        // Also update in the store's orders if available
        if (order.storeId.isNotEmpty) {
          _database.child('stores/${order.storeId}/orders/${order.id}').update({
            'status': 'cancelled',
            'statusHistory/${DateTime.now().toString()}': 'cancelled',
            'cancelledBy': 'customer',
          });
        }

        // Close the loading dialog
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your order has been cancelled successfully'),
          ),
        );

        // Close order details if open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Refresh the order list
        _refreshData();
      }).catchError((error) {
        // Close the loading dialog
        Navigator.pop(context);

        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $error'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _isLoading
                  ? 'Loading orders...'
                  : '${filteredOrders.length} orders',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[200],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isLoading) ...[
            // Filter button
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: _selectedFilter != 'None'
                        ? Theme.of(context).colorScheme.secondary
                        : null,
                  ),
                  onPressed: () => _showFilterOptions(context),
                ),
                if (_selectedFilter != 'None')
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),

            // Refresh button
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
            ),
          ],
        ],
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading ? _buildShimmerEffect() : _buildOrdersList(),
    );
  }

  // Build shimmer loading effect
  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 6,
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  // Build orders list with proper grouping and UI
  Widget _buildOrdersList() {
    if (filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          final order = filteredOrders[index];
          final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                (index / filteredOrders.length) * 0.5,
                ((index + 1) / filteredOrders.length) * 0.5 + 0.5,
                curve: Curves.easeOut,
              ),
            ),
          );

          _animationController.forward();

          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildOrderCard(order),
            ),
          );
        },
      ),
    );
  }

  // Build order card with enhanced UI
  Widget _buildOrderCard(Order order) {
    // Get animation for status changes
    final animation = _statusAnimationControllers[order.id] ??
        AnimationController(
          duration: const Duration(milliseconds: 800),
          vsync: this,
        );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final isAnimating = animation.status == AnimationStatus.forward;
        final glowIntensity = isAnimating ? (0.0 + animation.value * 0.2) : 0.0;

        return Card(
          elevation: isAnimating ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isAnimating
                  ? _getStatusColor(order.status).withOpacity(0.5)
                  : Colors.grey[200]!,
              width: isAnimating ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showOrderDetails(order),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: isAnimating
                    ? [
                        BoxShadow(
                          color: _getStatusColor(order.status)
                              .withOpacity(glowIntensity),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ]
                    : [],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        order.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.fastfood, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Order details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order ID and status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  order.id,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(order.status)
                                      .withAlpha(25),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getStatusIcon(order.status),
                                      size: 12,
                                      color: _getStatusColor(order.status),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getStatusText(order.status),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _getStatusColor(order.status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Item name
                          Text(
                            order.itemName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Date and price
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(order.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '₹${(order.price * order.quantity).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Quantity indicator and live tracking
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withAlpha(25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Qty: ${order.quantity}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),

                              // Show live indicator if in progress
                              if (_isActiveStatus(order.status)) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(order.status)
                                        .withAlpha(25),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(order.status),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'LIVE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(order.status),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const Spacer(),
                              Text(
                                'View Details',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: Theme.of(context).primaryColor,
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
          ),
        );
      },
    );
  }

  // Build empty state screen
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Orders Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your order history will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
