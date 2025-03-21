import 'package:canteen/Student/MyOrdersScreen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Current timestamp
  final String _orderTimestamp =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  // Merchant UPI ID
  final String _merchantUpiId =
      '7004394490@ybl'; // Replace with your merchant ID
  final String _merchantName = 'Canteen';

  @override
  void initState() {
    super.initState();
    _fetchStoreData();
    _fetchMerchantUpiId();
  }

  _fetchMerchantUpiId() async {
    // final ref = FirebaseDatabase.instance.ref().child('merchant_upi_id');
    // final snapshot = await ref.get();
    // if (snapshot.exists) {
    //   setState(() {
    //     _merchantUpiId = snapshot.value as String;
    //   });
    // }
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
  leading: IconButton(
    icon: Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(50), // Light background for contrast
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
    ),
    onPressed: () => Navigator.of(context).pop(),
  ),
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
                    ? Colors.white.withOpacity(0.9)
                    : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UPDATED: Payment method with manual UPI app selection
  Widget _buildPaymentMethod() {
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
          _buildManualUpiAppSelection(),
        ],
      ),
    );
  }

  // NEW: Manual UPI app selection grid
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

  // Add this method to generate orderId without creating in Firebase
  String _generateOrderId() {
    final now = DateTime.parse(_orderTimestamp);
    final formatter = DateFormat('yyyyMMddHHmmss');
    return 'ORD-${formatter.format(now)}';
  }

  // NEW: Initiate direct UPI payment using URL schemes
  // Replace the _initiatePayment method with this improved version
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

    try {
      // Generate orderId but DON'T create in Firebase yet
      final String orderId = _generateOrderId();
      bool success = false;

      // Use app-specific approach based on selected app
      switch (_selectedUpiApp) {
        case 'com.google.android.apps.nbu.paisa.user':
          success = await _launchGooglePay(orderId, _total);
          break;
        case 'com.phonepe.app':
          success = await _launchPhonePe(orderId, _total);
          break;
        case 'net.one97.paytm':
          success = await _launchPaytm(orderId, _total);
          break;
        case 'in.amazon.mShop.android.shopping':
          success = await _launchAmazonPay(orderId, _total);
          break;
        case 'in.org.npci.upiapp':
          success = await _launchBhim(orderId, _total);
          break;
        default:
          // Use generic intent approach as fallback
          success = await _launchUpiApp(_selectedUpiApp!);
      }

      if (success) {
        // App launched successfully - show confirmation dialog
        if (mounted) {
          _showPaymentConfirmationDialog(orderId);
        }
      } else {
        // Try generic fallback approach
        final String upiUrl =
            "upi://pay?pa=${_merchantUpiId}&pn=${Uri.encodeComponent(_merchantName)}&tr=$orderId&am=${_total.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent('Order #$orderId')}";

        print('Trying fallback generic UPI URL: $upiUrl');

        final fallbackSuccess = await launchUrl(
          Uri.parse(upiUrl),
          mode: LaunchMode.externalApplication,
        );

        if (fallbackSuccess) {
          if (mounted) {
            _showPaymentConfirmationDialog(orderId);
          }
        } else {
          // All attempts failed
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Could not launch payment app. Please check if the app is installed or try another payment option.')),
            );
          }
        }
      }
    } catch (e) {
      print('Error initiating payment: $e');

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

// Specialized launcher for PhonePe
  Future<bool> _launchPhonePe(String orderId, double amount) async {
    try {
      final upiId = _merchantUpiId;
      final String formattedAmount = amount.toStringAsFixed(2);
      final merchant = Uri.encodeComponent(_merchantName);
      final note = Uri.encodeComponent("Order #$orderId");

      // PhonePe deep link format
      final url =
          "phonepe://pay?pa=$upiId&pn=$merchant&tr=$orderId&am=$formattedAmount&cu=INR&tn=$note";

      print('Launching PhonePe URL: $url');

      final uri = Uri.parse(url);
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Error launching PhonePe: $e');
      return false;
    }
  }

// Specialized launcher for Paytm
  Future<bool> _launchPaytm(String orderId, double amount) async {
    try {
      final upiId = _merchantUpiId;
      final String formattedAmount = amount.toStringAsFixed(2);
      final merchant = Uri.encodeComponent(_merchantName);
      final note = Uri.encodeComponent("Order #$orderId");

      // Paytm deep link format
      final url =
          "paytmmp://pay?pa=$upiId&pn=$merchant&tr=$orderId&am=$formattedAmount&cu=INR&tn=$note";

      print('Launching Paytm URL: $url');

      final uri = Uri.parse(url);
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Error launching Paytm: $e');
      return false;
    }
  }

// Specialized launcher for Amazon Pay
  Future<bool> _launchAmazonPay(String orderId, double amount) async {
    try {
      final upiId = _merchantUpiId;
      final String formattedAmount = amount.toStringAsFixed(2);
      final merchant = Uri.encodeComponent(_merchantName);
      final note = Uri.encodeComponent("Order #$orderId");

      // Amazon Pay deep link format
      final url =
          "amazonpay://pay?pa=$upiId&pn=$merchant&tr=$orderId&am=$formattedAmount&cu=INR&tn=$note";

      print('Launching Amazon Pay URL: $url');

      final uri = Uri.parse(url);
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Error launching Amazon Pay: $e');
      return false;
    }
  }

// Specialized launcher for BHIM UPI
  Future<bool> _launchBhim(String orderId, double amount) async {
    try {
      final upiId = _merchantUpiId;
      final String formattedAmount = amount.toStringAsFixed(2);
      final merchant = Uri.encodeComponent(_merchantName);
      final note = Uri.encodeComponent("Order #$orderId");

      // BHIM deep link format
      final url =
          "bhim://pay?pa=$upiId&pn=$merchant&tr=$orderId&am=$formattedAmount&cu=INR&tn=$note";

      print('Launching BHIM URL: $url');

      final uri = Uri.parse(url);
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Error launching BHIM: $e');
      return false;
    }
  }

  // Generate UPI deep link URL based on app and payment details
  // Improved UPI URL generation with better encoding
  String _generateUpiUrl(String orderId) {
    // Format amount with 2 decimal places, no comma separators
    final String formattedAmount = _total.toStringAsFixed(2);

    // Basic parameters required for UPI payment
    final Map<String, String> upiParams = {
      'pa': _merchantUpiId, // Payee address (merchant UPI ID)
      'pn': Uri.encodeComponent(_merchantName), // Encoded payee name
      'tn': Uri.encodeComponent('Order #$orderId'), // Encoded transaction note
      'am': formattedAmount, // Amount
      'cu': 'INR', // Currency (Indian Rupee)
      'tr': orderId, // Transaction reference ID
    };

    // Create URL based on selected app
    String baseUrl;
    switch (_selectedUpiApp) {
      case 'com.google.android.apps.nbu.paisa.user': // Google Pay
        baseUrl = 'upi://pay';
        break;
      case 'com.phonepe.app': // PhonePe
        baseUrl = 'phonepe://pay';
        break;
      case 'net.one97.paytm': // Paytm
        baseUrl = 'paytmmp://pay';
        break;
      case 'in.amazon.mShop.android.shopping': // Amazon Pay
        baseUrl = 'amazonpay://pay';
        break;
      case 'in.org.npci.upiapp': // BHIM
        baseUrl = 'bhim://pay';
        break;
      default: // Default to generic UPI URL
        baseUrl = 'upi://pay';
    }

    // Construct the URL manually to ensure proper encoding
    String url = baseUrl + '?';
    upiParams.forEach((key, value) {
      url += '$key=$value&';
    });

    // Remove trailing &
    return url.substring(0, url.length - 1);
  }

  // Helper to build a URL with query parameters
  String _buildUpiUrl(String baseUrl, Map<String, String> params) {
    final Uri uri = Uri.parse(baseUrl);
    final queryParams = Uri(queryParameters: params).query;
    return '${uri.toString()}?$queryParams';
  }

  // Launch the UPI app using the generated URL
  // Improved URL launcher with better debugging
// Improved URL launcher that uses Intent approach for Android
  Future<bool> _launchUpiApp(String upiUrl) async {
    try {
      // For direct apps, use package-specific intents instead of URL schemes
      if (_selectedUpiApp != null) {
        // Create an intent URL for Android
        final intentUrl = _createIntentUrl();

        print('Launching intent: $intentUrl');

        final uri = Uri.parse(intentUrl);
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        print('No UPI app selected');
        return false;
      }
    } catch (e) {
      print('Error launching UPI app: $e');
      return false;
    }
  }

// Specialized launcher for Google Pay (more reliable)
  Future<bool> _launchGooglePay(String orderId, double amount) async {
    try {
      final packageName = 'com.google.android.apps.nbu.paisa.user';
      final upiId = _merchantUpiId;
      final String formattedAmount = amount.toStringAsFixed(2);
      final merchant = Uri.encodeComponent(_merchantName);
      final note = Uri.encodeComponent("Order #$orderId");

      // Direct Google Pay URL format
      final url =
          "tez://upi/pay?pa=$upiId&pn=$merchant&tr=$orderId&am=$formattedAmount&cu=INR&tn=$note";

      print('Launching Google Pay URL: $url');

      final uri = Uri.parse(url);
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Error launching Google Pay: $e');
      return false;
    }
  }

// Creates an Android Intent URL instead of direct UPI URL
  String _createIntentUrl() {
    // Format amount properly
    final String formattedAmount = _total.toStringAsFixed(2);
    final String orderId = _generateOrderId();

    // The package to launch
    final String packageName = _selectedUpiApp!;

    // Create an Android intent URL with all necessary parameters
    String intentUrl = 'intent://#Intent;';

    // Add scheme
    intentUrl += 'scheme=upi;';

    // Add package
    intentUrl += 'package=$packageName;';

    // Add parameters as extras
    intentUrl += 'S.pa=${Uri.encodeComponent(_merchantUpiId)};';
    intentUrl += 'S.pn=${Uri.encodeComponent(_merchantName)};';
    intentUrl += 'S.tn=${Uri.encodeComponent("Order #$orderId")};';
    intentUrl += 'S.am=$formattedAmount;';
    intentUrl += 'S.cu=INR;';
    intentUrl += 'S.tr=$orderId;';

    // End intent
    intentUrl += 'end;';

    return intentUrl;
  }

  // Show dialog to confirm payment status
  // Updated to create Firebase order only on confirmed payment
  void _showPaymentConfirmationDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Status'),
        content: const Text(
          'Did you complete the payment successfully?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isProcessing = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment cancelled')),
              );
            },
            child: const Text('No, Failed'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Show loading indicator
              setState(() {
                _isProcessing = true;
              });

              try {
                // NOW create the order in Firebase
                await _createOrder(orderId, 'confirmed');

                // Show success dialog
                if (mounted) {
                  setState(() {
                    _isProcessing = false;
                  });
                  _showSuccessDialog(orderId);
                }
              } catch (e) {
                print('Error creating order: $e');
                if (mounted) {
                  setState(() {
                    _isProcessing = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error saving order: ${e.toString()}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Yes, Completed'),
          ),
        ],
      ),
    );
  }

  // Update order status in Firebase
  Future<void> _updateOrderStatus(
      String orderId, String status, String reason) async {
    try {
      final orderRef = FirebaseDatabase.instance
          .ref()
          .child(widget.items[0]['storeId'])
          .child('orders')
          .child(orderId);

      await orderRef.update({
        'status': status,
        'paymentDetails.status': status == 'confirmed' ? 'completed' : 'failed',
        'paymentDetails.notes': reason,
        'paymentDetails.updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  // NEW: Create order in Firebase and return order ID
  // Updated to accept status parameter and simplified
  Future<void> _createOrder(String orderId, String status) async {
    // Create order data
    final orderData = {
      'orderId': orderId,
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
        'upiApp': _getAppName(_selectedUpiApp!),
        'status': status == 'confirmed' ? 'completed' : 'pending',
        'updatedAt': DateTime.now().toIso8601String(),
      },
      'storeId': widget.items[0]['storeId'],
      'userId': 'navin280123', // Current user
      'status': "pending",
    };

    // Save order to Firebase
    await FirebaseDatabase.instance
        .ref()
        .child(widget.items[0]['storeId'])
        .child('orders')
        .child(orderId)
        .set(orderData);
  }

  // Helper to get app name from package
  String _getAppName(String packageName) {
    switch (packageName) {
      case 'com.google.android.apps.nbu.paisa.user':
        return 'Google Pay';
      case 'com.phonepe.app':
        return 'PhonePe';
      case 'net.one97.paytm':
        return 'Paytm';
      case 'in.amazon.mShop.android.shopping':
        return 'Amazon Pay';
      case 'in.org.npci.upiapp':
        return 'BHIM';
      default:
        return 'UPI App';
    }
  }

  // UPDATED: Success dialog with order details
  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
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
                "Your order #$orderId has been successfully placed and will be delivered soon.",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),

              // Show payment details
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
                    _buildInfoRow("Order ID", orderId),
                    _buildInfoRow(
                        "Payment Method", _getAppName(_selectedUpiApp!)),
                    _buildInfoRow("Amount", _formatCurrency(_total)),
                  ],
                ),
              ),

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
      ),
    );
  }

  // Helper method for payment details in success dialog
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
