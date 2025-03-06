import 'package:flutter/material.dart';
// Removing unused import or we would need to add this to pubspec.yaml
// import 'package:fl_chart/fl_chart.dart';

class ManagerReport extends StatefulWidget {
  @override
  _ManagerReportState createState() => _ManagerReportState();
}

class _ManagerReportState extends State<ManagerReport> {
  String selectedTimeFrame = 'Weekly';
  List<String> timeFrames = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales Reports',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<String>(
                value: selectedTimeFrame,
                icon: Icon(Icons.arrow_drop_down),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedTimeFrame = newValue;
                    });
                  }
                },
                items: timeFrames.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 300,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(26), // Fixed: Changed withOpacity to withAlpha
                  spreadRadius: 1,
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Text(
                "Sales Chart Would Go Here\n(Requires fl_chart package)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          SizedBox(height: 30),
          Text(
            'Top Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildCategoryStats(),
          SizedBox(height: 30),
          _buildReportActions(),
        ],
      ),
    );
  }
  
  Widget _buildCategoryStats() {
    final categories = [
      {'name': 'Fast Food', 'sales': 'Rs. 5,200', 'percentage': 45},
      {'name': 'Beverages', 'sales': 'Rs. 3,100', 'percentage': 27},
      {'name': 'Desserts', 'sales': 'Rs. 2,500', 'percentage': 21},
      {'name': 'Main Course', 'sales': 'Rs. 800', 'percentage': 7},
    ];
    
    return Column(
      children: categories.map((category) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category['name'] as String, // Fixed: Explicit casting
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    category['sales'] as String, // Fixed: Explicit casting
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: (category['percentage'] as int) / 100, // Fixed: Explicit casting
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 4),
              Text(
                '${category['percentage']}% of total sales',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildReportActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.print,
          label: 'Print',
          onPressed: () {
            // Handle print action
          },
        ),
        _buildActionButton(
          icon: Icons.share,
          label: 'Share',
          onPressed: () {
            // Handle share action
          },
        ),
        _buildActionButton(
          icon: Icons.download,
          label: 'Download',
          onPressed: () {
            // Handle download action
          },
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}