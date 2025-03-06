import 'package:flutter/material.dart';

class ManagerHome extends StatefulWidget {
  final Function(int) updatePendingOrderCount;

  ManagerHome({required this.updatePendingOrderCount});

  @override
  _ManagerHomeState createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  // Sample data for quick statistics
  final Map<String, dynamic> statistics = {
    'Total Orders Today': 25,
    'Completed Orders': 20,
    'Pending Orders': 5,
    'Total Revenue': 'Rs. 3,500'
  };

  final List<Map<String, dynamic>> popularItems = [
    {
      "image": "assets/img/momo.jpeg",
      "name": "Momos",
      "sold": "32",
      "revenue": "Rs. 2,240"
    },
    {
      "image": "assets/img/pizza.jpeg",
      "name": "Pizza",
      "sold": "28",
      "revenue": "Rs. 3,080"
    },
    {
      "image": "assets/img/fried_rice.jpeg",
      "name": "Fried Rice",
      "sold": "25",
      "revenue": "Rs. 1,500"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildQuickStats(),
          SizedBox(height: 30),
          Text(
            'Popular Items',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildPopularItems(),
          SizedBox(height: 30),
          _buildAddNewItemButton(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: statistics.length,
      itemBuilder: (context, index) {
        String key = statistics.keys.elementAt(index);
        var value = statistics[key];
        
        IconData iconData;
        Color iconColor;
        
        switch (index) {
          case 0: // Total Orders Today
            iconData = Icons.shopping_bag;
            iconColor = Colors.blue;
            break;
          case 1: // Completed Orders
            iconData = Icons.check_circle;
            iconColor = Colors.green;
            break;
          case 2: // Pending Orders
            iconData = Icons.pending_actions;
            iconColor = Colors.orange;
            break;
          case 3: // Total Revenue
            iconData = Icons.attach_money;
            iconColor = Colors.purple;
            break;
          default:
            iconData = Icons.info;
            iconColor = Colors.blue;
        }
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(iconData, color: iconColor, size: 30),
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  key,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopularItems() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: popularItems.length,
      itemBuilder: (context, index) {
        final item = popularItems[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: EdgeInsets.all(10),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                item["image"],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              item["name"],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Sold: ${item["sold"]} units"),
            trailing: Text(
              item["revenue"],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddNewItemButton() {
    return Center(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add New Menu Item',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        onPressed: () {
          // Handle adding new menu item
        },
      ),
    );
  }
}