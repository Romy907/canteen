import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  final Map<String, String> profileData;
  final File? profileImage;

  const EditProfileScreen({Key? key, required this.profileData, this.profileImage}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameFocusNode = FocusNode(); // Add this line
  late Map<String, String> _editedProfileData;
  bool _isEditing = false; // Initially set to false
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _editedProfileData = Map.from(widget.profileData);
    _profileImage = widget.profileImage;
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      // Save the profile data to shared preferences or any other storage

      // Navigate back to the manager profile screen and pass the updated data
      Navigator.pop(context, {'profileData': _editedProfileData, 'profileImage': _profileImage});

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Personal information successfully changed')),
      );
    }
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

  void _toggleEdit() {
    setState(() {
      _isEditing = true;
    });

    // Focus on the first text field to bring up the keyboard
    Future.delayed(Duration(milliseconds: 300), () {
      FocusScope.of(context).requestFocus(_nameFocusNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
       appBar: AppBar(
  title: const Text('Edit Profile'),
  centerTitle: true,
  elevation: 1,
  backgroundColor: Colors.white,
  foregroundColor: Colors.black87,
  leading: IconButton(
    icon: Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.arrow_back_ios_new, size: 16),
    ),
    onPressed: () => Navigator.of(context).pop(),
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.save),
      onPressed: _saveProfile,
    ),
  ],
),


        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Hero(
                                tag: 'profile_image',
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(51),
                                        blurRadius: 10,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,  // Increased radius
                                    backgroundColor: Colors.white,
                                    backgroundImage: _profileImage != null
                                        ? FileImage(_profileImage!)
                                        : null,
                                    child: _profileImage == null
                                        ? Text(
                                            widget.profileData['name']!.substring(0, 1),
                                            style: TextStyle(
                                              fontSize: 28,
                                              color: Theme.of(context).primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(51),
                                        blurRadius: 6,
                                        spreadRadius: 0,
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
                        Card(
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
                                    Container(
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withAlpha(50),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Personal Information',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                                      onPressed: _toggleEdit,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildEditableInfoRow(Icons.person_outline, 'Name', _editedProfileData['name'], (value) => _editedProfileData['name'] = value!, focusNode: _nameFocusNode, iconColor: Colors.blue),
                                const SizedBox(height: 16),
                                _buildEditableInfoRow(Icons.email_outlined, 'Email', _editedProfileData['email'], (value) => _editedProfileData['email'] = value!, iconColor: Colors.red),
                                const SizedBox(height: 16),
                                _buildEditableInfoRow(Icons.phone_outlined, 'Phone', _editedProfileData['phone'], (value) => _editedProfileData['phone'] = value!, iconColor: Colors.green),
                                const SizedBox(height: 16),
                                _buildEditableInfoRow(Icons.location_on_outlined, 'Location', _editedProfileData['location'], (value) => _editedProfileData['location'] = value!, iconColor: Colors.orange),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _saveProfile,
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEditableInfoRow(IconData icon, String label, String? initialValue, FormFieldSetter<String> onSaved, {FocusNode? focusNode, required Color iconColor}) {
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
            initialValue: initialValue,
            enabled: _isEditing,
            focusNode: focusNode, // Add this line
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
            ),
            style: TextStyle(color: Colors.black),
            onSaved: onSaved,
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
}