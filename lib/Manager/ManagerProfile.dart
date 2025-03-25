import 'package:canteen/Firebase/FirebaseManager.dart';
import 'package:canteen/Login/loginscreen.dart';
import 'package:canteen/Manager/ManagerChangePassword.dart';
import 'package:canteen/Manager/ManagerManageMenu.dart';
import 'package:canteen/Manager/ManagerOperatingHours.dart';
import 'package:canteen/Manager/ManagerPaymentMethods.dart';
import 'package:canteen/Manager/ManagerSelectLanguage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'edit_profile_screen.dart';
import 'dart:io';

class ManagerProfile extends StatefulWidget {
  const ManagerProfile({Key? key}) : super(key: key);

  @override
  _ManagerProfileState createState() => _ManagerProfileState();
}

class _ManagerProfileState extends State<ManagerProfile>
    with SingleTickerProviderStateMixin {
  // Profile data
  Map<String, String> profileData = {
    'name': 'John Manager',
    'email': 'john.manager@example.com',
    'phone': '+1 123-456-7890',
    'canteen': 'Main Campus Canteen',
    'role': 'Canteen Manager',
  };
  
   File? _profileImage;
  late TabController _tabController;
  bool _isLoading = true;
  // ignore: unused_field
  int _selectedTabIndex = 0;

  // Modern color scheme
  final Color _primaryColor = const Color(0xFF1E88E5);
  final Color _accentColor = const Color(0xFF26C6DA);
  final Color _backgroundColor = const Color(0xFFF5F7FA);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF2D3748);
  final Color _subtitleColor = const Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
     

    // Set system UI overlay style for better integration
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: _backgroundColor,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  Future<void> _fetchUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
       await Future.delayed(const Duration(seconds: 2));
      setState(() {
        profileData = {
          'name': prefs.getString('name') ?? 'Not Available',
          'email': prefs.getString('email') ?? 'john.manager@example.com',
          'phone': prefs.getString('phone') ?? 'Not Available',
          'university': prefs.getString('university') ?? 'Main Campus Canteen',
          'role': prefs.getString('role') ?? 'CANTEEN MANAGER',
          'location': prefs.getString('location')?? 'Not Available',
          'createdAt': prefs.getString('createdAt')?? 'Not Available',
          'profileImageUrl': prefs.getString('profileImageUrl')?? '',
        };
        _isLoading = false;
      });
    } catch (e) {
       await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
 @override
Widget build(BuildContext context) {
  return Theme(
    data: ThemeData(
      primaryColor: _primaryColor,
      colorScheme: ColorScheme.light(
        primary: _primaryColor,
        secondary: _accentColor,
        surface: _backgroundColor,
      ),
      scaffoldBackgroundColor: _backgroundColor,
    ),
    child: Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600), // Smooth transition effect
        switchInCurve: Curves.easeInOut, // In animation curve
        switchOutCurve: Curves.easeInOut, // Out animation curve
        child: _isLoading 
          ? _buildLoadingState() // Show shimmer effect
          : _buildBody(), // Fade in actual content
      ),
    ),
  );
}


Widget _buildLoadingState() {
  return SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          // Profile Header Shimmer
          _buildShimmerBox(height: 150, width: double.infinity, borderRadius: 24),
          const SizedBox(height: 24),

          // Tab Bar Shimmer
          Row(
            children: List.generate(2, (index) {
              return Expanded(
                child: _buildShimmerBox(height: 48, width: double.infinity, borderRadius: 12),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Profile Info Section
          _buildShimmerProfileInfo(),
          const SizedBox(height: 24),

          // Action Buttons Shimmer
          _buildShimmerActions(),
          const SizedBox(height: 24),

          // Settings List Shimmer
          _buildShimmerSettings(),
        ],
      ),
    ),
  );
}

/// Generic Shimmer Box with Slow Effect
Widget _buildShimmerBox({required double height, required double width, double borderRadius = 8}) {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.white,
      ),
    ),
  );
}

/// Shimmer for Profile Info (Name, Role, Canteen)
Widget _buildShimmerProfileInfo() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildShimmerBox(height: 20, width: 180), // Name
      const SizedBox(height: 8),
      _buildShimmerBox(height: 16, width: 120), // Role
      const SizedBox(height: 8),
      _buildShimmerBox(height: 14, width: 200), // Canteen
    ],
  );
}


/// Shimmer for Action Buttons (Edit, Settings, Logout)
Widget _buildShimmerActions() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: List.generate(3, (index) {
      return _buildShimmerBox(height: 40, width: 100, borderRadius: 20);
    }),
  );
}

/// Shimmer for Settings List
Widget _buildShimmerSettings() {
  return Column(
    children: List.generate(3, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildShimmerBox(height: 60, width: double.infinity, borderRadius: 16),
      );
    }),
  );
}


  Widget _buildBody() {
    return SafeArea(
      child: RefreshIndicator(
        color: _primaryColor,
        onRefresh: () async {
          setState(() {
            _isLoading = true;
          });
          await _fetchUserData();
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
Widget _buildProfileHeader() {
  return SliverToBoxAdapter(
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 800), 
      opacity: _isLoading ? 0.0 : 1.0, // Only fade in after loading
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditProfileScreen(profileData: profileData, profileImage: _profileImage)),
          );
          if (result != null && result.containsKey('profileData')) {
            setState(() {
              profileData = result['profileData'];
              if (result.containsKey('profileImage') && result['profileImage'] != null) {
                _profileImage = result['profileImage'];
              }
            });
          }
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, _primaryColor.withAlpha(204)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: _primaryColor.withAlpha(76), blurRadius: 12, spreadRadius: 0, offset: const Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Hero(
                  tag: 'profile_image',
                  child: CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white,
                  backgroundImage: profileData.containsKey('profileImageUrl') && profileData['profileImageUrl']!.isNotEmpty
                    ? NetworkImage(profileData['profileImageUrl']!)
                    : (_profileImage != null ? FileImage(_profileImage!) : null) as ImageProvider?,
                  child: (profileData['profileImageUrl'] == null || profileData['profileImageUrl']!.isEmpty) && _profileImage == null
                    ? Text(
                      profileData['name']!.substring(0, 1),
                      style: TextStyle(fontSize: 28, color: _primaryColor, fontWeight: FontWeight.bold),
                      )
                    : null,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        profileData['name']!,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Role
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          profileData['role']!.toUpperCase(),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Canteen Info (NEWLY ADDED)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined, // Canteen icon
                            color: Colors.white.withAlpha(229),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              profileData['university']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withAlpha(229),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}



  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        Container(
          color: _backgroundColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Backdrop with extra depth
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(20),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: _primaryColor.withAlpha(12),
                        blurRadius: 12,
                        spreadRadius: 0,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),

                // Animated Tab Bar
                AnimatedBuilder(
                  animation: _tabController.animation!,
                  builder: (context, child) {
                    return TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: _subtitleColor,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      labelPadding: const EdgeInsets.symmetric(vertical: 10),
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            _primaryColor,
                            Color.lerp(_primaryColor, _accentColor, 0.6)!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withAlpha(76),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      dividerColor: Colors.transparent,
                      splashBorderRadius: BorderRadius.circular(12),
                      overlayColor: WidgetStateProperty.resolveWith<Color?>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.hovered)) {
                            return _primaryColor.withAlpha(10);
                          }
                          if (states.contains(WidgetState.pressed)) {
                            return _primaryColor.withAlpha(25);
                          }
                          return null;
                        },
                      ),
                      tabs: [
                        _buildTabItem(
                          icon: Icons.person_outline,
                          text: "Profile Info",
                          isSelected: _tabController.index == 0,
                          animationValue:
                              1.0 - (_tabController.animation!.value),
                        ),
                        _buildTabItem(
                          icon: Icons.settings_outlined,
                          text: "Management",
                          isSelected: _tabController.index == 1,
                          animationValue: _tabController.animation!.value,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Helper method to build animated tab items
  Widget _buildTabItem({
    required IconData icon,
    required String text,
    required bool isSelected,
    required double animationValue,
  }) {
    return Tab(
      height: 44,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isSelected ? 1.0 : 0.8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.9,
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, size: 20),
            ),
            SizedBox(width: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 14 : 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: isSelected ? 0.2 : 0.0,
                color: isSelected ? Colors.white : _subtitleColor,
              ),
              child: Text(text),
            ),
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
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildInfoCard(),
        const SizedBox(height: 16),
        _buildAccountActions(),
      ],
    );
  }

  Widget _buildInfoCard() {
  return Card(
    margin: EdgeInsets.zero,
    color: _cardColor,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: Colors.grey.shade100),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            Icons.email_outlined,
            'Email',
            profileData['email']!,
            Colors.blue.shade700,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.phone_outlined,
            'Phone',
            profileData['phone']!,
            Colors.green.shade700,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.location_on_outlined,
            'Address',
            profileData['location']!,
            Colors.orange.shade700,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.schedule_outlined,
            'Working Hours',
            'Mon-Fri, 8:00 AM - 5:00 PM',
            Colors.purple.shade700,
          ),
        ],
      ),
    ),
  );
}

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
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
                  color: _subtitleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountActions() {
    final settingsItems = [
      {
        'icon': Icons.lock_outline,
        'title': 'Change Password',
        'subtitle': 'Update your security credentials',
        'color': Colors.blue.shade700,
        'onTap': () {
          // Handle change password
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ManagerChangePassword()),
          );
        },
      },
      {
        'icon': Icons.language_outlined,
        'title': 'Language',
        'subtitle': 'Change your preferred language',
        'color': Colors.green.shade700,
        'onTap': () {
          // Handle language settings
          Navigator.push(
            context,
            // MaterialPageRoute(builder: (context) => LanguageSettingsScreen()),
            MaterialPageRoute(builder: (context) => ManagerSelectLanguage()),
          );
        },
      },
      {
        'icon': Icons.logout,
        'title': 'Logout',
        'subtitle': 'Sign out from your account',
        'color': Colors.red.shade700,
        'onTap': () async {
          // Show confirmation dialog
          bool confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Logout', style: TextStyle(color: _textColor)),
                  content: Text(
                    'Are you sure you want to logout from your account?',
                    style: TextStyle(color: _subtitleColor),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: _subtitleColor),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ) ??
              false;

          if (confirm) {
            await FirebaseManager().logout();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen()),
            );
          }
        },
      },
    ];

    return Card(
      margin: EdgeInsets.zero,
      color: _cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(settingsItems.length, (index) {
              final item = settingsItems[index];
              return Column(
                children: [
                  _buildSettingsTile(
                    item['icon'] as IconData,
                    item['title'] as String,
                    item['subtitle'] as String,
                    color: item['color'] as Color,
                    onTap: item['onTap'] as VoidCallback,
                  ),
                  if (index < settingsItems.length - 1)
                    const Divider(height: 16),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle, {
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: _textColor,
          fontSize: 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            color: _subtitleColor,
            fontSize: 14,
          ),
        ),
      ),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.arrow_forward_ios,
          color: _subtitleColor,
          size: 14,
        ),
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
            'badgeColor': Colors.green,
            'iconColor': Colors.orange.shade700,
            'onTap': () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManagerManageMenu()),
              );
            },
          },
        ],
      },
      {
        'title': 'Staff & Operations',
        'options': [
          {
            'icon': Icons.schedule_outlined,
            'title': 'Operating Hours',
            'subtitle': 'Set canteen operating hours',
            'iconColor': Colors.indigo.shade700,
            'onTap': () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ManagerOperatingHours()),
              );
            },
          },
          {
            'icon': Icons.payments_outlined,
            'title': 'Payment Methods',
            'subtitle': 'Configure accepted payment options',
            'badge': '5 methods',
            'badgeColor': Colors.teal,
            'iconColor': Colors.teal.shade700,
            'onTap': () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ManagerPaymentMethods()),
              );
            },
          },
        ],
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: managementCategories.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, categoryIndex) {
        final category = managementCategories[categoryIndex];
        final options = category['options'] as List;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                category['title'] as String,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
            ),
            Card(
              margin: EdgeInsets.zero,
              color: _cardColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey.shade100),
              ),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 76,
                  endIndent: 16,
                  color: Colors.grey.shade200,
                ),
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
    final Color iconColor = option['iconColor'] as Color? ?? _primaryColor;
    final Color badgeColor = option['badgeColor'] as Color? ?? _accentColor;
    final VoidCallback onTap = option['onTap'] as VoidCallback;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(25),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          option['icon'] as IconData,
          color: iconColor,
          size: 26,
        ),
      ),
      title: Text(
        option['title'] as String,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: _textColor,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          option['subtitle'] as String,
          style: TextStyle(
            color: _subtitleColor,
            fontSize: 14,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (option.containsKey('badge'))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withAlpha(25),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: badgeColor.withAlpha(102),
                  width: 1,
                ),
              ),
              child: Text(
                option['badge'] as String,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.arrow_forward_ios,
              color: _subtitleColor,
              size: 14,
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget _widget;

  _SliverAppBarDelegate(this._widget);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _widget;
  }

  @override
  double get maxExtent => kToolbarHeight + 16;

  @override
  double get minExtent => kToolbarHeight + 16;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
