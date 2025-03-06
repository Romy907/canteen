import 'package:flutter/material.dart';

class ManagerProfile extends StatefulWidget {
  @override
  _ManagerProfileState createState() => _ManagerProfileState();
}

class _ManagerProfileState extends State<ManagerProfile> {
  // Sample profile data
  Map<String, String> profileData = {
    'name': 'John Manager',
    'email': 'john.manager@example.com',
    'phone': '+1 123-456-7890',
    'canteen': 'Main Campus Canteen',
    'role': 'Manager',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          _buildProfileHeader(),
          SizedBox(height: 30),
          _buildInfoSection(),
          SizedBox(height: 30),
          _buildActionButtons(),
          SizedBox(height: 30),
          _buildManagementSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            profileData['name']!.substring(0, 1),
            style: TextStyle(
              fontSize: 40,
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 16),
        Text(
          profileData['name']!,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          profileData['role']!,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoItem(Icons.email, 'Email', profileData['email']!),
            Divider(),
            _buildInfoItem(Icons.phone, 'Phone', profileData['phone']!),
            Divider(),
            _buildInfoItem(Icons.store, 'Canteen', profileData['canteen']!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 28),
          SizedBox(width: 16),
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
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.edit,
          label: 'Edit Profile',
          onPressed: () {
            // Handle edit profile action
          },
        ),
        _buildActionButton(
          icon: Icons.lock,
          label: 'Change Password',
          onPressed: () {
            // Handle change password action
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

  Widget _buildManagementSection() {
    final managementOptions = [
      {
        'icon': Icons.restaurant_menu,
        'title': 'Manage Menu',
        'subtitle': 'Add, edit or remove menu items',
      },
      {
        'icon': Icons.group,
        'title': 'Staff Management',
        'subtitle': 'Manage canteen staff',
      },
      {
        'icon': Icons.settings,
        'title': 'Canteen Settings',
        'subtitle': 'Operating hours, payment methods',
      },
      {
        'icon': Icons.inventory,
        'title': 'Inventory',
        'subtitle': 'Manage stock and supplies',
      },
      {
        'icon': Icons.local_offer,
        'title': 'Special Offers',
        'subtitle': 'Create and manage promotions',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: managementOptions.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              final option = managementOptions[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Icon(
                    option['icon'] as IconData,
                    color: Colors.blue,
                  ),
                ),
                title: Text(option['title'] as String),
                subtitle: Text(option['subtitle'] as String),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  // Handle navigation to respective management screen
                  _handleManagementOptionTap(index);
                },
              );
            },
          ),
        ),
        SizedBox(height: 30),
        _buildSystemInfo(),
      ],
    );
  }

  Widget _buildSystemInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Canteen Management System',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Version 1.0.0',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Last Login: 2025-03-06 09:59:14',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'User ID: navin280123',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  void _handleManagementOptionTap(int index) {
    final options = [
      'Manage Menu',
      'Staff Management',
      'Canteen Settings',
      'Inventory',
      'Special Offers',
    ];
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to ${options[index]}'),
        duration: Duration(seconds: 1),
      ),
    );
    
    // Here you would typically navigate to the respective screen
    // Example:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => MenuManagementScreen()),
    // );
  }
}