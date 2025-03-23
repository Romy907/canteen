import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class Order {
  final String id;
  final String itemName;
  final double price;
  final String date;
  final int quantity;
  final String status;
  final String imageUrl;

  Order({
    required this.id,
    required this.itemName,
    required this.price,
    required this.date,
    required this.quantity,
    required this.status,
    required this.imageUrl,
  });
}

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late List<Order> orderHistory;
  late List<Order> filteredOrders;
  bool _isLoading = true;
  // ignore: unused_field
  bool _isRefreshing = false;
  String _selectedFilter = 'None';
  late AnimationController _animationController;
  late String _currentDate;
  late String _username;

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

    // Initialize animation controller for UI effects
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Get current date and username from provided info
    _currentDate = '2025-03-06 08:22:07';
    _username = 'navin280123';

    // Initialize with shimmer loading effect
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Load data with simulated network delay
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    // Create sample order history
    orderHistory = [
      Order(
        id: 'ORD-${_generateOrderId(0)}',
        itemName: 'Double Cheese Burger',
        price: 199.00,
        date: '2025-03-04 12:35:22',
        quantity: 2,
        status: 'Delivered',
        imageUrl: 'assets/images/burger.jpg',
      ),
      Order(
        id: 'ORD-${_generateOrderId(1)}',
        itemName: 'Margherita Pizza',
        price: 349.00,
        date: '2025-03-01 19:15:44',
        quantity: 1,
        status: 'Delivered',
        imageUrl: 'assets/images/pizza.jpg',
      ),
      Order(
        id: 'ORD-${_generateOrderId(2)}',
        itemName: 'Cold Coffee',
        price: 129.00,
        date: '2025-02-25 14:20:11',
        quantity: 3,
        status: 'Delivered',
        imageUrl: 'assets/images/coffee.jpg',
      ),
      Order(
        id: 'ORD-${_generateOrderId(3)}',
        itemName: 'Pasta Arrabiata',
        price: 249.00,
        date: '2025-02-20 20:05:38',
        quantity: 2,
        status: 'Delivered',
        imageUrl: 'assets/images/pasta.jpg',
      ),
      Order(
        id: 'ORD-${_generateOrderId(4)}',
        itemName: 'French Fries',
        price: 99.00,
        date: '2025-02-15 13:42:17',
        quantity: 2,
        status: 'Delivered',
        imageUrl: 'assets/images/fries.jpg',
      ),
    ];

    filteredOrders = List.from(orderHistory);

    // Update state to show loaded data
    setState(() {
      _isLoading = false;
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

  // Refresh data with new order
  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final newOrder = Order(
      id: 'ORD-${_generateOrderId(orderHistory.length)}',
      itemName: 'Chicken Biryani',
      price: 299.00,
      date: _currentDate,
      quantity: 1,
      status: 'Processing',
      imageUrl: 'assets/images/biryani.jpg',
    );

    setState(() {
      orderHistory.insert(0, newOrder);
      _applyFilter(_selectedFilter);
      _isRefreshing = false;
    });
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
          filteredOrders.sort((a, b) => a.status.compareTo(b.status));
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
                        
                        // Order status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.status).withAlpha(25),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(order.status),
                                size: 16,
                                color: _getStatusColor(order.status),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                order.status,
                                style: TextStyle(
                                  color: _getStatusColor(order.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Item details with responsive layout based on pre-determined screen width
                        screenWidth < 300 
                            ? _buildNarrowItemDetails(context, order)
                            : _buildWideItemDetails(context, order),
                        
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
                        
                        _buildSummaryRow('Item Price', '₹${order.price.toStringAsFixed(2)}'),
                        _buildSummaryRow('Quantity', '${order.quantity}'),
                        _buildSummaryRow('Item Total', '₹${(order.price * order.quantity).toStringAsFixed(2)}'),
                        _buildSummaryRow('Delivery Fee', '₹25.00'),
                        _buildSummaryRow('Taxes', '₹${((order.price * order.quantity) * 0.05).toStringAsFixed(2)}'),
                        
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
                              _buildInfoRow(Icons.access_time, 'Ordered on', _formatDate(order.date)),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.location_on, 'Delivery Address', 'Campus Canteen, Main Building'),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                  
                  // Bottom buttons - fixed at bottom, not inside the scrollable area
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: useVerticalLayout
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: const Text('Reorder'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
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
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.blue;
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
        return Icons.sync;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.info_outline;
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
      child: Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
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
        onPressed: _resetFilter,
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showOrderDetails(order),
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
                            color:
                                _getStatusColor(order.status).withAlpha(25),
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
                                order.status,
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

                    // Quantity indicator
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withAlpha(25),
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
