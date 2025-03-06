import 'package:flutter/material.dart';

class ManagerOrderList extends StatefulWidget {
  @override
  _ManagerOrderListState createState() => _ManagerOrderListState();
}

class _ManagerOrderListState extends State<ManagerOrderList> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<Map<String, dynamic>> pendingOrders = [
    {
      'id': 'ORD-001',
      'customer': 'John Doe',
      'items': [
        {'name': 'Pizza', 'quantity': 2},
        {'name': 'Coke', 'quantity': 1},
      ],
      'total': 'Rs. 290',
      'time': '10:15 AM',
      'status': 'Pending'
    },
    {
      'id': 'ORD-002',
      'customer': 'Jane Smith',
      'items': [
        {'name': 'Momos', 'quantity': 1},
        {'name': 'Fried Rice', 'quantity': 1},
      ],
      'total': 'Rs. 130',
      'time': '10:30 AM',
      'status': 'Pending'
    },
    {
      'id': 'ORD-003',
      'customer': 'Mike Johnson',
      'items': [
        {'name': 'Ice Cream', 'quantity': 3},
      ],
      'total': 'Rs. 120',
      'time': '10:45 AM',
      'status': 'Pending'
    },
    {
      'id': 'ORD-004',
      'customer': 'Sarah Wilson',
      'items': [
        {'name': 'Momos', 'quantity': 2},
        {'name': 'Lassi', 'quantity': 2},
      ],
      'total': 'Rs. 300',
      'time': '11:00 AM',
      'status': 'Pending'
    },
    {
      'id': 'ORD-005',
      'customer': 'Alex Brown',
      'items': [
        {'name': 'Pizza', 'quantity': 1},
        {'name': 'Ice Cream', 'quantity': 1},
      ],
      'total': 'Rs. 150',
      'time': '11:15 AM',
      'status': 'Pending'
    },
  ];
  
  final List<Map<String, dynamic>> completedOrders = [
    {
      'id': 'ORD-101',
      'customer': 'Emily Davis',
      'items': [
        {'name': 'Pizza', 'quantity': 1},
        {'name': 'Coke', 'quantity': 1},
      ],
      'total': 'Rs. 145',
      'time': '09:15 AM',
      'status': 'Completed'
    },
    {
      'id': 'ORD-102',
      'customer': 'Robert Miller',
      'items': [
        {'name': 'Fried Rice', 'quantity': 2},
        {'name': 'Lassi', 'quantity': 2},
      ],
      'total': 'Rs. 280',
      'time': '09:30 AM',
      'status': 'Completed'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(
                text: 'Pending Orders (${pendingOrders.length})',
                icon: Icon(Icons.pending_actions),
              ),
              Tab(
                text: 'Completed Orders',
                icon: Icon(Icons.check_circle),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(pendingOrders, isPending: true),
              _buildOrderList(completedOrders, isPending: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, {required bool isPending}) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          isPending ? 'No pending orders' : 'No completed orders',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text(
              'Order #${order['id']}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${order['customer']} - ${order['time']}'),
            trailing: Text(
              order['total'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    ...order['items'].map<Widget>((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item['name']}'),
                            Text('x${item['quantity']}'),
                          ],
                        ),
                      );
                    }).toList(),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          order['total'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    if (isPending)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.check),
                            label: Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              _acceptOrder(order);
                            },
                          ),
                          ElevatedButton.icon(
                            icon: Icon(Icons.close),
                            label: Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              _rejectOrder(order);
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _acceptOrder(Map<String, dynamic> order) {
    setState(() {
      pendingOrders.remove(order);
      order['status'] = 'Completed';
      completedOrders.add(order);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ${order['id']} accepted'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectOrder(Map<String, dynamic> order) {
    setState(() {
      pendingOrders.remove(order);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ${order['id']} rejected'),
        backgroundColor: Colors.red,
      ),
    );
  }
}