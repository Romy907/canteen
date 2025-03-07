import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isObscure = true;

  void _changePassword() {
    if (_formKey.currentState!.validate()) {
      // Perform password change logic here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password changed successfully!")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Colors.black,
                  ),
                ),
                child: TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    labelText: "Current Password",
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Please enter your current password";
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Colors.black,
                  ),
                ),
                child: TextFormField(
                  controller: _newPasswordController,
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Please enter a new password";
                    if (value.length < 6) return "Password must be at least 6 characters";
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Colors.black,
                  ),
                ),
                child: TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Please confirm your password";
                    if (value != _newPasswordController.text) return "Passwords do not match";
                    return null;
                  },
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 85, 151, 244),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _changePassword,
                  child: Text("Change Password"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}