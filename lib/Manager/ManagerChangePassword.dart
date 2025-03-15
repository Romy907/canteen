import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Assuming Firebase Auth
import 'dart:async';

class ManagerChangePassword extends StatefulWidget {
  final String? email;
  
  const ManagerChangePassword({
    Key? key, 
    this.email,
  }) : super(key: key);

  @override
  ManagerChangePasswordState createState() => ManagerChangePasswordState();
}

class ManagerChangePasswordState extends State<ManagerChangePassword> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  
  String _passwordStrength = 'Weak';
  Color _strengthColor = Colors.red;
  double _strengthValue = 0.0;
  
  // Animation controller for success animation
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  bool _passwordChanged = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    
    // Listen for password changes to calculate strength
    _newPasswordController.addListener(_calculatePasswordStrength);
  }
  
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  // Calculate password strength
  void _calculatePasswordStrength() {
    String password = _newPasswordController.text;
    
    if (password.isEmpty) {
      setState(() {
        _strengthValue = 0;
        _passwordStrength = "Empty";
        _strengthColor = Colors.grey;
      });
      return;
    }
    
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    bool hasMinLength = password.length >= 8;
    
    double strength = 0;
    if (hasMinLength) strength += 0.2;
    if (hasUppercase) strength += 0.2;
    if (hasDigits) strength += 0.2;
    if (hasLowercase) strength += 0.2;
    if (hasSpecialCharacters) strength += 0.2;
    
    setState(() {
      _strengthValue = strength;
      
      if (strength <= 0.2) {
        _passwordStrength = "Very weak";
        _strengthColor = Colors.red.shade800;
      } else if (strength <= 0.4) {
        _passwordStrength = "Weak";
        _strengthColor = Colors.orange;
      } else if (strength <= 0.6) {
        _passwordStrength = "Medium";
        _strengthColor = Colors.yellow.shade700;
      } else if (strength <= 0.8) {
        _passwordStrength = "Strong";
        _strengthColor = Colors.blue;
      } else {
        _passwordStrength = "Very strong";
        _strengthColor = Colors.green;
      }
    });
  }

  // Change password method
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    // Use a slight delay to show the loading indicator
    await Future.delayed(const Duration(milliseconds: 300));
    
    try {
      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Re-authenticate the user
        AuthCredential credential = EmailAuthProvider.credential(
          email: widget.email ?? user.email!,
          password: _currentPasswordController.text,
        );
        
        await user.reauthenticateWithCredential(credential);
        
        // Change the password
        await user.updatePassword(_newPasswordController.text);
        
        setState(() {
          _passwordChanged = true;
          _isLoading = false;
        });
        
        _animationController.forward();
        
        // Return to previous screen after delay
        Timer(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        if (e.code == 'wrong-password') {
          _errorMessage = 'Current password is incorrect. Please try again.';
        } else {
          _errorMessage = 'Error: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred. Please try again later.';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Change Password',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _passwordChanged ? _buildSuccessView() : _buildPasswordChangeForm(isSmallScreen, primaryColor),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _animation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
            ),
          ),
          SizedBox(height: 32),
          Text(
            'Password Changed!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Your password has been updated successfully.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPasswordChangeForm(bool isSmallScreen, Color primaryColor) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Create a new password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your new password must be different from your current password and meet the security requirements below.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 32),
                
                // Current Password Field
                _buildPasswordField(
                  controller: _currentPasswordController,
                  label: 'Current Password',
                  hint: 'Enter your current password',
                  isPasswordVisible: _isCurrentPasswordVisible,
                  toggleVisibility: () {
                    setState(() {
                      _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                  isFirstField: true,
                ),
                SizedBox(height: 24),
                
                // New Password Field
                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  hint: 'Enter your new password',
                  isPasswordVisible: _isNewPasswordVisible,
                  toggleVisibility: () {
                    setState(() {
                      _isNewPasswordVisible = !_isNewPasswordVisible;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value == _currentPasswordController.text) {
                      return 'New password must be different from current password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters long';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                
                // Password strength indicator
                _buildStrengthIndicator(),
                SizedBox(height: 24),
                
                // Confirm Password Field
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Confirm your new password',
                  isPasswordVisible: _isConfirmPasswordVisible,
                  toggleVisibility: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  isLastField: true,
                ),
                SizedBox(height: 24),
                
                // Password requirements
                _buildPasswordRequirements(),
                SizedBox(height: 32),
                
                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null) SizedBox(height: 24),
                
                // Change Password Button
                Container(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primaryColor.withAlpha(153),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Update Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isPasswordVisible,
    required Function() toggleVisibility,
    required String? Function(String?) validator,
    bool isFirstField = false,
    bool isLastField = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isPasswordVisible,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade300, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade300, width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade600,
                size: 22,
              ),
              onPressed: toggleVisibility,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.lock_outline,
                color: Colors.grey.shade600,
                size: 22,
              ),
            ),
          ),
          textInputAction: isLastField ? TextInputAction.done : TextInputAction.next,
          onFieldSubmitted: (_) {
            if (isLastField) {
              FocusScope.of(context).unfocus();
            } else {
              FocusScope.of(context).nextFocus();
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Password Strength: ',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              _passwordStrength,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _strengthColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _strengthValue,
            backgroundColor: Colors.grey.shade200,
            color: _strengthColor,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPasswordRequirements() {
    String password = _newPasswordController.text;
    
    bool hasMinLength = password.length >= 8;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withAlpha(25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          _buildRequirementRow(
            'At least 8 characters',
            hasMinLength,
          ),
          SizedBox(height: 8),
          _buildRequirementRow(
            'At least one uppercase letter (A-Z)',
            hasUppercase,
          ),
          SizedBox(height: 8),
          _buildRequirementRow(
            'At least one lowercase letter (a-z)',
            hasLowercase,
          ),
          SizedBox(height: 8),
          _buildRequirementRow(
            'At least one number (0-9)',
            hasDigits,
          ),
          SizedBox(height: 8),
          _buildRequirementRow(
            'At least one special character (!@#\$&*~)',
            hasSpecialCharacters,
          ),
        ],
      ),
    );
  }
  
  Widget _buildRequirementRow(String text, bool isMet) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMet ? Colors.green : Colors.grey.shade300,
          ),
          child: Icon(
            isMet ? Icons.check : Icons.close,
            size: 14,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isMet ? Colors.black87 : Colors.grey.shade600,
              fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}