import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

class ManagerOrderList extends StatefulWidget {
  const ManagerOrderList({Key? key}) : super(key: key);
  
  @override
  _ManagerOrderListState createState() => _ManagerOrderListState();
}

class _ManagerOrderListState extends State<ManagerOrderList> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> pendingOrders = [
    {
      'id': 'ORD-001',
      'customer': 'John Doe',
      'items': [
        {'name': 'Pizza', 'quantity': 2, 'price': 'Rs. 145'},
        {'name': 'Coke', 'quantity': 1, 'price': 'Rs. 45'},
      ],
      'total': 'Rs. 290',
      'time': '10:15 AM',
      'status': 'Pending',
      'estimatedTime': '20-25 min',
      'paymentMethod': 'COD'
    },
    {
      'id': 'ORD-002',
      'customer': 'Jane Smith',
      'items': [
        {'name': 'Momos', 'quantity': 1, 'price': 'Rs. 80'},
        {'name': 'Fried Rice', 'quantity': 1, 'price': 'Rs. 50'},
      ],
      'total': 'Rs. 130',
      'time': '10:30 AM',
      'status': 'Pending',
      'estimatedTime': '15-20 min',
      'paymentMethod': 'UPI'
    },
    {
      'id': 'ORD-003',
      'customer': 'Mike Johnson',
      'items': [
        {'name': 'Ice Cream', 'quantity': 3, 'price': 'Rs. 40'},
      ],
      'total': 'Rs. 120',
      'time': '10:45 AM',
      'status': 'Pending',
      'estimatedTime': '5-10 min',
      'paymentMethod': 'Card'
    },
    {
      'id': 'ORD-004',
      'customer': 'Sarah Wilson',
      'items': [
        {'name': 'Momos', 'quantity': 2, 'price': 'Rs. 160'},
        {'name': 'Lassi', 'quantity': 2, 'price': 'Rs. 70'},
      ],
      'total': 'Rs. 300',
      'time': '11:00 AM',
      'status': 'Pending',
      'estimatedTime': '25-30 min',
      'paymentMethod': 'COD'
    },
    {
      'id': 'ORD-005',
      'customer': 'Alex Brown',
      'items': [
        {'name': 'Pizza', 'quantity': 1, 'price': 'Rs. 110'},
        {'name': 'Ice Cream', 'quantity': 1, 'price': 'Rs. 40'},
      ],
      'total': 'Rs. 150',
      'time': '11:15 AM',
      'status': 'Pending',
      'estimatedTime': '20-25 min',
      'paymentMethod': 'UPI'
    },
  ];
  
  List<Map<String, dynamic>> completedOrders = [
    {
      'id': 'ORD-101',
      'customer': 'Emily Davis',
      'items': [
        {'name': 'Pizza', 'quantity': 1, 'price': 'Rs. 100'},
        {'name': 'Coke', 'quantity': 1, 'price': 'Rs. 45'},
      ],
      'total': 'Rs. 145',
      'time': '09:15 AM',
      'status': 'Completed',
      'completedAt': '09:45 AM',
      'paymentMethod': 'Card'
    },
    {
      'id': 'ORD-102',
      'customer': 'Robert Miller',
      'items': [
        {'name': 'Fried Rice', 'quantity': 2, 'price': 'Rs. 100'},
        {'name': 'Lassi', 'quantity': 2, 'price': 'Rs. 90'},
      ],
      'total': 'Rs. 280',
      'time': '09:30 AM',
      'status': 'Completed',
      'completedAt': '10:00 AM',
      'paymentMethod': 'UPI'
    },
  ];

  // Lists for filtered results
  late List<Map<String, dynamic>> filteredPendingOrders;
  late List<Map<String, dynamic>> filteredCompletedOrders;
  
  // Filter options
  String? _selectedPaymentFilter;
  String? _selectedSortOption = 'Newest First';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    filteredPendingOrders = List.from(pendingOrders);
    filteredCompletedOrders = List.from(completedOrders);
    
    // Simulate loading time
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
    
    _tabController.addListener(() {
      // Close search when switching tabs
      if (_isSearching) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _filterOrders() {
    setState(() {
      // First filter by search query
      List<Map<String, dynamic>> tempPending = pendingOrders
          .where((order) =>
              order['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
              order['customer'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
              order['items'].any((item) =>
                  item['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())))
          .toList();

      List<Map<String, dynamic>> tempCompleted = completedOrders
          .where((order) =>
              order['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
              order['customer'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
              order['items'].any((item) =>
                  item['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())))
          .toList();
      
      // Then filter by payment method if selected
      if (_selectedPaymentFilter != null && _selectedPaymentFilter!.isNotEmpty) {
        tempPending = tempPending
            .where((order) => order['paymentMethod'] == _selectedPaymentFilter)
            .toList();
            
        tempCompleted = tempCompleted
            .where((order) => order['paymentMethod'] == _selectedPaymentFilter)
            .toList();
      }
      
      // Apply sorting
      if (_selectedSortOption == 'Highest Amount') {
        tempPending.sort((a, b) {
          String aTotal = a['total'].replaceAll('Rs. ', '');
          String bTotal = b['total'].replaceAll('Rs. ', '');
          return int.parse(bTotal).compareTo(int.parse(aTotal));
        });
        tempCompleted.sort((a, b) {
          String aTotal = a['total'].replaceAll('Rs. ', '');
          String bTotal = b['total'].replaceAll('Rs. ', '');
          return int.parse(bTotal).compareTo(int.parse(aTotal));
        });
      } else if (_selectedSortOption == 'Lowest Amount') {
        tempPending.sort((a, b) {
          String aTotal = a['total'].replaceAll('Rs. ', '');
          String bTotal = b['total'].replaceAll('Rs. ', '');
          return int.parse(aTotal).compareTo(int.parse(bTotal));
        });
        tempCompleted.sort((a, b) {
          String aTotal = a['total'].replaceAll('Rs. ', '');
          String bTotal = b['total'].replaceAll('Rs. ', '');
          return int.parse(aTotal).compareTo(int.parse(bTotal));
        });
      } else {
        // Default: Newest First - assuming the order IDs are sequential
        tempPending.sort((a, b) => b['id'].compareTo(a['id']));
        tempCompleted.sort((a, b) => b['id'].compareTo(a['id']));
      }
      
      filteredPendingOrders = tempPending;
      filteredCompletedOrders = tempCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrDesktop = screenWidth > 600;
    
    return DefaultTabController(
      length: 2,
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
            : Text('Order Management', style: TextStyle(fontWeight: FontWeight.bold)),
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
            unselectedLabelColor: Theme.of(context).brightness == Brightness.light
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
                    Text('Pending (${filteredPendingOrders.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: 8),
                    Text('Completed (${filteredCompletedOrders.length})'),
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
        _buildOrdersScreen(filteredPendingOrders, isPending: true, isTabletOrDesktop: isTabletOrDesktop),
        _buildOrdersScreen(filteredCompletedOrders, isPending: false, isTabletOrDesktop: isTabletOrDesktop),
      ],
    );
  }

  Widget _buildOrdersScreen(List<Map<String, dynamic>> orders, {required bool isPending, required bool isTabletOrDesktop}) {
    // Empty state
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.pending_actions : Icons.check_circle,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              isPending 
                ? _searchQuery.isNotEmpty || _selectedPaymentFilter != null
                    ? 'No matching pending orders' 
                    : 'No pending orders' 
                : _searchQuery.isNotEmpty || _selectedPaymentFilter != null
                    ? 'No matching completed orders' 
                    : 'No completed orders',
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
      child: _buildResponsiveOrdersList(orders, isPending, isTabletOrDesktop),
    );
  }

  Widget _buildResponsiveOrdersList(List<Map<String, dynamic>> orders, bool isPending, bool isTabletOrDesktop) {
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
          return _buildOrderCard(orders[index], index, isPending, isTabletOrDesktop)
            .animate()
            .fadeIn(duration: 500.ms, delay: (50 * index).ms)
            .slideY(begin: 0.1, end: 0, delay: (50 * index).ms, duration: 500.ms);
        },
      );
    }
    
    // For mobile: list layout
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index], index, isPending, isTabletOrDesktop)
          .animate()
          .fadeIn(duration: 500.ms, delay: (50 * index).ms)
          .slideY(begin: 0.1, end: 0, delay: (50 * index).ms, duration: 500.ms);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, int index, bool isPending, bool isTabletOrDesktop) {
    final statusColor = isPending ? Colors.orange : Colors.green;
    final paymentMethodIcon = _getPaymentMethodIcon(order['paymentMethod']);
    
    return Card(
      margin: EdgeInsets.only(bottom: isTabletOrDesktop ? 0 : 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPending ? Colors.orange.withAlpha(76) : Colors.green.withAlpha(76),
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
                isPending ? Icons.timer : Icons.check_circle,
                color: statusColor,
                size: 20,
              ),
            ),
          ),
          title: Text(
            'Order #${order['id']}',
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
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    order['customer'],
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    isPending ? 'Ordered at ${order['time']}' : 'Completed at ${order['completedAt']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  if (isPending)
                    Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        // child: Text(
                        //   'ETA: ${order['estimatedTime']}',
                        //   style: TextStyle(
                        //     fontSize: 10, 
                        //     color: Theme.of(context).colorScheme.primary,
                        //     fontWeight: FontWeight.bold,
                        //   ),
                        // ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                order['total'],
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
                  Divider(height: 24, thickness: 1, color: Colors.grey[200]),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        order['total'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).brightness == Brightness.light
                              ? Colors.green[700]
                              : Colors.green[300],
                        ),
                      ),
                    ],
                  ),
                  if (isPending) ...[
                    SizedBox(height: 24),
                    LayoutBuilder(
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
                                  label: Text('Reject', style: TextStyle(color: Colors.red)),
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
                                  label: Text('Reject', style: TextStyle(color: Colors.red)),
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
                    ),
                  ],
                  if (!isPending) ...[
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: Icon(Icons.print),
                          label: Text('Print Receipt'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onPressed: () {
                            _printReceipt(order);
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
              item['price'],
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
    setState(() {
      pendingOrders.remove(order);
      filteredPendingOrders.remove(order);
      order['status'] = 'Completed';
      order['completedAt'] = _getCurrentTime();
      completedOrders.add(order);
      filteredCompletedOrders = List.from(completedOrders);
      if (_searchQuery.isNotEmpty || _selectedPaymentFilter != null) {
        _filterOrders();
      }
    });
    
    _showNotification(
      message: 'Order ${order['id']} accepted successfully!',
      isSuccess: true,
    );
  }

  void _rejectOrder(Map<String, dynamic> order, String reason) {
    setState(() {
      pendingOrders.remove(order);
      filteredPendingOrders.remove(order);
      if (_searchQuery.isNotEmpty || _selectedPaymentFilter != null) {
        _filterOrders();
      }
    });

        _showNotification(
      message: 'Order ${order['id']} rejected: $reason',
      isSuccess: false,
    );
  }

  void _printReceipt(Map<String, dynamic> order) {
    _showNotification(
      message: 'Printing receipt for order ${order['id']}...',
      isSuccess: true,
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
        return Icon(Icons.account_balance_wallet, size: 14, color: Colors.purple[700]);
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
    final List<String> paymentMethods = ['All', 'Cash on Delivery', 'Card', 'UPI'];
    final List<String> sortOptions = ['Newest First', 'Highest Amount', 'Lowest Amount'];

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                        bool isSelected = _selectedPaymentFilter == (method == 'All' ? null : method);
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
                              _selectedPaymentFilter = selected && method != 'All' ? method : null;
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
                              _selectedSortOption = selected ? option : 'Newest First';
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
                          child: OutlinedButton(
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
          }
        );
      },
    );
}
  // void _showFilterOptions() {
  //   final List<String> paymentMethods = ['All', 'Cash on Delivery', 'Card', 'UPI'];
  //   final List<String> sortOptions = ['Newest First', 'Highest Amount', 'Lowest Amount'];
    
  //   showModalBottomSheet(
  //     context: context,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) {
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           return Container(
  //             padding: EdgeInsets.all(20),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     Text(
  //                       'Filter Orders',
  //                       style: TextStyle(
  //                         fontSize: 18,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                     IconButton(
  //                       icon: Icon(Icons.close),
  //                       onPressed: () => Navigator.pop(context),
  //                     ),
  //                   ],
  //                 ),
  //                 Divider(),
                  
  //                 // Payment Method Filter
  //                 Text(
  //                   'Payment Method',
  //                   style: TextStyle(
  //                     fontWeight: FontWeight.bold,
  //                     fontSize: 16,
  //                   ),
  //                 ),
  //                 SizedBox(height: 12),
  //                 Wrap(
  //                   spacing: 8,
  //                   children: paymentMethods.map((method) {
  //                     bool isSelected = _selectedPaymentFilter == (method == 'All' ? null : method);
  //                     return FilterChip(
  //                       label: Text(method),
  //                       selected: isSelected,
  //                       checkmarkColor: Colors.white,
  //                       selectedColor: Theme.of(context).colorScheme.primary,
  //                       labelStyle: TextStyle(
  //                         color: isSelected ? Colors.white : null,
  //                       ),
  //                       onSelected: (selected) {
  //                         setState(() {
  //                           _selectedPaymentFilter = selected && method != 'All' ? method : null;
  //                         });
  //                       },
  //                     );
  //                   }).toList(),
  //                 ),
                  
  //                 SizedBox(height: 20),
                  
  //                 // Sort Options
  //                 Text(
  //                   'Sort By',
  //                   style: TextStyle(
  //                     fontWeight: FontWeight.bold,
  //                     fontSize: 16,
  //                   ),
  //                 ),
  //                 SizedBox(height: 12),
  //                 Wrap(
  //                   spacing: 8,
  //                   children: sortOptions.map((option) {
  //                     bool isSelected = _selectedSortOption == option;
  //                     return FilterChip(
  //                       label: Text(option),
  //                       selected: isSelected,
  //                       checkmarkColor: Colors.white,
  //                       selectedColor: Theme.of(context).colorScheme.primary,
  //                       labelStyle: TextStyle(
  //                         color: isSelected ? Colors.white : null,
  //                       ),
  //                       onSelected: (selected) {
  //                         setState(() {
  //                           _selectedSortOption = selected ? option : 'Newest First';
  //                         });
  //                       },
  //                     );
  //                   }).toList(),
  //                 ),
                  
  //                 SizedBox(height: 24),
                  
  //                 Row(
  //                   children: [
  //                     Expanded(
  //                       child: OutlinedButton(
  //                         onPressed: () {
  //                           setState(() {
  //                             _selectedPaymentFilter = null;
  //                             _selectedSortOption = 'Newest First';
  //                           });
  //                         },
  //                         child: Text('Reset Filters'),
  //                         style: OutlinedButton.styleFrom(
  //                           padding: EdgeInsets.symmetric(vertical: 16),
  //                         ),
  //                       ),
  //                     ),
  //                     SizedBox(width: 12),
  //                     Expanded(
  //                       child: ElevatedButton(
  //                         onPressed: () {
  //                           Navigator.pop(context);
  //                           // Apply filters
  //                           this.setState(() {
  //                             _filterOrders();
  //                           });
  //                         },
  //                         child: Text('Apply Filters'),
  //                         style: ElevatedButton.styleFrom(
  //                           padding: EdgeInsets.symmetric(vertical: 16),
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           );
  //         }
  //       );
  //     },
  //   );
  // }

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
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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

 
}