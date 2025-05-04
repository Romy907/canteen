import 'package:canteen/Manager/ManagerManageMenu.dart';
import 'package:canteen/Manager/ManagerPaymentMethods.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagerHome extends StatefulWidget {
  const ManagerHome({Key? key}) : super(key: key);

  @override
  _ManagerHomeState createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome>
    with SingleTickerProviderStateMixin {
  // Animation controller
  late AnimationController _animationController;
  bool _isLoading = true;
  String _storeId = '';

  // Date range selection
  String _selectedTimeRange = 'Today';
  final List<String> _timeRanges = [
    'Today',
    'Yesterday',
    'This Week',
    'This Month',
    'All Time'  // Added "All Time" option
  ];

  // Real-time statistics
  Map<String, dynamic> statistics = {
    'Total Orders': 0,
    'Completed': 0,
    'Pending': 0,
    'Revenue': 0.0
  };

  // Trend data (percentage change)
  Map<String, double> trends = {
    'Total Orders': 0.0,
    'Completed': 0.0,
    'Pending': 0.0,
    'Revenue': 0.0
  };

  // Chart data
  List<FlSpot> revenueSpots = [];
  List<FlSpot> ordersSpots = [];

  // Popular items based on real data
  List<Map<String, dynamic>> popularItems = [];

  final List<String> categories = [
    'All',
    'Appetizers',
    'Main Course',
    'Fast Food',
    'Desserts',
    'Beverages'
  ];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _loadStoreIdAndData();
  }

  Future<void> _loadStoreIdAndData() async {
    try {
      // Get storeId from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storeId = prefs.getString('createdAt');
      
      if (storeId != null) {
        setState(() {
          _storeId = storeId;
        });
        
        // Load data based on selected time range
        await _loadDataForTimeRange(_selectedTimeRange);
      } else {
        print('StoreId not found in SharedPreferences');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading storeId: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDataForTimeRange(String timeRange) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate date ranges based on selected time range
      DateTime now = DateTime.now();
      DateTime startDate;
      
      switch (timeRange) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'Yesterday':
          startDate = DateTime(now.year, now.month, now.day - 1);
          break;
        case 'This Week':
          // Start from last 7 days
          startDate = DateTime(now.year, now.month, now.day - 6);
          break;
        case 'This Month':
          // Start from beginning of current month
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'All Time':
          // Use a very early date to get all orders
          startDate = DateTime(2000, 1, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
      }

      // Load orders from Firebase Realtime Database
      await _fetchAndProcessOrders(startDate, now);
      
      // Only after data is processed, set loading to false
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAndProcessOrders(DateTime startDate, DateTime endDate) async {
    try {
      // Reference to the orders node for this store
      final databaseRef = FirebaseDatabase.instance
          .ref()
          .child(_storeId)
          .child('orders');
      
      // Get data from Firebase
      final snapshot = await databaseRef.get();
      
      if (snapshot.exists) {
        final Map<dynamic, dynamic> ordersData = snapshot.value as Map<dynamic, dynamic>;
        
        // Process orders data
        _processOrdersData(ordersData, startDate, endDate);
      } else {
        print('No orders data available');
        _resetStatistics();
      }
    } catch (e) {
      print('Error fetching orders: $e');
      _resetStatistics();
    }
  }

  void _resetStatistics() {
    setState(() {
      statistics = {
        'Total Orders': 0,
        'Completed': 0,
        'Pending': 0,
        'Revenue': 0.0
      };
      
      trends = {
        'Total Orders': 0.0,
        'Completed': 0.0,
        'Pending': 0.0,
        'Revenue': 0.0
      };
      
      revenueSpots = [];
      ordersSpots = [];
      popularItems = [];
    });
  }

  void _processOrdersData(Map<dynamic, dynamic> ordersData, DateTime startDate, DateTime endDate) {
    // Counters for statistics
    int totalOrders = 0;
    int completedOrders = 0;
    int pendingOrders = 0;
    double totalRevenue = 0.0;
    
    // Map to track popular items
    Map<String, Map<String, dynamic>> itemsMap = {};
    
    // Maps for tracking time-based data for charts
    Map<String, double> periodRevenue = {};
    Map<String, int> periodOrders = {};
    
    // For aggregating data points over time (especially useful for All Time view)
    bool isAllTime = _selectedTimeRange == 'All Time';
    bool isMonthView = _selectedTimeRange == 'This Month';
    
    // Define the number of data points we want in our chart
    final int maxDataPoints = 7;
    
    // Calculate the time interval for grouping data
    final totalMillis = endDate.difference(startDate).inMilliseconds;
    final intervalMillis = totalMillis ~/ maxDataPoints;
    
    // Initialize period maps
    for (int i = 0; i < maxDataPoints; i++) {
      String periodKey = i.toString();
      periodRevenue[periodKey] = 0.0;
      periodOrders[periodKey] = 0;
    }
    
    // Process each order
    ordersData.forEach((key, value) {
      try {
        final orderData = value as Map<dynamic, dynamic>;
        final orderTimestamp = orderData['timestamp'] as String?;
        
        if (orderTimestamp != null) {
          final orderDate = DateTime.parse(orderTimestamp);
          
          // Only process orders within the selected date range
          if (orderDate.isAfter(startDate.subtract(Duration(minutes: 1))) && 
              orderDate.isBefore(endDate.add(Duration(minutes: 1)))) {
            
            // Increment total orders count
            totalOrders++;
            
            // Check order status
            final status = orderData['status'] as String?;
            if (status == 'completed') {
              completedOrders++;
            } else if (status == 'pending' || status == 'accepted' || status == 'ready') {
              pendingOrders++;
            }
            
            // Add to revenue if amount is present
            final totalAmount = orderData['totalAmount'];
            if (totalAmount != null) {
              final double orderAmount = (totalAmount is double) 
                  ? totalAmount 
                  : double.tryParse(totalAmount.toString()) ?? 0.0;
              totalRevenue += orderAmount;
              
              // Determine which period bucket this order belongs to
              int periodIndex;
              
              if (isAllTime || isMonthView) {
                // For All Time or Month view, divide the total time range into equal periods
                periodIndex = orderDate.difference(startDate).inMilliseconds ~/ intervalMillis;
                if (periodIndex >= maxDataPoints) periodIndex = maxDataPoints - 1;
              } else {
                // For day/week view, use day index
                periodIndex = orderDate.difference(startDate).inDays;
                if (periodIndex >= maxDataPoints) periodIndex = maxDataPoints - 1;
              }
              
              String periodKey = periodIndex.toString();
              
              // Add to period metrics
              periodRevenue[periodKey] = (periodRevenue[periodKey] ?? 0.0) + orderAmount;
              periodOrders[periodKey] = (periodOrders[periodKey] ?? 0) + 1;
            }
            
            // Process items for popular items tracking
            final items = orderData['items'];
            if (items != null && items is List) {
              for (var item in items) {
                if (item is Map) {
                  final name = item['name'] as String?;
                  final price = item['price'];
                  final quantity = item['quantity'] ?? 1;
                  
                  if (name != null && price != null) {
                    final double itemPrice = (price is double) 
                        ? price 
                        : double.tryParse(price.toString()) ?? 0.0;
                    
                    // Calculate total price considering quantity
                    final double totalItemPrice = itemPrice * (quantity is int ? quantity : 1);
                    
                    // If item exists, update its stats, otherwise create new entry
                    if (itemsMap.containsKey(name)) {
                      itemsMap[name]!['sold'] = (itemsMap[name]!['sold'] as int) + (quantity is int ? quantity : 1);
                      itemsMap[name]!['revenue'] = (itemsMap[name]!['revenue'] as double) + totalItemPrice;
                    } else {
                      itemsMap[name] = {
                        'name': name,
                        'sold': quantity is int ? quantity : 1,
                        'revenue': totalItemPrice,
                        'category': item['category'] ?? 'Unknown',
                        'image': item['image'] ?? 'assets/img/placeholder.jpeg',
                        'trend': 0.0 // Will calculate later
                      };
                    }
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        print('Error processing order $key: $e');
      }
    });
    
    // Calculate trends (simplified: use 10% as a placeholder)
    final lastWeekTrend = 0.1; // 10% growth from last week
    
    // Convert period maps to FlSpot lists for charts
    List<FlSpot> revSpots = [];
    List<FlSpot> ordSpots = [];
    
    periodRevenue.entries.forEach((entry) {
      int index = int.parse(entry.key);
      revSpots.add(FlSpot(index.toDouble(), entry.value));
    });
    
    periodOrders.entries.forEach((entry) {
      int index = int.parse(entry.key);
      ordSpots.add(FlSpot(index.toDouble(), entry.value.toDouble()));
    });
    
    // Sort spots by x value
    revSpots.sort((a, b) => a.x.compareTo(b.x));
    ordSpots.sort((a, b) => a.x.compareTo(b.x));
    
    // Create list of popular items sorted by sold count
    final List<Map<String, dynamic>> sortedItems = itemsMap.values.toList()
      ..sort((a, b) => (b['sold'] as int).compareTo(a['sold'] as int));
    
    // Get top 5 (or fewer if less available)
    final topItems = sortedItems.take(5).toList();
    
    // Calculate trends for popular items (simulate trends based on item popularity)
    for (var item in topItems) {
      // Generate a trend between -15% and +25% based on item's position in the list
      final index = topItems.indexOf(item);
      final trendBase = 25.0 - (index * 8.0); // Higher for more popular items
      final trendVariation = (DateTime.now().millisecond % 10) - 5.0; // Random variation
      item['trend'] = trendBase + trendVariation;
    }
    
    // Update state
    setState(() {
      statistics = {
        'Total Orders': totalOrders,
        'Completed': completedOrders,
        'Pending': pendingOrders,
        'Revenue': totalRevenue
      };
      
      trends = {
        'Total Orders': totalOrders > 0 ? lastWeekTrend * 100 : 0.0,
        'Completed': completedOrders > 0 ? lastWeekTrend * 100 * 1.2 : 0.0,
        'Pending': pendingOrders > 0 ? -lastWeekTrend * 100 * 0.5 : 0.0,
        'Revenue': totalRevenue > 0 ? lastWeekTrend * 100 * 1.5 : 0.0
      };
      
      revenueSpots = revSpots;
      ordersSpots = ordSpots;
      popularItems = topItems;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Method to safely update state for category changes
  void _updateCategory(String category) {
    if (_selectedCategory != category) {
      setState(() {
        _selectedCategory = category;
        _isLoading = true;
      });

      // Filter items by category
      _filterItemsByCategory(category);
    }
  }

  void _filterItemsByCategory(String category) {
    // Simulate data loading for category change
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // Method to safely handle time range changes
  void _updateTimeRange(String? value) {
    if (value != null && _selectedTimeRange != value) {
      setState(() {
        _selectedTimeRange = value;
      });

      // Load new data for selected time range
      _loadDataForTimeRange(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range Selector
                  _buildDateSelector(),
                  const SizedBox(height: 20),

                  // Quick statistics
                  _isLoading
                      ? _buildStatisticsShimmer()
                      : _buildStatisticsCards(),
                  const SizedBox(height: 24),

                  // Charts
                  _isLoading ? _buildChartsShimmer() : _buildCharts(),
                  const SizedBox(height: 24),

                  // Popular items section
                  _buildPopularItemsSection(),
                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTimeRange,
                icon: Icon(Icons.keyboard_arrow_down,
                    size: 20, color: Colors.grey[700]),
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                items: _timeRanges
                    .map((range) => DropdownMenuItem(
                          value: range,
                          child: Text(range),
                        ))
                    .toList(),
                onChanged: _updateTimeRange,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).moveX(
              begin: 20, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .moveY(begin: -10, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
  }

  Widget _buildStatisticsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCards() {
    // Define colors for each card
    final List<LinearGradient> gradients = [
      LinearGradient(
        colors: [Color(0xFF6448FE), Color(0xFF5FC6FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      LinearGradient(
        colors: [Color(0xFF2ECE7B), Color(0xFF33D890)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      LinearGradient(
        colors: [Color(0xFFFE9A37), Color(0xFFFFB566)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      LinearGradient(
        colors: [Color(0xFFFF5182), Color(0xFFFF7B9E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ];

    final List<IconData> icons = [
      Icons.shopping_bag_rounded,
      Icons.check_circle_outlined,
      Icons.pending_actions_outlined,
      Icons.currency_rupee_rounded,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: statistics.length,
      itemBuilder: (context, index) {
        String key = statistics.keys.elementAt(index);
        var value = statistics[key];
        double trend = trends[key] ?? 0;
        bool isPositive = trend >= 0;

        String displayValue;
        if (key == "Revenue") {
          displayValue = "₹${NumberFormat('#,###.##').format(value)}";
        } else {
          displayValue = value.toString();
        }

        return Container(
          decoration: BoxDecoration(
            gradient: gradients[index],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradients[index].colors.first.withAlpha(76),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icons[index], color: Colors.white, size: 22),
                    ),
                    Row(
                      children: [
                        Icon(
                          isPositive ? Icons.trending_up : Icons.trending_down,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${trend.abs().toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  displayValue,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  key,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha(229),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms * index).slideY(
            begin: 0.2,
            end: 0,
            duration: 400.ms,
            delay: 100.ms * index,
            curve: Curves.easeOutQuad);
      },
    );
  }

  Widget _buildChartsShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 180,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCharts() {
    // Determine chart title based on selected time range
    String chartPeriod = _selectedTimeRange;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Trends',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ).animate().fadeIn(duration: 400.ms).moveX(
            begin: -20, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue ($chartPeriod)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: revenueSpots.isEmpty
                          ? Center(
                              child: Text(
                                'No data available',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            )
                          : LineChart(
                              LineChartData(
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  show: true,
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 22,
                                      getTitlesWidget: (value, meta) {
                                        const style = TextStyle(
                                          color: Color(0xff68737d),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        );
                                        String text = '';
                                        
                                        // Customize labels based on time range
                                        if (_selectedTimeRange == 'All Time') {
                                          if (value.toInt() == 0) {
                                            text = 'Start';
                                          } else if (value.toInt() == 3) {
                                            text = 'Mid';
                                          } else if (value.toInt() == revenueSpots.length - 1 || value.toInt() == 6) {
                                            text = 'Now';
                                          }
                                        } else if (_selectedTimeRange == 'This Month') {
                                          // Show week markers
                                          if (value.toInt() == 0) {
                                            text = 'W1';
                                          } else if (value.toInt() == 2) {
                                            text = 'W2';
                                          } else if (value.toInt() == 4) {
                                            text = 'W3';
                                          } else if (value.toInt() == 6) {
                                            text = 'W4';
                                          }
                                        } else if (_selectedTimeRange == 'This Week') {
                                          if (value.toInt() == 0) {
                                            text = 'Day 1';
                                          } else if (value.toInt() == 3) {
                                            text = 'Day 4';
                                          } else if (value.toInt() == 6) {
                                            text = 'Day 7';
                                          }
                                        } else {
                                          // For Today or Yesterday, just show hours
                                          if (value.toInt() == 0) {
                                            text = 'Start';
                                          } else if (value.toInt() == revenueSpots.length - 1) {
                                            text = 'End';
                                          }
                                        }
                                        
                                        return SideTitleWidget(
                                          meta: meta,
                                          space: 4,
                                          child: Text(text, style: style),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: revenueSpots,
                                    isCurved: true,
                                    color: Colors.blue,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.blue.withAlpha(51),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideX(
                  begin: -0.2,
                  end: 0,
                  duration: 600.ms,
                  curve: Curves.easeOutQuad),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orders ($chartPeriod)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ordersSpots.isEmpty
                          ? Center(
                              child: Text(
                                'No data available',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            )
                          : LineChart(
                              LineChartData(
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  show: true,
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 22,
                                      getTitlesWidget: (value, meta) {
                                        const style = TextStyle(
                                          color: Color(0xff68737d),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        );
                                        String text = '';
                                        
                                        // Customize labels based on time range
                                        if (_selectedTimeRange == 'All Time') {
                                          if (value.toInt() == 0) {
                                            text = 'Start';
                                          } else if (value.toInt() == 3) {
                                            text = 'Mid';
                                          } else if (value.toInt() == ordersSpots.length - 1 || value.toInt() == 6) {
                                            text = 'Now';
                                          }
                                        } else if (_selectedTimeRange == 'This Month') {
                                          // Show week markers
                                          if (value.toInt() == 0) {
                                            text = 'W1';
                                          } else if (value.toInt() == 2) {
                                            text = 'W2';
                                          } else if (value.toInt() == 4) {
                                            text = 'W3';
                                          } else if (value.toInt() == 6) {
                                            text = 'W4';
                                          }
                                        } else if (_selectedTimeRange == 'This Week') {
                                          if (value.toInt() == 0) {
                                            text = 'Day 1';
                                          } else if (value.toInt() == 3) {
                                            text = 'Day 4';
                                          } else if (value.toInt() == 6) {
                                            text = 'Day 7';
                                          }
                                        } else {
                                          // For Today or Yesterday, just show hours
                                          if (value.toInt() == 0) {
                                            text = 'Start';
                                          } else if (value.toInt() == ordersSpots.length - 1) {
                                            text = 'End';
                                          }
                                        }
                                        
                                        return SideTitleWidget(
                                          meta: meta,
                                          space: 4,
                                          child: Text(text, style: style),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: ordersSpots,
                                    isCurved: true,
                                    color: Colors.green,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.green.withAlpha(51),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideX(
                  begin: 0.2,
                  end: 0,
                  duration: 600.ms,
                  curve: Curves.easeOutQuad),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPopularItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Popular Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 500.ms).moveX(
                begin: -20,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOutQuad),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManagerManageMenu()),
                );
              },
              child: Text(
                'View all',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 500.ms).moveX(
                begin: 20, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
          ],
        ),
        const SizedBox(height: 8),

        // Categories
        _isLoading ? _buildCategoriesShimmer() : _buildCategories(),
        const SizedBox(height: 16),

        // Popular items horizontal list
        _isLoading ? _buildPopularItemsListShimmer() : _buildPopularItemsList(),
      ],
    );
  }

  Widget _buildCategoriesShimmer() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;

          return GestureDetector(
            onTap: () {
              _updateCategory(category);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[300]!,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 600.ms + (50.ms * index))
                .slideX(
                    begin: 0.2,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutQuad),
          );
        },
      ),
    );
  }

  Widget _buildPopularItemsListShimmer() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 180,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularItemsList() {
    // Filter items by category if needed
    List<Map<String, dynamic>> filteredItems = popularItems;
    if (_selectedCategory != 'All') {
      filteredItems = popularItems
          .where((item) => item['category'] == _selectedCategory)
          .toList();
    }
    
    if (filteredItems.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Text(
          'No items found in this category',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          final isPositiveTrend = (item["trend"] as double) >= 0;

          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item image with shimmer effect on load
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        item["image"] as String,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: Icon(Icons.image_not_supported, color: Colors.grey[500]),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 120,
                              width: double.infinity,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPositiveTrend
                              ? Colors.green.withAlpha(229)
                              : Colors.red.withAlpha(229),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPositiveTrend
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${item["trend"].abs().toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["name"] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item["category"] as String,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sold: ${item["sold"]}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '₹${NumberFormat('#,###.##').format(item["revenue"])}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 700.ms + (100.ms * index), duration: 500.ms)
              .slideX(
                  begin: 0.2,
                  end: 0,
                  delay: 700.ms + (100.ms * index),
                  duration: 400.ms,
                  curve: Curves.easeOutQuad)
              .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                  delay: 2.seconds)
              .shimmer(
                  duration: 1.seconds,
                  angle: 0.5,
                  color: Colors.white.withAlpha(51));
        },
      ),
    );
  }

  Widget _buildQuickActionsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          2,
          (index) => Container(
            width: MediaQuery.of(context).size.width * 0.43,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  // Method to handle action tap safely
  void _handleActionTap(Map<String, dynamic> action) {
    if(action['title'] == 'Manage Menu'){
      Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ManagerManageMenu()),
          );
    }
    else if(action['title'] == 'Manage Payment'){
     Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ManagerPaymentMethods()),
          );
    }
  }

  Widget _buildQuickActions() {
    final List<Map<String, dynamic>> actions = [
      {
        'title': 'Manage Menu',
        'icon': Icons.restaurant_menu,
        'color': Colors.blue[700]!,
      },
     {
        'title': 'Manage Payment',
        'icon': Icons.payment,
        'color': Colors.blue[700]!,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ).animate().fadeIn(delay: 900.ms, duration: 400.ms).moveX(
            begin: -20, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
        const SizedBox(height: 16),
        _isLoading
            ? _buildQuickActionsShimmer()
            : _buildQuickActionsGrid(actions),
      ],
    );
  }

  Widget _buildQuickActionsGrid(List<Map<String, dynamic>> actions) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.asMap().entries.map((entry) {
        final index = entry.key;
        final action = entry.value;

        return InkWell(
          onTap: () => _handleActionTap(action),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.43,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: action['color'].withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    action['icon'],
                    color: action['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  action['title'],
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 1.seconds + (100.ms * index), duration: 400.ms)
            .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 300.ms,
                curve: Curves.elasticOut)
            .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
                delay: 3.seconds)
            .shimmer(
                duration: 1.seconds, color: action['color'].withAlpha(51));
      }).toList(),
    );
  }
}