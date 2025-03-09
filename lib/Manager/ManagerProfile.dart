import 'package:canteen/Firebase/FirebaseManager.dart';
import 'package:canteen/Login/loginscreen.dart';
import 'package:canteen/Manager/ManagerManageMenu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ManagerProfile extends StatefulWidget {
  const ManagerProfile({Key? key}) : super(key: key);

  @override
  _ManagerProfileState createState() => _ManagerProfileState();
}

class _ManagerProfileState extends State<ManagerProfile> with SingleTickerProviderStateMixin {
  // Sample profile data
  final Map<String, String> profileData = {
    'name': 'John Manager',
    'email': 'john.manager@example.com',
    'phone': '+1 123-456-7890',
    'canteen': 'Main Campus Canteen',
    'role': 'Canteen Manager',
  };

  late TabController _tabController;
  final Color _primaryColor = const Color.fromARGB(102, 30, 136, 229);
  final Color _accentColor = const Color(0xFF26C6DA);

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
    return Theme(
      data: Theme.of(context).copyWith(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
      child: Scaffold(
        body: _buildBody(),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  

  Widget _buildBody() {
    return SafeArea(
      child: RefreshIndicator(
        color: _primaryColor,
        onRefresh: () async {
          // Simulate refreshing profile data
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildProfileHeader(),
            _buildTabBar(),
            _buildTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _showQuickActions(context);
      },
      backgroundColor: _accentColor,
      child: const Icon(Icons.add),
      tooltip: 'Quick Actions',
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionItem(
                  icon: Icons.restaurant_menu,
                  label: 'Add Menu Item',
                  onTap: () {
                    Navigator.pop(context);
                    // Add menu item logic
                  },
                ),
                _buildQuickActionItem(
                  icon: Icons.people_alt_outlined,
                  label: 'Add Staff',
                  onTap: () {
                    Navigator.pop(context);
                    // Add staff logic
                  },
                ),
                _buildQuickActionItem(
                  icon: Icons.local_offer_outlined,
                  label: 'New Offer',
                  onTap: () {
                    Navigator.pop(context);
                    // Add offer logic
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accentColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _accentColor, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
  return SliverToBoxAdapter(
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor.withAlpha(229), _primaryColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Hero(
                tag: 'profile_image',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51),
                        blurRadius: 6,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      profileData['name']!.substring(0, 1),
                      style: TextStyle(
                        fontSize: 40,
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Handle profile picture change
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51),
                        blurRadius: 6,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profileData['name']!,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              profileData['role']!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profileData['canteen']!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withAlpha(216),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: _primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _primaryColor,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Profile Info'),
            Tab(text: 'Management'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileInfoTab(),
          _buildManagementTab(),
        ],
      ),
    );
  }

  Widget _buildProfileInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard(),
        const SizedBox(height: 24),
        _buildAccountActions(),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: _primaryColor),
                  onPressed: () {
                    // Handle edit profile
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email_outlined, 'Email', profileData['email']!),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.phone_outlined, 'Phone', profileData['phone']!),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.location_on_outlined, 'Location', 'Main Campus, Building A'),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.schedule_outlined, 'Working Hours', 'Mon-Fri, 8:00 AM - 5:00 PM'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _primaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primaryColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              Icons.lock_outline,
              'Change Password',
              'Update your security credentials',
              onTap: () {
                // Handle change password
              },
            ),
            const Divider(height: 24),
            _buildSettingsTile(
              Icons.notifications_outlined,
              'Notifications',
              'Manage your notification preferences',
              onTap: () {
                // Handle notifications settings
              },
            ),
            const Divider(height: 24),
            _buildSettingsTile(
              Icons.language_outlined,
              'Language',
              'Change your preferred language',
              onTap: () {
                // Handle language settings
              },
            ),
            const Divider(height: 24),
            _buildSettingsTile(
              Icons.logout,
              'Logout',
              'Sign out from your account',
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () async{
                await FirebaseManager().logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? _primaryColor).withAlpha(25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? _primaryColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

 
  Widget _buildManagementTab() {
    final managementCategories = [
      {
        'title': 'Menu Management',
        'options': [
          {
            'icon': Icons.restaurant_menu,
            'title': 'Manage Menu Items',
            'subtitle': 'Add, edit or remove menu items',
            'badge': '45 items',
          },
          {
            'icon': Icons.category_outlined,
            'title': 'Menu Categories',
            'subtitle': 'Organize your menu categories',
            'badge': '8 categories',
          },
          {
            'icon': Icons.local_dining_outlined,
            'title': 'Special Dishes',
            'subtitle': 'Highlight special menu items',
            'badge': '3 specials',
          },
        ],
      },
      {
        'title': 'Staff & Operations',
        'options': [
          {
            'icon': Icons.people_outline,
            'title': 'Staff Management',
            'subtitle': 'Manage canteen staff and shifts',
            'badge': '12 staff',
          },
          {
            'icon': Icons.schedule_outlined,
            'title': 'Operating Hours',
            'subtitle': 'Set canteen operating hours',
          },
          {
            'icon': Icons.payments_outlined,
            'title': 'Payment Methods',
            'subtitle': 'Configure accepted payment options',
            'badge': '5 methods',
          },
        ],
      },
      {
        'title': 'Inventory & Offers',
        'options': [
          {
            'icon': Icons.inventory_2_outlined,
            'title': 'Inventory Management',
            'subtitle': 'Track and manage stock levels',
            'badge': 'Low stock',
            'badgeColor': Colors.orange,
          },
          {
            'icon': Icons.local_offer_outlined,
            'title': 'Special Offers',
            'subtitle': 'Create and manage promotions',
            'badge': '2 active',
          },
          {
            'icon': Icons.insert_chart_outlined,
            'title': 'Sales Analytics',
            'subtitle': 'View sales reports and insights',
          },
        ],
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: managementCategories.length,
      itemBuilder: (context, categoryIndex) {
        final category = managementCategories[categoryIndex];
        final options = category['options'] as List;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text(
                category['title'] as String,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
                itemBuilder: (context, index) {
                  final option = options[index] as Map;
                  return _buildManagementOption(option);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildManagementOption(Map option) {
    final Color badgeColor = option['badgeColor'] as Color? ?? _accentColor;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _primaryColor.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          option['icon'] as IconData,
          color: _primaryColor,
        ),
      ),
      title: Text(
        option['title'] as String,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(option['subtitle'] as String),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (option.containsKey('badge'))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                option['badge'] as String,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
      onTap: () {
        // Handle management option tap
        if (option['title'] == 'Manage Menu Items') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ManagerManageMenu()),
          );
        }
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}