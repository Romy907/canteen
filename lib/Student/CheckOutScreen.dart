import 'package:canteen/Student/MyOrdersScreen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:upi_pay/upi_pay.dart';

class CheckOutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final bool isBuyNow;

  const CheckOutScreen({
    Key? key,
    required this.items,
    this.isBuyNow = false,
  }) : super(key: key);

  @override
  CheckOutScreenState createState() => CheckOutScreenState();
}

class CheckOutScreenState extends State<CheckOutScreen> {
  bool _isProcessing = false;
  String _deliveryTime = 'As soon as possible';
  final TextEditingController _notesController = TextEditingController();

  // Store data
  bool _isLoadingStoreData = true;
  Map<String, dynamic> _storeTimings = {};
  // Preparation time in minutes (default 15 min)
  int _preparationTime = 15;

  // Selected UPI app
  String? _selectedUpiApp;
  List<ApplicationMeta>? _upiApps;
  bool _isLoadingUpiApps = true;
  final upiPay = UpiPay();

  // Current timestamp
  final String _orderTimestamp =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _fetchStoreData();
    _loadUpiApps();

    // Add this debug section
    print("Checking for UPI apps...");
    Future.delayed(Duration(seconds: 3), () {
      if (_upiApps == null || _upiApps!.isEmpty) {
        print("No UPI apps detected after 3 seconds");
      } else {
        print("Detected ${_upiApps!.length} UPI apps:");
        for (var app in _upiApps!) {
          print(" - ${app.upiApplication.getAppName()}");
        }
      }
    });
  }
  // Load available UPI apps on the device
  // Add this improved method to your CheckOutScreenState class

  Future<void> _loadUpiApps() async {
    setState(() {
      _isLoadingUpiApps = true;
    });

    try {
      // Try with both discovery methods
      _upiApps = await upiPay.getInstalledUpiApplications(
          statusType: UpiApplicationDiscoveryAppStatusType.all);

      print("Found ${_upiApps?.length ?? 0} UPI apps");

      // If no apps found, show debug info
      if (_upiApps == null || _upiApps!.isEmpty) {
        print("No UPI apps found. Trying alternative discovery method...");

        // You could add fallback discovery here if needed
      }

      // Set the first app as default if available
      if (_upiApps != null && _upiApps!.isNotEmpty) {
        _selectedUpiApp = _upiApps![0].upiApplication.toString();
        print(
            "Selected default app: ${_upiApps![0].upiApplication.getAppName()}");
      }
    } catch (e) {
      print('Error loading UPI apps: $e');
    } finally {
      setState(() {
        _isLoadingUpiApps = false;
      });
    }
  }
// Add this method to your CheckOutScreenState class

  Widget _buildManualUpiAppSelection() {
    // Common UPI apps in India
    final List<Map<String, dynamic>> commonUpiApps = [
      {
        'name': 'Google Pay',
        'package': 'com.google.android.apps.nbu.paisa.user',
        'icon': Icons.account_balance_wallet,
        'color': Colors.green,
      },
      {
        'name': 'PhonePe',
        'package': 'com.phonepe.app',
        'icon': Icons.phone_android,
        'color': Colors.indigo,
      },
      {
        'name': 'Paytm',
        'package': 'net.one97.paytm',
        'icon': Icons.payment,
        'color': Colors.blue,
      },
      {
        'name': 'Amazon Pay',
        'package': 'in.amazon.mShop.android.shopping',
        'icon': Icons.shopping_cart,
        'color': Colors.orange,
      },
      {
        'name': 'BHIM',
        'package': 'in.org.npci.upiapp',
        'icon': Icons.account_balance,
        'color': Colors.deepPurple,
      },
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: commonUpiApps.length,
      itemBuilder: (context, index) {
        final app = commonUpiApps[index];
        final isSelected = _selectedUpiApp == app['package'];

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedUpiApp = app['package'];
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color:
                  isSelected ? app['color'].withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? app['color'] : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: app['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(app['icon'], color: app['color'], size: 32),
                ),
                const SizedBox(height: 8),
                // App name
                Text(
                  app['name'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Selected indicator
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: app['color'],
                    size: 16,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchStoreData() async {
    setState(() {
      _isLoadingStoreData = true;
    });

    try {
      // Fetch store data from Firebase
      final storeRef =
          FirebaseDatabase.instance.ref().child(widget.items[0]['storeId']);
      final snapshot = await storeRef.get();

      if (snapshot.exists) {
        final storeData = Map<String, dynamic>.from(snapshot.value as Map);

        // Get store timings
        if (storeData.containsKey('store_timings')) {
          _storeTimings =
              Map<String, dynamic>.from(storeData['store_timings'] as Map);
        }

        // Get preparation time if available
        if (storeData.containsKey('preparation_time')) {
          _preparationTime = storeData['preparation_time'] ?? 15;
        }
      }
    } catch (e) {
      print('Error fetching store data: $e');
    } finally {
      setState(() {
        _isLoadingStoreData = false;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Helper method to safely convert price to double
  double _getPriceAsDouble(dynamic price) {
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      try {
        // Remove currency symbol if present and parse
        String cleanedPrice = price.replaceAll(RegExp(r'[^\d.]'), '');
        return double.parse(cleanedPrice);
      } catch (e) {
        return 0.0; // Default if parsing fails
      }
    }
    return 0.0; // Default for other cases
  }

  // Calculate the discounted price for an item
  double _getDiscountedPrice(Map<String, dynamic> item) {
    double originalPrice = _getPriceAsDouble(item['price']);

    // Check if item has a discount
    if (item.containsKey('hasDiscount') && item['hasDiscount'] == true) {
      // Get discount percentage
      double discountPercent = _getPriceAsDouble(item['discount']);
      // Apply discount
      return originalPrice * (1 - discountPercent / 100);
    }

    // Return original price if no discount
    return originalPrice;
  }

  // Calculate subtotal from items (with discounts applied)
  double get _subtotal {
    return widget.items.fold(0.0, (sum, item) {
      double itemPrice = _getDiscountedPrice(item);
      int quantity = item['quantity'] ?? 1;
      return sum + (itemPrice * quantity);
    });
  }

  // Original subtotal (without discounts) - for display purposes
  double get _originalSubtotal {
    return widget.items.fold(0.0, (sum, item) {
      double itemPrice = _getPriceAsDouble(item['price']);
      int quantity = item['quantity'] ?? 1;
      return sum + (itemPrice * quantity);
    });
  }

  // Calculate total discount amount
  double get _totalDiscount {
    return widget.items.fold(0.0, (sum, item) {
      if (item.containsKey('hasDiscount') && item['hasDiscount'] == true) {
        double originalPrice = _getPriceAsDouble(item['price']);
        double discountedPrice = _getDiscountedPrice(item);
        int quantity = item['quantity'] ?? 1;
        return sum + ((originalPrice - discountedPrice) * quantity);
      }
      return sum;
    });
  }

  // Calculate taxes (5% on discounted subtotal)
  double get _tax => _subtotal * 0.05;

  // Delivery fee
  double get _platformcharge => 2.0;

  // Calculate the total amount
  double get _total => _subtotal + _tax + _platformcharge;

  // Format currency
  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  // Order ID generator
  String get _orderId {
    final now = DateTime.parse(_orderTimestamp);
    final formatter = DateFormat('yyyyMMddHHmmss');
    return 'ORD-${formatter.format(now)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.isBuyNow ? "Quick Checkout" : "Checkout",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingStoreData
          ? _buildLoadingView()
          : widget.items.isEmpty
              ? _buildEmptyCart()
              : _buildCheckoutContent(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            "Loading checkout details...",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            "Your cart is empty",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Add some items to your cart to checkout",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "Continue Shopping",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutContent() {
    return Stack(
      children: [
        // Main scrollable content
        ListView(
          padding: const EdgeInsets.fromLTRB(
              16, 16, 16, 120), // Bottom padding for place order button
          children: [
            // Order ID and timestamp - Fixed responsive layout
            _buildOrderHeader(),
            const SizedBox(height: 24),

            // Order summary section
            _buildSectionTitle("Order Summary"),
            const SizedBox(height: 8),
            _buildOrderItems(),
            const SizedBox(height: 24),

            // Delivery details section - Updated with preparation time
            _buildSectionTitle("Delivery Details"),
            const SizedBox(height: 8),
            _buildDeliveryForm(),
            const SizedBox(height: 24),

            // Payment method section - UPI App selection
            _buildSectionTitle("Payment Method"),
            const SizedBox(height: 8),
            _buildPaymentMethod(),
            const SizedBox(height: 24),

            // Additional notes - Improved UI
            _buildSectionTitle("Additional Notes"),
            const SizedBox(height: 8),
            _buildNotesField(),
            const SizedBox(height: 16),

            // Order summary
            _buildPriceDetails(),
          ],
        ),

        // Fixed bottom bar with Place Order button
        Align(
          alignment: Alignment.bottomCenter,
          child: _buildPlaceOrderBar(),
        ),
      ],
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed responsive layout for order ID
          Row(
            children: [
              // Order ID Container that flexes to fit available space
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order ID:",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "#${_orderId}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status badge that doesn't shrink
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "New Order",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date with better formatting
          Row(
            children: [
              Icon(Icons.event, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                "Date: $_orderTimestamp",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          // Show store status based on current day's schedule
          const SizedBox(height: 12),
          _buildStoreStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildStoreStatusIndicator() {
    // Get current day
    final now = DateTime.now();
    final currentDay =
        DateFormat('EEEE').format(now); // Returns day name like 'Monday'

    // Check if store is open today based on database
    bool isOpenToday = false;
    String openingTime = "Not available";
    String closingTime = "Not available";

    if (_storeTimings.containsKey(currentDay)) {
      final daySchedule = _storeTimings[currentDay];
      isOpenToday = daySchedule['isOpen'] ?? false;

      if (isOpenToday) {
        // Format open/close time
        final openHour = daySchedule['openTimeHour'] ?? 9;
        final openMinute = daySchedule['openTimeMinute'] ?? 0;
        final closeHour = daySchedule['closeTimeHour'] ?? 18;
        final closeMinute = daySchedule['closeTimeMinute'] ?? 0;

        final openTime = TimeOfDay(hour: openHour, minute: openMinute);
        final closeTime = TimeOfDay(hour: closeHour, minute: closeMinute);

        openingTime = _formatTimeOfDay(openTime);
        closingTime = _formatTimeOfDay(closeTime);
      }
    }

    // Build the status indicator
    return Row(
      children: [
        Icon(isOpenToday ? Icons.circle : Icons.circle_outlined,
            size: 10, color: isOpenToday ? Colors.green : Colors.red),
        const SizedBox(width: 8),
        Text(
          isOpenToday
              ? "Open today: $openingTime - $closingTime"
              : "Closed today",
          style: TextStyle(
            color: isOpenToday ? Colors.green[700] : Colors.red,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildOrderItems() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var item in widget.items) _buildOrderItem(item),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Items Total",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Display discounted subtotal if there are any discounts
                _totalDiscount > 0
                    ? Row(
                        children: [
                          Text(
                            _formatCurrency(_originalSubtotal),
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatCurrency(_subtotal),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _formatCurrency(_subtotal),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    // Get price as double for formatting
    double originalPrice = _getPriceAsDouble(item['price']);
    double discountedPrice = _getDiscountedPrice(item);
    bool hasDiscount =
        item.containsKey('hasDiscount') && item['hasDiscount'] == true;
    int quantity = item['quantity'] ?? 1;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item['image'],
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[300],
                  child:
                      Icon(Icons.image_not_supported, color: Colors.grey[500]),
                );
              },
            ),
          ),
          const SizedBox(width: 16),

          // Food details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: item['isVegetarian'] == true
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.circle,
                        color: item['isVegetarian'] == true
                            ? Colors.green
                            : Colors.red,
                        size: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item['category'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Price and quantity information
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (hasDiscount) ...[
                      Row(
                        children: [
                          Text(
                            '₹${originalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${discountedPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        '₹${originalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Qty: $quantity",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Delivery form with preparation time and expected delivery time
  Widget _buildDeliveryForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preparation time info
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: Theme.of(context).primaryColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                "Preparation Time: $_preparationTime minutes",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          // Expected delivery time
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 8, bottom: 16),
            child: _buildEstimatedDeliveryTime(),
          ),

          // Divider
          const Divider(thickness: 1),
          const SizedBox(height: 16),

          // Delivery time options header
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: Theme.of(context).primaryColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                "Adjust Delivery Time",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Delivery time options - based on store hours
          _buildDeliveryTimeOptions(),
        ],
      ),
    );
  }

  // NEW: Widget to display the estimated delivery time
  Widget _buildEstimatedDeliveryTime() {
    // Calculate expected delivery time based on current time and preparation time
    final now = DateTime.now();
    final estimatedDelivery = now.add(Duration(minutes: _preparationTime));
    final formattedTime = DateFormat('hh:mm a').format(estimatedDelivery);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delivery_dining, color: Colors.green[700], size: 20),
          const SizedBox(width: 8),
          Text(
            "Expected by $formattedTime",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Delivery time options
  Widget _buildDeliveryTimeOptions() {
    // Create delivery options based on preparation time
    final now = DateTime.now();

    // Default option is the minimum preparation time
    List<Map<String, dynamic>> deliveryOptions = [
      {
        'label': 'As soon as possible',
        'time': DateFormat('hh:mm a')
            .format(now.add(Duration(minutes: _preparationTime))),
        'value': 'As soon as possible'
      },
    ];

    // Add additional time options
    deliveryOptions.addAll([
      {
        'label': '+15 minutes',
        'time': DateFormat('hh:mm a')
            .format(now.add(Duration(minutes: _preparationTime + 15))),
        'value': 'In ${_preparationTime + 15} minutes'
      },
      {
        'label': '+30 minutes',
        'time': DateFormat('hh:mm a')
            .format(now.add(Duration(minutes: _preparationTime + 30))),
        'value': 'In ${_preparationTime + 30} minutes'
      },
      {
        'label': '+1 hour',
        'time': DateFormat('hh:mm a')
            .format(now.add(Duration(minutes: _preparationTime + 60))),
        'value': 'In ${_preparationTime + 60} minutes'
      },
    ]);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          deliveryOptions.map((option) => _buildTimeOption(option)).toList(),
    );
  }

  // UPDATED: Time option widget
  Widget _buildTimeOption(Map<String, dynamic> option) {
    final isSelected = _deliveryTime == option['value'];

    return GestureDetector(
      onTap: () {
        setState(() {
          _deliveryTime = option['value'];
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withAlpha(76),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Theme.of(context).primaryColor,
                      size: 12,
                    ),
                  ),
                if (isSelected) const SizedBox(width: 6),
                Text(
                  option['label'],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[800],
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              option['time'],
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UPDATED: Payment method with UPI app selection
  // Replace your _buildPaymentMethod method with this:

  Widget _buildPaymentMethod() {
    if (_isLoadingUpiApps) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 8),
              CircularProgressIndicator(color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              Text("Loading payment options...",
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment,
                color: Theme.of(context).primaryColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                "Select Payment App",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Check if UPI apps were detected
          if (_upiApps != null && _upiApps!.isNotEmpty)
            _buildUpiAppOptions()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Unable to detect UPI apps automatically",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Select from common UPI apps:",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                _buildManualUpiAppSelection(),
              ],
            ),
        ],
      ),
    );
  }

  // UPDATED: UPI app options widget - fixed icon issue
  Widget _buildUpiAppOptions() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _upiApps!.length,
      itemBuilder: (context, index) {
        final app = _upiApps![index];
        final isSelected = _selectedUpiApp == app.upiApplication.toString();

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedUpiApp = app.upiApplication.toString();
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon - using iconImage method instead of icon property
                Container(
                  padding: const EdgeInsets.all(8),
                  child: app.iconImage(40),
                ),
                const SizedBox(height: 4),
                // App name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    app.upiApplication.getAppName(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Selected indicator
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                    size: 16,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Improved notes field
  Widget _buildNotesField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notes header
          Row(
            children: [
              Icon(
                Icons.note_alt_outlined,
                color: Theme.of(context).primaryColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                "Add Special Instructions",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Notes text field with improved styling
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: 4,
              style: const TextStyle(
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: "Any specific preferences or requests...",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                contentPadding: const EdgeInsets.all(16),
                border: InputBorder.none,
              ),
            ),
          ),

          // Helper text
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              "For example: No spices, extra sauce, etc.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Display original subtotal and discount if applicable
          if (_totalDiscount > 0) ...[
            _buildPriceRow(
                "Original Subtotal", _formatCurrency(_originalSubtotal)),
            const SizedBox(height: 8),
            _buildPriceRow("Discount", "- ${_formatCurrency(_totalDiscount)}",
                valueColor: Colors.green[700]),
            const SizedBox(height: 8),
            _buildPriceRow("Subtotal", _formatCurrency(_subtotal)),
          ] else ...[
            _buildPriceRow("Subtotal", _formatCurrency(_subtotal)),
          ],

          const SizedBox(height: 8),
          _buildPriceRow("Tax (5%)", _formatCurrency(_tax)),
          const SizedBox(height: 8),
          _buildPriceRow("Platform Charge", _formatCurrency(_platformcharge)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(thickness: 1),
          ),
          _buildPriceRow(
            "Total Amount",
            _formatCurrency(_total),
            isTotal: true,
          ),
          // Display savings if applicable
          if (_totalDiscount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.savings, color: Colors.green[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "You saved ${_formatCurrency(_totalDiscount)} on this order!",
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount,
      {bool isTotal = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 18 : 16,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 18 : 16,
            color: isTotal ? Theme.of(context).primaryColor : valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceOrderBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Order details summary
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${widget.items.length} ${widget.items.length == 1 ? 'item' : 'items'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Show savings below total if discount exists
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total: ${_formatCurrency(_total)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      if (_totalDiscount > 0)
                        Text(
                          "Saved: ${_formatCurrency(_totalDiscount)}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green[700],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Place order button - UPDATED to start UPI payment
            ElevatedButton(
              onPressed: !_isProcessing && _selectedUpiApp != null
                  ? () => _initiatePayment()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Pay Now",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // UPDATED: Initiate UPI payment (fixed UpiApplication.values issue)
  // Replace your _initiatePayment method with this:

  Future<void> _initiatePayment() async {
    if (_selectedUpiApp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment app')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Create the order in Firebase first
    final String orderId = await _createOrder();

    try {
      UpiApplication? selectedUpiApp;

      // Check if we're using automatically discovered apps
      if (_upiApps != null && _upiApps!.isNotEmpty) {
        // Try to find the selected app
        final selectedApp = _upiApps!.firstWhere(
          (app) => app.upiApplication.toString() == _selectedUpiApp,
          orElse: () => _upiApps![0], // Default to first app if not found
        );

        selectedUpiApp = selectedApp.upiApplication;
      } else {
        // We're using manual selection, determine the app by package name
        if (_selectedUpiApp == 'com.google.android.apps.nbu.paisa.user') {
          selectedUpiApp = UpiApplication.googlePay;
        } else if (_selectedUpiApp == 'com.phonepe.app') {
          selectedUpiApp = UpiApplication.phonePe;
        } else if (_selectedUpiApp == 'net.one97.paytm') {
          selectedUpiApp = UpiApplication.paytm;
        } else if (_selectedUpiApp == 'in.amazon.mShop.android.shopping') {
          selectedUpiApp = UpiApplication.amazonPay;
        } else if (_selectedUpiApp == 'in.org.npci.upiapp') {
          selectedUpiApp = UpiApplication.bhim;
        } else {
          // Default to Google Pay
          selectedUpiApp = UpiApplication.googlePay;
        }
      }

      // Create UPI Payment request
      final UpiTransactionResponse response = await upiPay.initiateTransaction(
        amount: _total.toString(),
        app: selectedUpiApp,
        receiverName: 'Canteen', // Name of merchant
        receiverUpiAddress: 'canteen@ybl', // Merchant UPI ID
        transactionRef: orderId,
        transactionNote: 'Order #$orderId',
      );

      // Handle response
      _handlePaymentResponse(response, orderId);
    } catch (e) {
      print('Error initiating payment: $e');

      // Show error dialog
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${e.toString()}')),
        );
      }
    }
  }

  // NEW: Create order in Firebase and return order ID
  Future<String> _createOrder() async {
    // Get the selected UPI application info
    final selectedApp = _upiApps!.firstWhere(
      (app) => app.upiApplication.toString() == _selectedUpiApp,
      orElse: () => _upiApps![0], // Default to first app if not found
    );

    // Create order data
    final orderData = {
      'orderId': _orderId,
      'items': widget.items,
      'timestamp': _orderTimestamp,
      'notes': _notesController.text,
      'deliveryTime': _deliveryTime,
      'subtotal': _subtotal,
      'tax': _tax,
      'platformCharge': _platformcharge,
      'totalAmount': _total,
      'discount': _totalDiscount,
      'paymentMethod': 'UPI',
      'paymentDetails': {
        'upiApp': selectedApp.upiApplication.getAppName(),
        'status': 'pending', // Will be updated after payment is complete
      },
      'storeId': widget.items[0]['storeId'], // Store ID
      'userId': 'navin280123', // Current user
      'status': 'pending',
    };

    try {
      // Save order to Firebase
      await FirebaseDatabase.instance
          .ref()
          .child(widget.items[0]['storeId'])
          .child('orders')
          .child(_orderId)
          .set(orderData);

      return _orderId;
    } catch (e) {
      print('Error creating order: $e');
      rethrow; // Re-throw to handle in the calling function
    }
  }

  // NEW: Handle payment response
  void _handlePaymentResponse(UpiTransactionResponse response, String orderId) {
    setState(() {
      _isProcessing = false;
    });

    // Update order status in Firebase based on payment status
    final orderRef = FirebaseDatabase.instance
        .ref()
        .child(widget.items[0]['storeId'])
        .child('orders')
        .child(orderId);

    switch (response.status) {
      case UpiTransactionStatus.success:
        // Update order status to paid
        orderRef.update({
          'status': 'confirmed',
          'paymentDetails.status': 'completed',
          'paymentDetails.transactionId': response.txnId ?? '',
          'paymentDetails.approvalRefNo': response.approvalRefNo ?? '',
        });

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildSuccessDialog(response),
        );
        break;

      case UpiTransactionStatus.failure:
        // Update order status to payment failed
        orderRef.update({
          'status': 'payment_failed',
          'paymentDetails.status': 'failed',
          'paymentDetails.failureReason': response.txnRef ?? 'Payment failed',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Payment failed: ${response.txnRef ?? "Unknown error"}')),
        );
        break;

      case UpiTransactionStatus.submitted:
        // Payment is pending
        orderRef.update({
          'status': 'payment_pending',
          'paymentDetails.status': 'pending',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Payment submitted and pending confirmation')),
        );
        break;

      default:
        // Payment was not completed
        orderRef.update({
          'status': 'payment_cancelled',
          'paymentDetails.status': 'cancelled',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment cancelled or returned')),
        );
    }
  }

  // UPDATED: Success dialog with payment details
  Widget _buildSuccessDialog([UpiTransactionResponse? response]) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[700],
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Order Placed Successfully!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "Your order #${_orderId} has been successfully placed and will be delivered soon.",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),

            // Show payment details if available
            if (response != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Payment Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (response.txnId != null)
                      _buildInfoRow("Transaction ID", response.txnId!),
                    if (response.approvalRefNo != null)
                      _buildInfoRow("Reference No", response.approvalRefNo!),
                    _buildInfoRow("Amount", _formatCurrency(_total)),
                  ],
                ),
              ),
            ],

            if (_totalDiscount > 0) ...[
              const SizedBox(height: 6.0),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.savings, color: Colors.green[700], size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "You saved ${_formatCurrency(_totalDiscount)}!",
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => const MyOrdersScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Track Order",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Return to previous screen
              },
              child: const Text(
                "Back to Menu",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Helper method for payment details in success dialog
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper extension for UPI app names is already part of the package
