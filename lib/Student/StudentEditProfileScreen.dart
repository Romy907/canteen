import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class StudentEditProfileScreen extends StatefulWidget {
  final File? profileImage;

  const StudentEditProfileScreen({Key? key, this.profileImage})
      : super(key: key);

  @override
  _StudentEditProfileScreenState createState() =>
      _StudentEditProfileScreenState();
}

class _StudentEditProfileScreenState extends State<StudentEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController campusController = TextEditingController();
  String selectedMealPreference = 'Vegetarian';
  File? _profileImage;

  final FocusNode _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _profileImage = widget.profileImage;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? imagePath = prefs.getString('profile_image');
    if (imagePath != null) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
    setState(() {
      nameController.text = prefs.getString('name') ?? '';
      emailController.text = prefs.getString('email') ?? '';
      phoneController.text = prefs.getString('phone') ?? '';
      campusController.text = prefs.getString('campus') ?? '';
      selectedMealPreference =
          prefs.getString('meal_preference') ?? 'Vegetarian';
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _saveProfileData() async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.setString('name', nameController.text);
    // await prefs.setString('email', emailController.text);
    // await prefs.setString('phone', phoneController.text);
    // await prefs.setString('campus', campusController.text);
    // await prefs.setString('meal_preference', selectedMealPreference);
    // if (_profileImage != null) {
    //   await prefs.setString('profile_image', _profileImage!.path);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
  title: const Text('Edit Profile'),
  centerTitle: true,
  backgroundColor: Colors.white,
  foregroundColor: Colors.black87,
  elevation: 1,
  leading: IconButton(
    icon: Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black87),
    ),
    onPressed: () => Navigator.of(context).pop(),
  ),
),

      resizeToAvoidBottomInset:
          true, // Allows the screen to resize when the keyboard appears
      body: GestureDetector(
        onTap: () => FocusScope.of(context)
            .unfocus(), // Hide keyboard when tapping outside
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context)
                  .size
                  .height, // Ensures full-screen scrollability
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(51),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : AssetImage('assets/images/logo.png')
                                      as ImageProvider,
                              child: _profileImage == null
                                  ? Icon(Icons.person,
                                      size: 50, color: Colors.grey)
                                  : null,
                            ),
                          ),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(51),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Scrollable Personal Information Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withAlpha(50),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Personal Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined,
                                        color: Theme.of(context).primaryColor),
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = true;
                                      });
                                      Future.delayed(
                                          const Duration(milliseconds: 300),
                                          () {
                                        FocusScope.of(context)
                                            .requestFocus(_nameFocusNode);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildEditableInfoRow(Icons.person_outline,
                                'Full Name', nameController, _nameFocusNode),
                            const SizedBox(height: 16),
                            _buildEditableInfoRow(
                                Icons.email_outlined, 'Email', emailController),
                            const SizedBox(height: 16),
                            _buildEditableInfoRow(
                                Icons.phone_outlined, 'Phone', phoneController),
                            const SizedBox(height: 16),
                            _buildDropdownInfoRow(Icons.restaurant_menu,
                                'Meal Preference', selectedMealPreference),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button (Always Visible)
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await _saveProfileData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Profile updated successfully')),
                            );
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableInfoRow(
      IconData icon, String label, TextEditingController controller,
      [FocusNode? focusNode]) {
    // Define different colors for each icon
    Color iconColor;
    switch (label) {
      case 'Full Name':
        iconColor = Colors.blue;
        break;
      case 'Email':
        iconColor = Colors.red;
        break;
      case 'Phone':
        iconColor = Colors.green;
        break;
      case 'Campus':
        iconColor = Colors.orange;
        break;
      default:
        iconColor = Theme.of(context).primaryColor;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: controller,
            enabled: _isEditing,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
            ),
            style: const TextStyle(color: Colors.black),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your $label';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownInfoRow(
      IconData icon, String label, String currentValue) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.purple.withAlpha(25), // Meal Preference icon color
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.purple, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: currentValue,
            onChanged: _isEditing
                ? (value) {
                    setState(() {
                      selectedMealPreference = value!;
                    });
                  }
                : null,
            decoration: const InputDecoration(
              labelText: 'Meal Preference',
              border: InputBorder.none,
            ),
            style: const TextStyle(color: Colors.black),
            items: ['Vegetarian', 'Non-Vegetarian', 'Vegan']
                .map((meal) => DropdownMenuItem(
                      value: meal,
                      child: Text(
                        meal,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
