import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class ManagerOrderList extends StatefulWidget {
  const ManagerOrderList({Key? key}) : super(key: key);

  @override
  _ManagerOrderListState createState() => _ManagerOrderListState();
}

class _ManagerOrderListState extends State<ManagerOrderList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseReference _ordersRef = FirebaseDatabase.instance.ref();
  // Add database listeners
  List<StreamSubscription<DatabaseEvent>> _dbListeners = [];
  // Order lists
  List<Map<String, dynamic>> pendingOrders = [];
  List<Map<String, dynamic>> onGoingOrders = [];
  List<Map<String, dynamic>> completedOrders = [];

  // Lists for filtered results
  late List<Map<String, dynamic>> filteredPendingOrders;
  late List<Map<String, dynamic>> filteredOnGoingOrders;
  late List<Map<String, dynamic>> filteredCompletedOrders;

  // Maps to store order timers and estimated delivery times
  Map<String, Timer> orderTimers = {};
  Map<String, DateTime> orderStartTimes = {};
  Map<String, Duration> orderEstimatedTimes = {};

  // Filter options
  String? _selectedPaymentFilter;
  String? _selectedSortOption = 'Newest First';
  String? id;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Set up filtered lists
    filteredPendingOrders = List.from(pendingOrders);
    filteredOnGoingOrders = List.from(onGoingOrders);
    filteredCompletedOrders = List.from(completedOrders);

    // Load ID first, which will trigger loading data
    _loadIdFromSharedPrefs();

    _tabController.addListener(() {
      // Close search when switching tabs
      if (_isSearching) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  void _loadIdFromSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      id = prefs.getString('createdAt');

      // Only load order data after id is available
      if (id != null) {
        _loadOrderData();
        _setupOrderListeners(); // Move this here to use the correct id
      } else {
        // Handle the case where id is not available
        _isLoading = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Store ID not found. Please login again.')),
        );
      }
    });
  }

  void _setupOrderListeners() {
    if (id == null) return; // Safety check

    // Cancel any existing listeners
    for (var listener in _dbListeners) {
      listener.cancel();
    }
    _dbListeners.clear();

    // Listen for changes to orders
    final orderListener =
        _ordersRef.child(id!).child('orders').onValue.listen((event) {
      if (event.snapshot.exists) {
        _updateOrdersFromSnapshot(event.snapshot);
      }
    });

    _dbListeners.add(orderListener);
  }

  void _updateOrdersFromSnapshot(DataSnapshot snapshot) {
    setState(() {
      // Clear current lists
      pendingOrders.clear();
      onGoingOrders.clear();
      completedOrders.clear();

      final ordersData = Map<String, dynamic>.from(snapshot.value as Map);

      // Process each order
      ordersData.forEach((key, value) {
        final orderData = Map<String, dynamic>.from(value);
        final status = orderData['status'] ?? 'pending';

        // Add to appropriate list based on status
        switch (status) {
          case 'pending':
            pendingOrders.add(orderData);
            break;
          case 'accepted':
            onGoingOrders.add(orderData);
            break;
          case 'confirmed': // Handle this status as ongoing too
            onGoingOrders.add(orderData);
            break;
          case 'completed':
            completedOrders.add(orderData);
            break;
        }
      });

      // Update filtered lists
      filteredPendingOrders = List.from(pendingOrders);
      filteredOnGoingOrders = List.from(onGoingOrders);
      filteredCompletedOrders = List.from(completedOrders);
      print(filteredPendingOrders.length);
      print(filteredPendingOrders.toString());  
    // Apply filters if any
      if (_searchQuery.isNotEmpty || _selectedPaymentFilter != null) {
        _filterOrders();
      }

      _isLoading = false;
    });
  }

  void _loadOrderData() {
    if (id == null) return; // Safety check

    setState(() {
      _isLoading = true;
    });
  print(id);
    // Get orders from Firebase
    _ordersRef.child(id!).child('orders').get().then((snapshot) {
      if (snapshot.exists) {
        _updateOrdersFromSnapshot(snapshot);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }).catchError((error) {
      print('Error loading orders: $error');
      setState(() {
        _isLoading = false;
      });
    });
  }

  String _formatTimestamp(String timestamp) {
    // Format timestamp to readable time
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      String formattedTime = DateFormat('hh:mm a').format(dateTime);
      return formattedTime;
    } catch (e) {
      return timestamp;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();

    // Cancel all active timers
    orderTimers.forEach((key, timer) {
      timer.cancel();
    });

    // Cancel Firebase listeners
    for (var listener in _dbListeners) {
      listener.cancel();
    }

    super.dispose();
  }

  void _filterOrders() {
    setState(() {
      // First filter by search query
      filteredPendingOrders = _filterOrdersByQuery(pendingOrders);
      filteredOnGoingOrders = _filterOrdersByQuery(onGoingOrders);
      filteredCompletedOrders = _filterOrdersByQuery(completedOrders);

      // Then filter by payment method if selected
      if (_selectedPaymentFilter != null &&
          _selectedPaymentFilter!.isNotEmpty) {
        filteredPendingOrders = _filterOrdersByPayment(filteredPendingOrders);
        filteredOnGoingOrders = _filterOrdersByPayment(filteredOnGoingOrders);
        filteredCompletedOrders =
            _filterOrdersByPayment(filteredCompletedOrders);
      }

      // Apply sorting
      _applySorting();
    });
  }

  List<Map<String, dynamic>> _filterOrdersByQuery(
      List<Map<String, dynamic>> orders) {
    return orders
        .where((order) =>
            order['id']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            order['customer']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            order['items'].any((item) => item['name']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase())))
        .toList();
  }

  List<Map<String, dynamic>> _filterOrdersByPayment(
      List<Map<String, dynamic>> orders) {
    return orders
        .where((order) => order['paymentMethod'] == _selectedPaymentFilter)
        .toList();
  }

  void _applySorting() {
    if (_selectedSortOption == 'Highest Amount') {
      _sortOrdersByAmount(filteredPendingOrders, isAscending: false);
      _sortOrdersByAmount(filteredOnGoingOrders, isAscending: false);
      _sortOrdersByAmount(filteredCompletedOrders, isAscending: false);
    } else if (_selectedSortOption == 'Lowest Amount') {
      _sortOrdersByAmount(filteredPendingOrders, isAscending: true);
      _sortOrdersByAmount(filteredOnGoingOrders, isAscending: true);
      _sortOrdersByAmount(filteredCompletedOrders, isAscending: true);
    } else {
      // Default: Newest First - assuming the order IDs are sequential
      filteredPendingOrders.sort((a, b) => b['id'].compareTo(a['id']));
      filteredOnGoingOrders.sort((a, b) => b['id'].compareTo(a['id']));
      filteredCompletedOrders.sort((a, b) => b['id'].compareTo(a['id']));
    }
  }

  void _sortOrdersByAmount(List<Map<String, dynamic>> orders,
      {required bool isAscending}) {
    orders.sort((a, b) {
      String aTotal = a['total'].replaceAll('Rs. ', '');
      String bTotal = b['total'].replaceAll('Rs. ', '');
      double aValue = double.tryParse(aTotal) ?? 0;
      double bValue = double.tryParse(bTotal) ?? 0;
      return isAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrDesktop = screenWidth > 600;

    return DefaultTabController(
      length: 3, // Changed to 3 tabs
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.grey[50]
            : Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          toolbarHeight: _isSearching ? kToolbarHeight + 8 : kToolbarHeight,
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search orders...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                          filteredPendingOrders = List.from(pendingOrders);
                          filteredOnGoingOrders = List.from(onGoingOrders);
                          filteredCompletedOrders = List.from(completedOrders);
                          _isSearching = false;
                        });
                      },
                    ),
                  ),
                  style: TextStyle(fontSize: 16),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _filterOrders();
                    });
                  },
                )
              : Text('Order Management',
                  style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            if (!_isSearching)
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
            IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: _showFilterOptions,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).brightness == Brightness.light
                ? Colors.black
                : Colors.white,
            unselectedLabelColor:
                Theme.of(context).brightness == Brightness.light
                    ? Colors.black54
                    : Colors.white70,
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pending_actions),
                    SizedBox(width: 8),
                    // Text('Pending (${filteredPendingOrders.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delivery_dining),
                    SizedBox(width: 8),
                    // Text('On Going (${filteredOnGoingOrders.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: 8),
                    // Text('Completed (${filteredCompletedOrders.length})'),
                  ],
                ),
              ),
            ],
          ),
          elevation: 0,
        ),
        body: _isLoading
            ? _buildLoadingIndicator()
            : _buildTabBarView(isTabletOrDesktop),
      ),
    );
  }

  Widget _buildTabBarView(bool isTabletOrDesktop) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOrdersScreen(
            filteredPendingOrders, OrderStatus.pending, isTabletOrDesktop),
        _buildOrdersScreen(
            filteredOnGoingOrders, OrderStatus.ongoing, isTabletOrDesktop),
        _buildOrdersScreen(
            filteredCompletedOrders, OrderStatus.completed, isTabletOrDesktop),
      ],
    );
  }

  Widget _buildOrdersScreen(List<Map<String, dynamic>> orders,
      OrderStatus status, bool isTabletOrDesktop) {
    // Empty state
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStatusIcon(status),
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              _getEmptyStateText(status),
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty || _selectedPaymentFilter != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _selectedPaymentFilter = null;
                    filteredPendingOrders = List.from(pendingOrders);
                    filteredOnGoingOrders = List.from(onGoingOrders);
                    filteredCompletedOrders = List.from(completedOrders);
                  });
                },
                child: Text('Clear filters'),
              ),
          ],
        ).animate().fadeIn(duration: 600.ms),
      );
    }

    // Content state
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          // Refresh data - in real app would fetch from API
        });
      },
      child: _buildResponsiveOrdersList(orders, status, isTabletOrDesktop),
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.pending_actions;
      case OrderStatus.ongoing:
        return Icons.delivery_dining;
      case OrderStatus.completed:
        return Icons.check_circle;
    }
  }

  String _getEmptyStateText(OrderStatus status) {
    final filterText = _searchQuery.isNotEmpty || _selectedPaymentFilter != null
        ? 'matching '
        : '';

    switch (status) {
      case OrderStatus.pending:
        return 'No ${filterText}pending orders';
      case OrderStatus.ongoing:
        return 'No ${filterText}ongoing orders';
      case OrderStatus.completed:
        return 'No ${filterText}completed orders';
    }
  }

  Widget _buildResponsiveOrdersList(List<Map<String, dynamic>> orders,
      OrderStatus status, bool isTabletOrDesktop) {
    // For tablet and desktop: grid layout
    if (isTabletOrDesktop) {
      return GridView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(
                  orders[index], index, status, isTabletOrDesktop)
              .animate()
              .fadeIn(duration: 500.ms, delay: (50 * index).ms)
              .slideY(
                  begin: 0.1, end: 0, delay: (50 * index).ms, duration: 500.ms);
        },
      );
    }

    // For mobile: list layout
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index], index, status, isTabletOrDesktop)
            .animate()
            .fadeIn(duration: 500.ms, delay: (50 * index).ms)
            .slideY(
                begin: 0.1, end: 0, delay: (50 * index).ms, duration: 500.ms);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, int index,
      OrderStatus status, bool isTabletOrDesktop) {
    final statusColor = _getStatusColor(status);
    final paymentMethodIcon = _getPaymentMethodIcon(order['paymentMethod']);

    return Card(
      margin: EdgeInsets.only(bottom: isTabletOrDesktop ? 0 : 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withAlpha(76),
          width: 1.0,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          colorScheme: Theme.of(context).colorScheme.copyWith(
                surface: Theme.of(context).cardColor,
              ),
        ),
        child: ExpansionTile(
          childrenPadding: EdgeInsets.zero,
          tilePadding: EdgeInsets.all(16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _getStatusIcon(status),
                color: statusColor,
                size: 20,
              ),
            ),
          ),
          title: Text(
            '${order['orderId']}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order['userId'],
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _getTimeText(order, status),
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (status == OrderStatus.ongoing) ...[
                    SizedBox(width: 8),
                    Flexible(
                      child: _buildDeliveryTimer(order),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                order['totalAmount'].toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  paymentMethodIcon,
                  SizedBox(width: 4),
                  Text(
                    order['paymentMethod'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  ..._buildOrderItems(order['items']),

                  if (order['notes'] != null &&
                      order['notes'].toString().isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'Customer Notes:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order['notes'],
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],

                  Divider(height: 24, thickness: 1, color: Colors.grey[200]),

                  // Payment summary
                  Column(
                    children: [
                      _buildPaymentDetail('Subtotal', order['subtotal'].toString()),
                      if (order['discount'] != null)
                        _buildPaymentDetail(
                            'Discount', '- ${order['discount']}'),
                      _buildPaymentDetail('Tax', order['tax'].toString()),
                      if (order['platformCharge'] != null)
                        _buildPaymentDetail(
                            'Platform Charge', order['platformCharge'].toString()),
                      Divider(height: 16, thickness: 1),
                      _buildPaymentDetail('Total Amount', order['totalAmount'].toString(),
                          isBold: true),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Action buttons
                  _buildActionButtons(order, status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryTimer(Map<String, dynamic> order) {
    final String orderId = order['orderId'];

    // If no timer is running for this order, start one
    if (!orderTimers.containsKey(orderId)) {
      // Record the start time if not already set
      orderStartTimes[orderId] = orderStartTimes[orderId] ?? DateTime.now();

      // Parse the estimated delivery time (e.g., "20-30 mins")
      if (order['estimatedTime'] != null) {
        final String estTime = order['estimatedTime'];
        final RegExp regex = RegExp(r'(\d+)(?:-(\d+))?\s*mins?');
        final match = regex.firstMatch(estTime);

        if (match != null) {
          int minTime = int.parse(match.group(1)!);
          int maxTime =
              match.group(2) != null ? int.parse(match.group(2)!) : minTime;

          // Use average for display
          int avgTime = (minTime + maxTime) ~/ 2;
          orderEstimatedTimes[orderId] = Duration(minutes: avgTime);
        }
      } else {
        // Default to 30 minutes if no estimate is provided
        orderEstimatedTimes[orderId] = Duration(minutes: 30);
      }

      // Start the timer to update the UI every second
      orderTimers[orderId] = Timer.periodic(Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }

    // Calculate elapsed time
    final Duration elapsed =
        DateTime.now().difference(orderStartTimes[orderId]!);
    final Duration estimated = orderEstimatedTimes[orderId]!;

    // Calculate progress (0.0 to 1.0)
    final double progress = elapsed.inSeconds / estimated.inSeconds;
    final bool isOverdue = progress > 1.0;

    // Format the remaining/overdue time
    String timeText;
    Color timeColor;

    if (isOverdue) {
      final Duration overdue = elapsed - estimated;
      timeText = '+${_formatDuration(overdue)} over';
      timeColor = Colors.red;
    } else {
      final Duration remaining = estimated - elapsed;
      timeText = '${_formatDuration(remaining)} left';
      timeColor = progress > 0.8 ? Colors.orange : Colors.green;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: timeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: timeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.timer_off : Icons.timer,
            size: 10,
            color: timeColor,
          ),
          SizedBox(width: 4),
          Text(
            timeText,
            style: TextStyle(
              fontSize: 10,
              color: timeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    int minutes = duration.inMinutes;
    int seconds = (duration.inSeconds % 60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Row _buildPaymentDetail(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> order, OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return LayoutBuilder(
          builder: (context, constraints) {
            // Responsive buttons - stack them if narrow
            if (constraints.maxWidth < 400) {
              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.check),
                      label: Text('Accept Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        _acceptOrder(order);
                      },
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.close, color: Colors.red),
                      label:
                          Text('Reject', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        _showRejectDialog(order);
                      },
                    ),
                  ),
                ],
              );
            } else {
              // Side by side for wider screens
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.check),
                      label: Text('Accept Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        _acceptOrder(order);
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.close, color: Colors.red),
                      label:
                          Text('Reject', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        _showRejectDialog(order);
                      },
                    ),
                  ),
                ],
              );
            }
          },
        );

      case OrderStatus.ongoing:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: Icon(Icons.check_circle),
            label: Text('Complete Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              _showOtpVerificationDialog(order);
            },
          ),
        );

      case OrderStatus.completed:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              icon: Icon(Icons.print),
              label: Text('Print Receipt'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // _printReceipt(order);
              },
            ),
            SizedBox(width: 12),
            OutlinedButton.icon(
              icon: Icon(Icons.history),
              label: Text('Order History'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Show order history/timeline
                _showOrderHistory(order);
              },
            ),
          ],
        );
    }
  }

  List<Widget> _buildOrderItems(List<dynamic> items) {
    return items.map<Widget>((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(51),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        'x${item['quantity']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Text(
              item['price'].toString(),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _getTimeText(Map<String, dynamic> order, OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Ordered at ${order['time']}';
      case OrderStatus.ongoing:
        return 'Accepted at ${order['acceptedAt'] ?? _getCurrentTime()}';
      case OrderStatus.completed:
        return 'Completed at ${order['completedAt'] ?? _getCurrentTime()}';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.ongoing:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
    }
  }

  Widget _buildLoadingIndicator() {
    // Check if we should display a grid for larger screens
    bool isTabletOrDesktop = MediaQuery.of(context).size.width > 600;

    if (isTabletOrDesktop) {
      // Grid layout for tablet/desktop
      return GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      );
    }

    // List layout for mobile
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  void _acceptOrder(Map<String, dynamic> order) {
    final String orderId = order['orderId'] ?? order['id'];
    final String storeId = order['storeId'];

    // Update Firebase with new status
    _ordersRef.child(storeId).child('orders').child(orderId).update({
      'status': 'accepted',
      'acceptedAt': _getCurrentTime(),
      'acceptedBy': 'navin280123', // Using current user's login
      'acceptedDate': DateTime.now().toString()
    }).then((_) {
      // Success handling - UI will update via the listener
      _showNotification(
        message: 'Order $orderId accepted and moved to On Going!',
        isSuccess: true,
      );

      // Switch to ongoing tab
      _tabController.animateTo(1); // Index 1 is the "On Going" tab

      // Start the delivery timer
      _startDeliveryTimer(order);
    }).catchError((error) {
      print('Error accepting order: $error');
      _showNotification(
        message: 'Failed to accept order: $error',
        isSuccess: false,
      );
    });
  }

  void _startDeliveryTimer(Map<String, dynamic> order) {
    final String orderId = order['orderId'];
    orderStartTimes[orderId] = DateTime.now();

    // Parse the estimated delivery time
    if (order['estimatedTime'] != null) {
      final String estTime = order['estimatedTime'];
      final RegExp regex = RegExp(r'(\d+)(?:-(\d+))?\s*mins?');
      final match = regex.firstMatch(estTime);

      if (match != null) {
        int minTime = int.parse(match.group(1)!);
        int maxTime =
            match.group(2) != null ? int.parse(match.group(2)!) : minTime;

        // Use average
        int avgTime = (minTime + maxTime) ~/ 2;
        orderEstimatedTimes[orderId] = Duration(minutes: avgTime);
      } else {
        orderEstimatedTimes[orderId] = Duration(minutes: 30); // Default
      }
    } else {
      orderEstimatedTimes[orderId] = Duration(minutes: 30); // Default
    }

    // Start timer to update UI
    orderTimers[orderId] = Timer.periodic(Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _completeOrder(Map<String, dynamic> order) {
    final String orderId = order['orderId'] ?? order['id'];
    final String storeId = order['storeId'];

    // Cancel the timer if it exists
    if (orderTimers.containsKey(orderId)) {
      orderTimers[orderId]!.cancel();
      orderTimers.remove(orderId);
    }

    // Update Firebase with new status
    _ordersRef.child(storeId).child('orders').child(orderId).update({
      'status': 'completed',
      'completedAt': _getCurrentTime(),
      'completedBy': 'navin280123', // Current user
      'completedDate': DateTime.now().toString()
    }).then((_) {
      // Success handling - UI will update via the listener
      _showNotification(
        message: 'Order $orderId completed successfully!',
        isSuccess: true,
      );

      // Switch to completed tab
      _tabController.animateTo(2); // Index 2 is the "Completed" tab
    }).catchError((error) {
      print('Error completing order: $error');
      _showNotification(
        message: 'Failed to complete order: $error',
        isSuccess: false,
      );
    });
  }

  void _rejectOrder(Map<String, dynamic> order, String reason) {
    final String orderId = order['orderId'] ?? order['id'];
    final String storeId = order['storeId'];

    // Update Firebase with rejected status
    _ordersRef.child(storeId).child('orders').child(orderId).update({
      'status': 'rejected',
      'rejectedAt': _getCurrentTime(),
      'rejectedBy': 'navin280123', // Current user
      'rejectReason': reason
    }).then((_) {
      // Success handling - UI will update via the listener
      _showNotification(
        message: 'Order $orderId rejected: $reason',
        isSuccess: false,
      );
    }).catchError((error) {
      print('Error rejecting order: $error');
      _showNotification(
        message: 'Failed to reject order: $error',
        isSuccess: false,
      );
    });
  }

  void _showOrderHistory(Map<String, dynamic> order) {
    // This would show a detailed history/timeline of the order
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order History'),
        content: Container(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildTimelineItem('Order Placed', 'Customer placed the order',
                  order['time'], Icons.shopping_cart, Colors.blue),
              if (order['acceptedAt'] != null)
                _buildTimelineItem(
                    'Order Accepted',
                    'Accepted by ${order['acceptedBy'] ?? 'staff'}',
                    order['acceptedAt'],
                    Icons.thumb_up,
                    Colors.green),
              if (order['completedAt'] != null)
                _buildTimelineItem(
                    'Order Completed',
                    'Completed and delivered to customer',
                    order['completedAt'],
                    Icons.check_circle,
                    Colors.purple),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
      String title, String subtitle, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
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
                SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${now.minute.toString().padLeft(2, '0')} $amPm';
  }

  Widget _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash on delivery':
        return Icon(Icons.money, size: 14, color: Colors.green[700]);
      case 'card':
        return Icon(Icons.credit_card, size: 14, color: Colors.blue[700]);
      case 'upi':
        return Icon(Icons.account_balance_wallet,
            size: 14, color: Colors.purple[700]);
      default:
        return Icon(Icons.payment, size: 14, color: Colors.grey[700]);
    }
  }

  void _showNotification({required String message, required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showFilterOptions() {
    final List<String> paymentMethods = [
      'All',
      'Cash on Delivery',
      'Card',
      'UPI'
    ];
    final List<String> sortOptions = [
      'Newest First',
      'Highest Amount',
      'Lowest Amount'
    ];

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Container(
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(),

                  // Payment Method Filter
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: paymentMethods.map((method) {
                      bool isSelected = _selectedPaymentFilter ==
                          (method == 'All' ? null : method);
                      return FilterChip(
                        label: Text(method),
                        selected: isSelected,
                        checkmarkColor: Colors.white,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedPaymentFilter =
                                selected && method != 'All' ? method : null;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 20),

                  // Sort Options
                  Text(
                    'Sort By',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: sortOptions.map((option) {
                      bool isSelected = _selectedSortOption == option;
                      return FilterChip(
                        label: Text(option),
                        selected: isSelected,
                        checkmarkColor: Colors.white,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedSortOption =
                                selected ? option : 'Newest First';
                          });
                        },
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedPaymentFilter = null;
                              _selectedSortOption = 'Newest First';
                            });
                          },
                          child: Text('Reset Filters'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Apply filters
                            this.setState(() {
                              _filterOrders();
                            });
                          },
                          child: Text('Apply Filters'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showRejectDialog(Map<String, dynamic> order) {
    String rejectReason = 'Out of stock';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reject Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please select a reason:'),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: rejectReason,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                items: [
                  'Out of stock',
                  'Restaurant too busy',
                  'Kitchen closed',
                  'Other reason'
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  rejectReason = value!;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _rejectOrder(order, rejectReason);
              },
              child: Text('REJECT ORDER'),
            ),
          ],
        );
      },
    );
  }

  void _showOtpVerificationDialog(Map<String, dynamic> order) {
    // Create controller inside the method, but don't dispose it in the .then() callback
    final TextEditingController otpController = TextEditingController();
    bool isVerifying = false;
    String errorMessage = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Verify Delivery'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Please ask the customer for the OTP sent to their phone to complete the delivery.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'Enter OTP',
                      border: OutlineInputBorder(),
                      counterText: '',
                      errorText: errorMessage.isNotEmpty ? errorMessage : null,
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  SizedBox(height: 16),
                  if (isVerifying)
                    Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          // Validate OTP input
                          if (otpController.text.length < 4) {
                            setState(() {
                              errorMessage = 'Please enter a valid OTP';
                            });
                            return;
                          }

                          setState(() {
                            isVerifying = true;
                            errorMessage = '';
                          });

                          // Simulate OTP verification
                          await Future.delayed(Duration(seconds: 2));
                          if (otpController.text.length == 6) {
                            Navigator.pop(context);
                            _completeOrder(order);
                          } else {
                            setState(() {
                              isVerifying = false;
                              errorMessage = 'Invalid OTP. Please try again.';
                            });
                          }
                        },
                  child: Text('VERIFY & COMPLETE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Enum to represent order status
enum OrderStatus { pending, ongoing, completed }
