import 'package:flutter/material.dart';
import 'dart:math' as math;

class ManagerManageMenu extends StatefulWidget {
  const ManagerManageMenu({Key? key}) : super(key: key);

  @override
  _ManagerManageMenuState createState() => _ManagerManageMenuState();
}

class _ManagerManageMenuState extends State<ManagerManageMenu> {
  final Color _primaryColor = const Color(0xFF1E88E5);
  final Color _accentColor = const Color(0xFF26C6DA);
  
  // Simulated data
  final List<String> _categories = [
    'All', 'Main Course', 'Appetizers', 'Beverages', 'Desserts', 'Sides'
  ];
  
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isGridView = false;
  
  // Sample menu items data
  List<Map<String, dynamic>> _menuItems = [];

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
    
    // Set current date and user info
    _currentDate = "2025-03-06 18:31:31";
    _currentUserLogin = "navin280123";
  }
  
  // Simulated data loading
  void _loadMenuItems() {
    _menuItems = List.generate(20, (index) {
      final random = math.Random();
      final categories = ['Main Course', 'Appetizers', 'Beverages', 'Desserts', 'Sides'];
      final category = categories[random.nextInt(categories.length)];
      
      return {
        'id': '${category.substring(0, 3).toUpperCase()}-${100 + index}',
        'name': _generateItemName(category, index),
        'price': (5 + random.nextDouble() * 15).toStringAsFixed(2),
        'category': category,
        'description': 'Delicious ${category.toLowerCase()} prepared with fresh ingredients.',
        'image': 'assets/food_${(index % 5) + 1}.jpg', // Placeholder for image path
        'available': random.nextBool(),
        'isVegetarian': random.nextBool(),
        'isPopular': random.nextInt(10) > 7,
        'lastUpdated': _currentDate,
      };
    });
  }
  
  // Helper to generate realistic food names
  String _generateItemName(String category, int index) {
    final mainCourses = ['Grilled Chicken', 'Pasta Carbonara', 'Beef Steak', 'Fish & Chips',
                         'Vegetable Curry', 'Mushroom Risotto', 'Chicken Burger', 'Lasagna'];
    final appetizers = ['Garlic Bread', 'Bruschetta', 'Mozzarella Sticks', 'Onion Rings',
                        'Spring Rolls', 'Chicken Wings', 'Caesar Salad', 'Soup of the Day'];
    final beverages = ['Fresh Orange Juice', 'Coffee', 'Iced Tea', 'Lemonade',
                       'Strawberry Shake', 'Mango Smoothie', 'Hot Chocolate', 'Sparkling Water'];
    final desserts = ['Chocolate Cake', 'Ice Cream', 'Apple Pie', 'Tiramisu',
                     'Cheesecake', 'Fruit Salad', 'Brownie', 'Crème Brûlée'];
    final sides = ['French Fries', 'Mashed Potato', 'Steamed Vegetables', 'Rice Pilaf',
                  'Coleslaw', 'Garden Salad', 'Onion Rings', 'Garlic Bread'];
    
    List<String> items;
    switch (category) {
      case 'Main Course': items = mainCourses; break;
      case 'Appetizers': items = appetizers; break;
      case 'Beverages': items = beverages; break;
      case 'Desserts': items = desserts; break;
      case 'Sides': items = sides; break;
      default: items = mainCourses;
    }
    
    return items[index % items.length];
  }
  
  // Current date and user (passed from previous screen)
  String _currentDate = '';
  String _currentUserLogin = '';
  
  // Filter menu items based on category and search
  List<Map<String, dynamic>> get _filteredMenuItems {
    return _menuItems.where((item) {
      // Filter by category
      if (_selectedCategory != 'All' && item['category'] != _selectedCategory) {
        return false;
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final name = item['name'].toString().toLowerCase();
        final id = item['id'].toString().toLowerCase();
        final category = item['category'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        
        return name.contains(query) || id.contains(query) || category.contains(query);
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu Items', style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
        backgroundColor: _primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view,
            color: Colors.white,),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list,color: Colors.white,),
            onPressed: () {
              _showFilterOptions();
            },
            tooltip: 'Filter Options',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditItemDialog(null),
        backgroundColor: _accentColor,
        child: const Icon(Icons.add),
        tooltip: 'Add New Menu Item',
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategorySelector(),
          _buildItemCountHeader(),
          Expanded(
            child: _isGridView 
                ? _buildGridView() 
                : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: _primaryColor,
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search menu items...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                }
              },
              backgroundColor: Colors.white.withOpacity(0.2),
              selectedColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? _primaryColor : const Color.fromARGB(255, 2, 2, 2),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemCountHeader() {
    final itemCount = _filteredMenuItems.length;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$itemCount ${itemCount == 1 ? 'item' : 'items'} found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Text(
                'Sort by: ',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              DropdownButton<String>(
                value: 'Name',
                underline: Container(),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: ['Name', 'Price: Low to High', 'Price: High to Low', 'Category']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  // Implement sorting logic
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final filteredItems = _filteredMenuItems;
    
    if (filteredItems.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildListItem(item);
      },
    );
  }

  Widget _buildGridView() {
    final filteredItems = _filteredMenuItems;
    
    if (filteredItems.isEmpty) {
      return _buildEmptyState();
    }
    
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), // Space for FAB
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildGridItem(item);
      },
    );
  }

  Widget _buildListItem(Map<String, dynamic> item) {
    final bool isAvailable = item['available'] as bool;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 60,
            height: 60,
            color: Colors.grey[200],
            child: Center(
              child: Icon(
                Icons.restaurant,
                color: _primaryColor,
                size: 30,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item['name'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isAvailable ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
            if (item['isPopular'] as bool)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Popular',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '\₹${item['price']}',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item['category'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                if (item['isVegetarian'] as bool) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.eco_outlined,
                      size: 14,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isAvailable ? Icons.check_circle_outline : Icons.cancel_outlined,
                  size: 14,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  isAvailable ? 'Available' : 'Unavailable',
                  style: TextStyle(
                    fontSize: 12,
                    color: isAvailable ? Colors.green : Colors.red,
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${item['id']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              _showAddEditItemDialog(item);
            } else if (value == 'delete') {
              _showDeleteConfirmation(item);
            } else if (value == 'toggle') {
              _toggleItemAvailability(item);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    isAvailable ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(isAvailable ? 'Mark Unavailable' : 'Mark Available'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showItemDetails(item),
      ),
    );
  }

  Widget _buildGridItem(Map<String, dynamic> item) {
    final bool isAvailable = item['available'] as bool;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showItemDetails(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.restaurant,
                      size: 40,
                      color: _primaryColor.withOpacity(0.5),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddEditItemDialog(item);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(item);
                      } else if (value == 'toggle') {
                        _toggleItemAvailability(item);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              isAvailable ? Icons.visibility_off : Icons.visibility,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(isAvailable ? 'Mark Unavailable' : 'Mark Available'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isAvailable)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.4),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'UNAVAILABLE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item['isVegetarian'] as bool)
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.eco_outlined,
                            size: 14,
                            color: Colors.green[800],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\₹${item['price']}',
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item['category'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.no_food,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No menu items found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term or category'
                : 'Add your first menu item',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditItemDialog(null),
            icon: const Icon(Icons.add),
            label: const Text('Add Menu Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Filter Menu Items',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          // Reset all filters
                          setModalState(() {
                            // Reset filters logic here
                          });
                        },
                        child: Text(
                          'Reset',
                          style: TextStyle(color: _primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Availability',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Available'),
                        selected: true,
                        onSelected: (selected) {
                          // Filter logic
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Unavailable'),
                        selected: false,
                        onSelected: (selected) {
                          // Filter logic
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Dietary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Vegetarian'),
                        selected: false,
                        onSelected: (selected) {
                          // Filter logic
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Non-Vegetarian'),
                        selected: false,
                        onSelected: (selected) {
                          // Filter logic
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Special',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilterChip(
                    label: const Text('Popular Items'),
                    selected: false,
                    onSelected: (selected) {
                      // Filter logic
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddEditItemDialog(Map<String, dynamic>? item) {
    final bool isEditing = item != null;
    
    // Form controllers
    final nameController = TextEditingController(text: isEditing ? item['name'] as String : '');
    final priceController = TextEditingController(text: isEditing ? item['price'] as String : '');
    final descriptionController = TextEditingController(text: isEditing ? item['description'] as String : '');
    
    // Initial values
    String selectedCategory = isEditing ? item['category'] as String : 'Main Course';
    bool isAvailable = isEditing ? item['available'] as bool : true;
    bool isVegetarian = isEditing ? item['isVegetarian'] as bool : false;
    bool isPopular = isEditing ? item['isPopular'] as bool : false;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Menu Item' : 'Add New Menu Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image placeholder/picker
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.restaurant,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: _accentColor,
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                onPressed: () {
                                  // Image picker logic would go here
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Item ID (only for editing)
                                        // Item ID (only for editing)
                    if (isEditing)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Text(
                              'Item ID: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              item!['id'] as String,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Name field
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name*',
                        border: OutlineInputBorder(),
                        hintText: 'Enter item name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Price field
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price*',
                        border: OutlineInputBorder(),
                        hintText: 'Enter price',
                        prefixText: '\$ ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    
                    // Description field
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        hintText: 'Enter item description',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Category dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category*',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedCategory,
                      items: ['Main Course', 'Appetizers', 'Beverages', 'Desserts', 'Sides']
                          .map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Availability toggle
                    SwitchListTile(
                      title: const Text('Available'),
                      subtitle: const Text('Show this item on the menu'),
                      value: isAvailable,
                      activeColor: _primaryColor,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          isAvailable = value;
                        });
                      },
                    ),
                    
                    // Vegetarian toggle
                    SwitchListTile(
                      title: const Text('Vegetarian'),
                      subtitle: const Text('Mark as vegetarian option'),
                      value: isVegetarian,
                      activeColor: _primaryColor,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          isVegetarian = value;
                        });
                      },
                    ),
                    
                    // Popular toggle
                    SwitchListTile(
                      title: const Text('Popular Item'),
                      subtitle: const Text('Highlight as popular choice'),
                      value: isPopular,
                      activeColor: _primaryColor,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          isPopular = value;
                        });
                      },
                    ),
                    
                    if (isEditing) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Last Updated: ${item!['lastUpdated'] as String}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validate inputs
                    if (nameController.text.trim().isEmpty ||
                        priceController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // Process form data
                    final Map<String, dynamic> updatedItem = {
                      'name': nameController.text.trim(),
                      'price': priceController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'category': selectedCategory,
                      'available': isAvailable,
                      'isVegetarian': isVegetarian,
                      'isPopular': isPopular,
                      'lastUpdated': _currentDate,
                    };
                    
                    if (isEditing) {
                      // Update existing item
                      updatedItem['id'] = item!['id'] as String;
                      updatedItem['image'] = item['image'] as String;
                      
                      setState(() {
                        final index = _menuItems.indexWhere(
                          (element) => element['id'] == item['id'],
                        );
                        if (index != -1) {
                          _menuItems[index] = updatedItem;
                        }
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${updatedItem['name']} updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      // Add new item
                      final newId = 'ITEM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13)}';
                      updatedItem['id'] = newId;
                      updatedItem['image'] = 'assets/food_placeholder.jpg';
                      
                      setState(() {
                        _menuItems.add(updatedItem);
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${updatedItem['name']} added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                  ),
                  child: Text(isEditing ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 60,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Item header with image
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.restaurant,
                          size: 40,
                          color: _primaryColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['name'] as String,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (item['isPopular'] as bool)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'POPULAR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\₹${item['price']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item['category'] as String,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (item['isVegetarian'] as bool)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.eco_outlined,
                                      size: 12,
                                      color: Colors.green[800],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Vegetarian',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Item status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (item['available'] as bool)
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      (item['available'] as bool)
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      color: (item['available'] as bool)
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (item['available'] as bool)
                          ? 'This item is currently available'
                          : 'This item is currently unavailable',
                      style: TextStyle(
                        color: (item['available'] as bool)
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Description
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['description'] as String,
                style: const TextStyle(fontSize: 16),
              ),
              
              const SizedBox(height: 24),
              
              // Item details
              const Text(
                'Item Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('Item ID', item['id'] as String),
              _buildDetailRow('Last Updated', item['lastUpdated'] as String),
              _buildDetailRow('Updated By', _currentUserLogin),
              
              const Spacer(),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddEditItemDialog(item);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Item'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _toggleItemAvailability(item);
                      },
                      icon: Icon(
                        (item['available'] as bool)
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      label: Text(
                        (item['available'] as bool)
                            ? 'Mark Unavailable'
                            : 'Mark Available',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Menu Item'),
          content: Text(
            'Are you sure you want to delete "${item['name']}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _menuItems.removeWhere(
                    (element) => element['id'] == item['id'],
                  );
                });
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item['name']} has been deleted'),
                    backgroundColor: Colors.red,
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: Colors.white,
                      onPressed: () {
                        setState(() {
                          _menuItems.add(item);
                        });
                      },
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _toggleItemAvailability(Map<String, dynamic> item) {
    setState(() {
      final index = _menuItems.indexWhere(
        (element) => element['id'] == item['id'],
      );
      if (index != -1) {
        final bool newStatus = !(_menuItems[index]['available'] as bool);
        _menuItems[index]['available'] = newStatus;
        _menuItems[index]['lastUpdated'] = _currentDate;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item['name']} marked as ${newStatus ? 'available' : 'unavailable'}',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    });
  }
}