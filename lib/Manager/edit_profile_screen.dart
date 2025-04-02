import 'package:canteen/Services/ImgBBService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_database/firebase_database.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, String> profileData;
  final File? profileImage;

  const EditProfileScreen(
      {Key? key, required this.profileData, this.profileImage})
      : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, String> _editedProfileData;
  File? _profileImage;
  bool _isLoading = false;
  final ImgBBService _imgBBService = ImgBBService();
  @override
  void initState() {
    super.initState();
    _editedProfileData = Map.from(widget.profileData);
    _profileImage = widget.profileImage;
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      _formKey.currentState?.save();

      try {
        // Upload the profile image and get the URL
        final imageUrl = await _uploadImage();
        if (imageUrl.isNotEmpty) {
          _editedProfileData['profileImageUrl'] = imageUrl;
        }

        // Prepare the email key for Firebase (remove invalid characters)
        final sanitizedEmail = _editedProfileData['email']
            .toString()
            .replaceAll(RegExp(r'[.#$[\]]'), '');

        // Save or update the data in Firebase Realtime Database
        final databaseRef =
            FirebaseDatabase.instance.ref('User/$sanitizedEmail');
        await databaseRef.set(_editedProfileData);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back to the profile screen and pass the updated data
        Navigator.pop(context, {
          'profileData': _editedProfileData,
          'profileImage': _profileImage,
        });
      } catch (e) {
        _showSnackBar('Failed to save profile: $e', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _uploadImage() async {
    if (_profileImage == null) return '';

    String tempPath = '';
    try {
      // First compress the image to reduce upload size
      final tempDir = await getTemporaryDirectory();
      tempPath = '${tempDir.path}/profile.jpg';

      // Compress the file
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        _profileImage!.path,
        tempPath,
        quality: 70,
        minWidth: 800,
        minHeight: 800,
      );

      if (compressedFile == null) {
        throw Exception('Failed to compress image');
      }

      // Upload compressed file to ImgBB
      final imageUrl =
          await _imgBBService.uploadImage(File(compressedFile.path));

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('Failed to upload image to ImgBB');
      }

      return imageUrl;
    } catch (e) {
      _showSnackBar('Failed to upload image: $e', isError: true);
      return '';
    } finally {
      // Delete the compressed file
      if (File(tempPath).existsSync()) {
        File(tempPath).deleteSync();
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    // Show image source selection dialog
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.blue),
                ),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const Divider(height: 0.5),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.indigo),
                ),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, size: 20),
            ),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                // Profile Image Section
                profileImageSection(primaryColor),
                const SizedBox(height: 28),

                // Personal Information Section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                personalInfoSection(),
                const SizedBox(height: 32),

                // Save Button
                saveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget profileImageSection(Color primaryColor) {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Profile Image Background
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFE0F2F1)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x3A000000),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Hero(
              tag: 'profile_image',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: primaryColor.withAlpha(51),
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (widget.profileData['profileImageUrl'] != null &&
                              widget.profileData['profileImageUrl']!.isNotEmpty
                          ? NetworkImage(widget.profileData['profileImageUrl']!)
                          : null) as ImageProvider?,
                  child: _profileImage == null &&
                          (widget.profileData['profileImageUrl'] == null ||
                              widget.profileData['profileImageUrl']!.isEmpty)
                      ? Text(
                          widget.profileData['name']
                                  ?.substring(0, 1)
                                  .toUpperCase() ??
                              'A',
                          style: TextStyle(
                            fontSize: 40,
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Camera/Edit Button
          Material(
            elevation: 4,
            shadowColor: Colors.black38,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _pickImage,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget personalInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInputField(
              icon: Icons.person_outline,
              label: 'Full Name',
              initialValue: _editedProfileData['name'],
              onSaved: (value) => _editedProfileData['name'] = value!,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
              iconColor: Colors.blue,
            ),
            const Divider(height: 24),
            _buildInputField(
              icon: Icons.email_outlined,
              label: 'Email Address',
              initialValue: _editedProfileData['email'],
              onSaved: (value) => _editedProfileData['email'] = value!,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              keyboardType: TextInputType.emailAddress,
              iconColor: Colors.red,
            ),
            const Divider(height: 24),
            _buildInputField(
              icon: Icons.phone_outlined,
              label: 'Phone Number',
              initialValue: _editedProfileData['phone'],
              onSaved: (value) => _editedProfileData['phone'] = value!,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
              keyboardType: TextInputType.phone,
              iconColor: Colors.green,
            ),
            const Divider(height: 24),
            _buildInputField(
              icon: Icons.location_on_outlined,
              label: 'Location',
              initialValue: _editedProfileData['university'],
              onSaved: (value) => _editedProfileData['university'] = value!,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your location';
                }
                return null;
              },
              iconColor: Colors.orange,
            ),
            const Divider(height: 24),
             _buildInputField(
              icon: Icons.home,
              label: 'Address',
              initialValue: _editedProfileData['location'],
              onSaved: (value) => _editedProfileData['location'] = value!,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your Store Address';
                }
                return null;
              },
              iconColor: const Color.fromARGB(255, 20, 218, 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String label,
    required String? initialValue,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    TextInputType? keyboardType,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            initialValue: initialValue,
            decoration: InputDecoration(
              labelText: label,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: InputBorder.none,
              labelStyle: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            keyboardType: keyboardType,
            textInputAction: TextInputAction.next,
            onSaved: onSaved,
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget saveButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 55,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withAlpha(76),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _saveProfile,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
