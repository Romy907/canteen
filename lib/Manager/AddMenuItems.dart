import 'package:canteen/Services/ImgBBService.dart';
import 'package:canteen/Services/MenuServices.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';


class AddEditMenuItemScreen extends StatefulWidget {
  final Map<String, dynamic>? item; // Null if adding new item
  final String currentDate;
  final String userLogin;
  
  const AddEditMenuItemScreen({
    Key? key, 
    this.item, 
    required this.currentDate,
    required this.userLogin,
  }) : super(key: key);
  
  @override
  _AddEditMenuItemScreenState createState() => _AddEditMenuItemScreenState();
}

class _AddEditMenuItemScreenState extends State<AddEditMenuItemScreen> {
  final MenuService _menuService = MenuService();
  final ImgBBService _imgBBService = ImgBBService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  String _selectedCategory = 'Main Course';
  bool _isAvailable = true;
  bool _isVegetarian = false;
  bool _isPopular = false;
  File? _imageFile;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _isUploading = false;
  
  final Color _primaryColor = const Color(0xFF1E88E5);
  final Color _accentColor = const Color(0xFF26C6DA);
  
  @override
  void initState() {
    super.initState();
    _initializeService();
    // Initialize form with existing item data if editing
    if (widget.item != null) {
      _nameController.text = widget.item!['name'] as String;
      _priceController.text = widget.item!['price'] as String;
      _descriptionController.text = widget.item!['description'] as String? ?? '';
      _selectedCategory = widget.item!['category'] as String;
      _isAvailable = widget.item!['available'] as bool;
      _isVegetarian = widget.item!['isVegetarian'] as bool;
      _isPopular = widget.item!['isPopular'] as bool;
      _currentImageUrl = widget.item!['image'] as String?;
    }
  }
   
  Future<void> _initializeService() async {
    
    try {
      // Initialize MenuService
      await _menuService.initialize();
    } catch (e) {
      print('Error initializing service: $e');
     ;
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _initializeService,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }
  
  Future<String> _uploadImage() async {
    if (_imageFile == null) return _currentImageUrl ?? '';
    
    try {
      setState(() {
        _isUploading = true;
      });
      
      // First compress the image to reduce upload size
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/compressed_menu_image.jpg';
      
      // Compress the file
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        _imageFile!.path,
        tempPath,
        quality: 70,  // Medium quality
        minWidth: 500,
        minHeight: 500,
      );
      
      if (compressedFile == null) {
        throw Exception('Failed to compress image');
      }
      
      // Upload compressed file to ImgBB
      final imageUrl = await _imgBBService.uploadImage(File(compressedFile.path));
      
      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('Failed to upload image to ImgBB');
      }
      
      return imageUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e'), backgroundColor: Colors.red)
      );
      return '';
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
  
  Future<void> _saveMenuItem() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Upload image if changed
      String imageUrl = _currentImageUrl ?? '';
      
      if (_imageFile != null) {
        imageUrl = await _uploadImage();
        if (imageUrl.isEmpty) {
          throw Exception('Image upload failed');
        }
      }
      
      final Map<String, dynamic> menuData = {
        'name': _nameController.text.trim(),
        'price': _priceController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'available': _isAvailable,
        'isVegetarian': _isVegetarian,
        'isPopular': _isPopular,
        'image': imageUrl,
        'lastUpdated': widget.currentDate, // "2025-03-09 18:15:38"
        'updatedBy': widget.userLogin,      // "navin280123"
      };
      
      if (widget.item == null) {
        // Add new item
        await _menuService.addMenuItem(menuData, widget.currentDate, widget.userLogin);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${menuData['name']} added successfully'), backgroundColor: Colors.green)
        );
      } else {
        // Update existing item
        await _menuService.updateMenuItem(widget.item!['id'], menuData, widget.currentDate, widget.userLogin);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${menuData['name']} updated successfully'), backgroundColor: Colors.green)
        );
      }
      
      Navigator.pop(context, true); // Return success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.item != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Menu Item' : 'Add New Menu Item', 
                 style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _saveMenuItem,
            tooltip: 'Save',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image picker
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            height: 180,
                            width: 180,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(15),
                              image: _imageFile != null
                                  ? DecorationImage(
                                      image: FileImage(_imageFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(_currentImageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                            ),
                            child: (_imageFile == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty))
                                ? Icon(
                                    Icons.restaurant,
                                    size: 80,
                                    color: Colors.grey[400],
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _isUploading ? null : _pickImage,
                              child: CircleAvatar(
                                backgroundColor: _accentColor,
                                radius: 24,
                                child: _isUploading 
                                  ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  : const Icon(Icons.camera_alt, size: 24, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Form fields
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
                            Expanded(
                              child: Text(
                                widget.item!['id'] as String,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  color: Colors.grey[700],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name*',
                        border: OutlineInputBorder(),
                        hintText: 'Enter item name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an item name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price*',
                        border: OutlineInputBorder(),
                        hintText: 'Enter price',
                        prefixText: '\₹ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        hintText: 'Enter item description',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category*',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCategory,
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
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Item Options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Options
                    SwitchListTile(
                      title: const Text('Available'),
                      subtitle: const Text('Show this item on the menu'),
                      value: _isAvailable,
                      activeColor: _primaryColor,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          _isAvailable = value;
                        });
                      },
                    ),
                    
                    SwitchListTile(
                      title: const Text('Vegetarian'),
                      subtitle: const Text('Mark as vegetarian option'),
                      value: _isVegetarian,
                      activeColor: _primaryColor,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          _isVegetarian = value;
                        });
                      },
                    ),
                    
                    SwitchListTile(
                      title: const Text('Popular Item'),
                      subtitle: const Text('Highlight as popular choice'),
                      value: _isPopular,
                      activeColor: _primaryColor,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          _isPopular = value;
                        });
                      },
                    ),
                    
                    if (isEditing) ...[
                      const SizedBox(height: 16),
                      Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Last Updated: ${widget.item!['lastUpdated']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Updated By: ${widget.item!['updatedBy'] ?? widget.userLogin}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveMenuItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          elevation: 2,
                        ),
                        child: Text(
                          isEditing ? 'UPDATE MENU ITEM' : 'ADD MENU ITEM',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}