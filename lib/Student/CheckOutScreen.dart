import 'package:canteen/Student/MyOrdersScreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  
  // Current timestamp and username - using the provided details
  final String _orderTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  final String _username = 'navin280123';
  
  // Form is always considered complete now that we've removed required fields
  bool get _isFormComplete => true;

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
      body: widget.items.isEmpty
          ? _buildEmptyCart()
          : _buildCheckoutContent(),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // Bottom padding for place order button
          children: [
            // Order ID and timestamp - Fixed responsive layout
            _buildOrderHeader(),
            const SizedBox(height: 24),
            
            // Order summary section
            _buildSectionTitle("Order Summary"),
            const SizedBox(height: 8),
            _buildOrderItems(),
            const SizedBox(height: 24),
            
            // Delivery details section - Simplified
            _buildSectionTitle("Delivery Details"),
            const SizedBox(height: 8),
            _buildDeliveryForm(),
            const SizedBox(height: 24),
            
            // Payment method section - UPI Only
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
        ],
      ),
    );
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
                            style: TextStyle(
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
    bool hasDiscount = item.containsKey('hasDiscount') && item['hasDiscount'] == true;
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
                  child: Icon(Icons.image_not_supported, color: Colors.grey[500]),
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
                        color: item['isVegetarian'] == true ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.circle,
                        color: item['isVegetarian'] == true ? Colors.green : Colors.red,
                        size: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                            style: TextStyle(
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
          // Delivery time options header with icon
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: Theme.of(context).primaryColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                "Preferred Delivery Time",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Delivery time options
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildTimeOption("As soon as possible"),
              _buildTimeOption("In 30 minutes"),
              _buildTimeOption("In 1 hour"),
              _buildTimeOption("Schedule for later"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOption(String time) {
    final isSelected = _deliveryTime == time;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _deliveryTime = time;
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) 
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
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
              time,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simplified payment method - UPI only
  Widget _buildPaymentMethod() {
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
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          // UPI Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // UPI Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pay with UPI",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Google Pay, PhonePe, Paytm, and more",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Selected indicator
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
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
              style: TextStyle(
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
            _buildPriceRow("Original Subtotal", _formatCurrency(_originalSubtotal)),
            const SizedBox(height: 8),
            _buildPriceRow(
              "Discount", 
              "- ${_formatCurrency(_totalDiscount)}", 
              valueColor: Colors.green[700]
            ),
            const SizedBox(height: 8),
            _buildPriceRow("Subtotal", _formatCurrency(_subtotal)),
          ] else ...[
            _buildPriceRow("Subtotal", _formatCurrency(_subtotal)),
          ],
          
          const SizedBox(height: 8),
          _buildPriceRow("Tax (5%)", _formatCurrency(_tax)),
          const SizedBox(height: 8),
          _buildPriceRow("Platform CHarge", _formatCurrency(_platformcharge)),
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

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false, Color? valueColor}) {
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
            
            // Place order button
            ElevatedButton(
              onPressed: !_isProcessing ? () => _placeOrder() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                        Text(
                          "Place Order",
                          style: const TextStyle(
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

  void _placeOrder() {
    setState(() {
      _isProcessing = true;
    });

    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildSuccessDialog(),
        );
      }
    });
  }

  Widget _buildSuccessDialog() {
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
            if (_totalDiscount > 0) ...[
              const SizedBox(height: 16),
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
                  MaterialPageRoute(builder: (context) => MyOrdersScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Track Order",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white
                ),
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
}