import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ManagerReport extends StatefulWidget {
  const ManagerReport({Key? key}) : super(key: key);

  @override
  _ManagerReportState createState() => _ManagerReportState();
}

class _ManagerReportState extends State<ManagerReport> {
  String selectedTimeFrame = 'Weekly';
  List<String> timeFrames = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  bool _isLoading = true;
  int _selectedChartTypeIndex = 0;
  final List<String> _chartTypes = ['Bar', 'Line', 'Pie'];
  
  // Store ID from SharedPreferences
  String _storeId = '';
  
  // Data containers
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> salesData = [];
  
  // Summary metrics
  Map<String, dynamic> summaryMetrics = {
    'totalSales': 0.0,
    'totalOrders': 0,
    'avgOrderValue': 0.0,
    'salesChange': 0.0,
    'ordersChange': 0.0,
    'avgOrderChange': 0.0,
  };

  @override
  void initState() {
    super.initState();
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
        
        // Load data based on selected time frame
        await _loadDataForTimeFrame(selectedTimeFrame);
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

  Future<void> _loadDataForTimeFrame(String timeFrame) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate date ranges based on selected time frame
      final now = DateTime.now();
      DateTime startDate;
      DateTime previousPeriodStart;
      DateTime previousPeriodEnd;
      
      // Determine date ranges for current and previous periods
      switch (timeFrame) {
        case 'Daily':
          startDate = DateTime(now.year, now.month, now.day);
          previousPeriodStart = startDate.subtract(const Duration(days: 1));
          previousPeriodEnd = startDate;
          break;
        case 'Weekly':
          // Start from beginning of the week (considering Monday as first day)
          final daysToSubtract = now.weekday - 1;
          startDate = DateTime(now.year, now.month, now.day - daysToSubtract);
          previousPeriodStart = startDate.subtract(const Duration(days: 7));
          previousPeriodEnd = startDate;
          break;
        case 'Monthly':
          startDate = DateTime(now.year, now.month, 1);
          previousPeriodStart = DateTime(now.year, now.month - 1, 1);
          previousPeriodEnd = startDate;
          break;
        case 'Yearly':
          startDate = DateTime(now.year, 1, 1);
          previousPeriodStart = DateTime(now.year - 1, 1, 1);
          previousPeriodEnd = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day - 6); // Default to weekly
          previousPeriodStart = startDate.subtract(const Duration(days: 7));
          previousPeriodEnd = startDate;
      }

      // Load orders from Firebase Realtime Database
      await _fetchAndProcessOrders(timeFrame, startDate, now, previousPeriodStart, previousPeriodEnd);
      
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

  Future<void> _fetchAndProcessOrders(
    String timeFrame, 
    DateTime startDate, 
    DateTime endDate,
    DateTime previousPeriodStart,
    DateTime previousPeriodEnd
  ) async {
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
        _processOrdersData(
          timeFrame,
          ordersData, 
          startDate, 
          endDate,
          previousPeriodStart,
          previousPeriodEnd
        );
      } else {
        print('No orders data available');
        _resetData();
      }
    } catch (e) {
      print('Error fetching orders: $e');
      _resetData();
    }
  }

  void _resetData() {
    setState(() {
      salesData = [];
      categories = [];
      summaryMetrics = {
        'totalSales': 0.0,
        'totalOrders': 0,
        'avgOrderValue': 0.0,
        'salesChange': 0.0,
        'ordersChange': 0.0,
        'avgOrderChange': 0.0,
      };
    });
  }

  void _processOrdersData(
    String timeFrame,
    Map<dynamic, dynamic> ordersData, 
    DateTime startDate, 
    DateTime endDate,
    DateTime previousPeriodStart,
    DateTime previousPeriodEnd
  ) {
    // Counters for current period
    double totalSales = 0.0;
    int totalOrders = 0;
    
    // Counters for previous period (for calculating change percentages)
    double previousTotalSales = 0.0;
    int previousTotalOrders = 0;
    
    // Maps for category stats
    Map<String, double> categoryRevenue = {};
    Map<String, int> categoryCount = {};
    
    // Maps for time-series data based on selected timeframe
    Map<String, double> periodSales = {};
    
    // Define periods based on timeframe for chart
    List<String> chartLabels = _generateChartLabels(timeFrame, startDate, endDate);
    
    // Initialize sales data with zeros
    chartLabels.forEach((label) {
      periodSales[label] = 0.0;
    });
    
    // Process each order
    ordersData.forEach((key, value) {
      try {
        final orderData = value as Map<dynamic, dynamic>;
        final orderTimestamp = orderData['timestamp'] as String?;
        
        if (orderTimestamp != null) {
          final orderDate = DateTime.parse(orderTimestamp);
          
          // Check if this order belongs to current period or previous period
          bool isCurrentPeriod = orderDate.isAfter(startDate.subtract(const Duration(minutes: 1))) && 
                                 orderDate.isBefore(endDate.add(const Duration(minutes: 1)));
          
          bool isPreviousPeriod = orderDate.isAfter(previousPeriodStart.subtract(const Duration(minutes: 1))) && 
                                  orderDate.isBefore(previousPeriodEnd.add(const Duration(minutes: 1)));
          
          // Only completed orders are counted
          final status = orderData['status'] as String?;
          if (status == 'completed') {
            final totalAmount = orderData['totalAmount'];
            if (totalAmount != null) {
              final double orderAmount = (totalAmount is double) 
                  ? totalAmount 
                  : double.tryParse(totalAmount.toString()) ?? 0.0;
              
              // Add to current period stats if applicable
              if (isCurrentPeriod) {
                totalSales += orderAmount;
                totalOrders++;
                
                // Add to time-series data for chart
                String periodKey = _getPeriodKeyForDate(timeFrame, orderDate, startDate);
                if (periodSales.containsKey(periodKey)) {
                  periodSales[periodKey] = (periodSales[periodKey] ?? 0.0) + orderAmount;
                }
                
                // Process categories
                final items = orderData['items'];
                if (items != null && items is List) {
                  for (var item in items) {
                    if (item is Map) {
                      final category = item['category'] as String? ?? 'Uncategorized';
                      final price = item['price'];
                      final quantity = item['quantity'] ?? 1;
                      
                      if (price != null) {
                        final double itemPrice = (price is double) 
                            ? price 
                            : double.tryParse(price.toString()) ?? 0.0;
                        
                        final double totalItemPrice = itemPrice * (quantity is int ? quantity : 1);
                        
                        // Update category stats
                        categoryRevenue[category] = (categoryRevenue[category] ?? 0.0) + totalItemPrice;
                        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
                      }
                    }
                  }
                }
              }
              
              // Add to previous period stats if applicable
              if (isPreviousPeriod) {
                previousTotalSales += orderAmount;
                previousTotalOrders++;
              }
            }
          }
        }
      } catch (e) {
        print('Error processing order $key: $e');
      }
    });
    
    // Calculate percentage changes
    double salesChange = previousTotalSales > 0 
        ? ((totalSales - previousTotalSales) / previousTotalSales) * 100 
        : 0.0;
    
    double ordersChange = previousTotalOrders > 0 
        ? ((totalOrders - previousTotalOrders) / previousTotalOrders) * 100 
        : 0.0;
    
    // Calculate average order values
    double avgOrderValue = totalOrders > 0 ? totalSales / totalOrders : 0.0;
    double prevAvgOrderValue = previousTotalOrders > 0 ? previousTotalSales / previousTotalOrders : 0.0;
    double avgOrderChange = prevAvgOrderValue > 0 
        ? ((avgOrderValue - prevAvgOrderValue) / prevAvgOrderValue) * 100 
        : 0.0;
    
    // Prepare sales data for charts
    List<Map<String, dynamic>> chartData = [];
    periodSales.forEach((key, value) {
      chartData.add({
        'day': key,
        'sales': value,
      });
    });
    
    // Sort chart data to ensure correct order
    if (timeFrame == 'Weekly') {
      final Map<String, int> dayOrder = {
        'Mon': 0, 'Tue': 1, 'Wed': 2, 'Thu': 3, 'Fri': 4, 'Sat': 5, 'Sun': 6
      };
      chartData.sort((a, b) => dayOrder[a['day']]!.compareTo(dayOrder[b['day']]!));
    } else {
      // For other timeframes, try to maintain chronological order
      chartData.sort((a, b) => a['day'].compareTo(b['day']));
    }
    
    // Prepare category data
    List<Map<String, dynamic>> categoryData = [];
    double totalRevenue = categoryRevenue.values.fold(0, (prev, curr) => prev + curr);
    
    // Define a list of predefined colors for categories
    final List<Color> categoryColors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    
    int colorIndex = 0;
    categoryRevenue.forEach((category, revenue) {
      final percentage = totalRevenue > 0 ? ((revenue / totalRevenue) * 100).round() : 0;
      
      categoryData.add({
        'name': category,
        'sales': 'Rs. ${NumberFormat('#,###.##').format(revenue)}',
        'percentage': percentage,
        'color': categoryColors[colorIndex % categoryColors.length],
      });
      
      colorIndex++;
    });
    
    // Sort categories by revenue (highest first)
    categoryData.sort((a, b) => b['percentage'].compareTo(a['percentage']));
    
    // Take top categories (limit to 4-5 for better visualization)
    if (categoryData.length > 5) {
      // Extract top 4 categories
      final topCategories = categoryData.sublist(0, 4);
      
      // Combine the rest as "Other"
      double otherRevenue = 0;
      int otherPercentage = 0;
      
      for (int i = 4; i < categoryData.length; i++) {
        final rawRevenue = categoryData[i]['sales'].toString().replaceAll('Rs. ', '').replaceAll(',', '');
        otherRevenue += double.tryParse(rawRevenue) ?? 0;
        otherPercentage += categoryData[i]['percentage'] as int;
      }
      
      topCategories.add({
        'name': 'Other',
        'sales': 'Rs. ${NumberFormat('#,###.##').format(otherRevenue)}',
        'percentage': otherPercentage,
        'color': Colors.grey,
      });
      
      categoryData = topCategories;
    }
    
    // Update state with processed data
    setState(() {
      salesData = chartData;
      categories = categoryData;
      summaryMetrics = {
        'totalSales': totalSales,
        'totalOrders': totalOrders,
        'avgOrderValue': avgOrderValue,
        'salesChange': salesChange,
        'ordersChange': ordersChange,
        'avgOrderChange': avgOrderChange,
      };
    });
  }

  List<String> _generateChartLabels(String timeFrame, DateTime startDate, DateTime endDate) {
    List<String> labels = [];
    
    switch (timeFrame) {
      case 'Daily':
        // For daily, use hours
        for (int hour = 0; hour < 24; hour += 2) {
          final label = hour < 12 
              ? '${hour == 0 ? 12 : hour}am' 
              : '${hour == 12 ? 12 : hour - 12}pm';
          labels.add(label);
        }
        break;
      
      case 'Weekly':
        // For weekly, use day names
        labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        break;
      
      case 'Monthly':
        // For monthly, use weeks or specific dates
        final daysInMonth = DateTime(startDate.year, startDate.month + 1, 0).day;
        for (int day = 1; day <= daysInMonth; day += 5) {
          labels.add('$day');
        }
        break;
      
      case 'Yearly':
        // For yearly, use months
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        labels = months;
        break;
    }
    
    return labels;
  }

  String _getPeriodKeyForDate(String timeFrame, DateTime date, DateTime startDate) {
    switch (timeFrame) {
      case 'Daily':
        // Group by 2-hour periods
        final hour = date.hour;
        final periodHour = (hour ~/ 2) * 2;
        final label = periodHour < 12 
            ? '${periodHour == 0 ? 12 : periodHour}am' 
            : '${periodHour == 12 ? 12 : periodHour - 12}pm';
        return label;
      
      case 'Weekly':
        // Use day name
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[date.weekday - 1];
      
      case 'Monthly':
        // Group by 5-day periods
        final dayOfMonth = date.day;
        final periodStart = ((dayOfMonth - 1) ~/ 5) * 5 + 1;
        return '$periodStart';
      
      case 'Yearly':
        // Use month name
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return months[date.month - 1];
    }
    
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading ? _buildLoadingView() : _buildReportContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerHeader(),
          const SizedBox(height: 20),
          _buildShimmerChart(),
          const SizedBox(height: 30),
          _buildShimmerCategoryTitle(),
          const SizedBox(height: 16),
          _buildShimmerCategories(),
          const SizedBox(height: 30),
          _buildShimmerActions(),
        ],
      ),
    );
  }

  Widget _buildShimmerHeader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 30,
            width: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
          ),
          Container(
            height: 30,
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerChart() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildShimmerCategoryTitle() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 24,
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildShimmerCategories() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(4, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 16,
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      height: 16,
                      width: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildShimmerActions() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return Container(
            height: 40,
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildReportContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader()
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.2, end: 0),
          const SizedBox(height: 20),
          _buildChartSelector()
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms),
          const SizedBox(height: 10),
          _buildChart()
            .animate()
            .fadeIn(delay: 400.ms, duration: 800.ms)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
          const SizedBox(height: 20),
          _buildSummaryCards()
            .animate()
            .fadeIn(delay: 600.ms, duration: 600.ms),
          const SizedBox(height: 30),
          Text(
            'Top Categories',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          )
            .animate()
            .fadeIn(delay: 800.ms, duration: 600.ms),
          const SizedBox(height: 16),
          _buildCategoryStats()
            .animate()
            .fadeIn(delay: 1000.ms, duration: 600.ms),
          const SizedBox(height: 30),
          _buildReportActions()
            .animate()
            .fadeIn(delay: 1200.ms, duration: 600.ms)
            .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Reports',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Text(
              'Restaurant performance',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(25),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: DropdownButton<String>(
            value: selectedTimeFrame,
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            underline: const SizedBox(),
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
            onChanged: (String? newValue) {
              if (newValue != null && newValue != selectedTimeFrame) {
                setState(() {
                  selectedTimeFrame = newValue;
                });
                _loadDataForTimeFrame(newValue);
              }
            },
            items: timeFrames.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildChartSelector() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          _chartTypes.length,
          (index) => GestureDetector(
            onTap: () {
              setState(() {
                _selectedChartTypeIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedChartTypeIndex == index
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _chartTypes[index],
                style: TextStyle(
                  color: _selectedChartTypeIndex == index
                      ? Colors.white
                      : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
                .animate(target: _selectedChartTypeIndex == index ? 1 : 0)
                .scaleXY(end: 1.05, duration: 200.ms)
                .then()
                .scaleXY(end: 1.0, duration: 200.ms),
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: salesData.isEmpty
          ? Center(
              child: Text(
                'No data available for this period',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            )
          : _getSelectedChart(),
    );
  }

  Widget _getSelectedChart() {
    switch (_selectedChartTypeIndex) {
      case 0:
        return _buildBarChart();
      case 1:
        return _buildLineChart();
      case 2:
        return _buildPieChart();
      default:
        return _buildBarChart();
    }
  }

  Widget _buildBarChart() {
    // Find max value for Y axis with some padding
    final maxY = salesData.fold<double>(
      0, 
      (max, item) => item['sales'] > max ? (item['sales'] * 1.2) : max
    );
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY > 0 ? maxY : 6000,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                'Rs. ${NumberFormat('#,###.##').format(salesData[groupIndex]['sales'])}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= salesData.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    salesData[value.toInt()]['day'],
                    style: const TextStyle(
                      color: Color(0xff7589a2),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: maxY > 10000 ? 5000 : (maxY > 1000 ? 1000 : 500),
              getTitlesWidget: (double value, TitleMeta meta) {
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    value == 0 ? '0' : '${(value / 1000).toInt()}K',
                    style: const TextStyle(
                      color: Color(0xff7589a2),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          salesData.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: salesData[index]['sales'].toDouble(),
                color: Theme.of(context).primaryColor,
                width: 20,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY > 0 ? maxY : 6000,
                  color: Colors.grey.withAlpha(25),
                ),
              ),
            ],
          ),
        ),
        gridData: FlGridData(
          show: true,
          checkToShowHorizontalLine: (value) => value % 1000 == 0,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withAlpha(51),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    // Find max value for Y axis with some padding
    final maxY = salesData.fold<double>(
      0, 
      (max, item) => item['sales'] > max ? (item['sales'] * 1.2) : max
    );
    
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  'Rs. ${NumberFormat('#,###.##').format(spot.y)}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 10000 ? 5000 : (maxY > 1000 ? 1000 : 500),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withAlpha(51),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= salesData.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    salesData[value.toInt()]['day'],
                    style: const TextStyle(
                      color: Color(0xff7589a2),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY > 10000 ? 5000 : (maxY > 1000 ? 1000 : 500),
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    value == 0 ? '0' : '${(value / 1000).toInt()}K',
                    style: const TextStyle(
                      color: Color(0xff7589a2),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: salesData.length - 1.0,
        minY: 0,
        maxY: maxY > 0 ? maxY : 6000,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              salesData.length, 
              (index) => FlSpot(index.toDouble(), salesData[index]['sales'].toDouble()),
            ),
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withAlpha(51),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    // If no categories with data, show message
    if (categories.isEmpty || categories.every((cat) => cat['percentage'] == 0)) {
      return Center(
        child: Text(
          'No category data available',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }
    
    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: List.generate(
                categories.length,
                (index) {
                  return PieChartSectionData(
                    color: categories[index]['color'],
                    value: categories[index]['percentage'].toDouble(),
                    title: '${categories[index]['percentage']}%',
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: categories.map((category) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: category['color'],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    category['name'].toString().length > 8
                        ? '${category['name'].toString().substring(0, 8)}...'
                        : category['name'].toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final List<Map<String, dynamic>> summaries = [
      {
        'title': 'Total Sales',
        'value': 'Rs. ${NumberFormat('#,###').format(summaryMetrics['totalSales'])}',
        'change': '${summaryMetrics['salesChange'].toStringAsFixed(1)}%',
        'isPositive': summaryMetrics['salesChange'] >= 0,
        'icon': Icons.trending_up,
      },
      {
        'title': 'Orders',
        'value': '${summaryMetrics['totalOrders']}',
        'change': '${summaryMetrics['ordersChange'].toStringAsFixed(1)}%',
        'isPositive': summaryMetrics['ordersChange'] >= 0,
        'icon': Icons.shopping_bag,
      },
      {
        'title': 'Avg. Order Value',
        'value': 'Rs. ${NumberFormat('#,###').format(summaryMetrics['avgOrderValue'])}',
        'change': '${summaryMetrics['avgOrderChange'].toStringAsFixed(1)}%',
        'isPositive': summaryMetrics['avgOrderChange'] >= 0,
        'icon': Icons.attach_money,
      },
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: summaries.length,
        itemBuilder: (context, index) {
          final item = summaries[index];
          return Container(
            width: MediaQuery.of(context).size.width * 0.42,
            margin: EdgeInsets.only(right: index < summaries.length - 1 ? 12 : 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['title'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Icon(
                      item['icon'],
                      color: Theme.of(context).primaryColor,
                      size: 18,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['value'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item['isPositive']
                            ? Colors.green.withAlpha(25)
                            : Colors.red.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['change'],
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              item['isPositive'] ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().scale(delay: (index * 200).ms, duration: 400.ms);
        },
      ),
    );
  }
  
  Widget _buildCategoryStats() {
    if (categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            'No category data available for this period',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: categories.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> category = entry.value;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(12),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: category['color'],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category['name'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      category['sales'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      width: MediaQuery.of(context).size.width *
                          (category['percentage'] as int) / 100 * 0.83,
                      height: 8,
                      decoration: BoxDecoration(
                        color: category['color'],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ).animate(delay: (100 * index).ms).slideX(
                          begin: -1,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOut,
                        ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${category['percentage']}% of total sales',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 200).ms, duration: 400.ms)
         .slideY(begin: 0.2, end: 0);
      }).toList(),
    );
  }
  
  Widget _buildReportActions() {
    final List<Map<String, dynamic>> actions = [
      {'icon': Icons.share, 'label': 'Share', 'color': Colors.green[700]!},
      {'icon': Icons.download, 'label': 'Download', 'color': Colors.orange[700]!},
    ];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> action = entry.value;
        
        return ElevatedButton.icon(
          onPressed: () {
            // In a real app, implement sharing or downloading functionality
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${action['label']} report functionality would be implemented here'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          icon: Icon(action['icon']),
          label: Text(action['label']),
          style: ElevatedButton.styleFrom(
            backgroundColor: action['color'],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 2,
          ),
        ).animate().fadeIn(delay: (index * 200).ms, duration: 400.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
      }).toList(),
    );
  }
}