import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Assuming you're using the easy_localization package, but this can be adjusted
// import 'package:easy_localization/easy_localization.dart' as easy;

class ManagerSelectLanguage extends StatefulWidget {
  const ManagerSelectLanguage({Key? key}) : super(key: key);

  @override
  ManagerSelectLanguageState createState() => ManagerSelectLanguageState();
}

class ManagerSelectLanguageState extends State<ManagerSelectLanguage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedLanguage = 'en'; // Default language
  bool _isLoading = false;
  
  // Language options
  final List<Map<String, dynamic>> _languages = [
    {
      'code': 'en',
      'name': 'English',
      'nativeName': 'English',
      'flag': '🇺🇸',
      'image': 'assets/images/english_flag.png', // Optional flag image if you prefer custom images
    },
    {
      'code': 'hi',
      'name': 'Hindi',
      'nativeName': 'हिन्दी',
      'flag': '🇮🇳',
      'image': 'assets/images/hindi_flag.png', // Optional flag image
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    
    _getCurrentLanguage();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Get current language from shared preferences
  Future<void> _getCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _selectedLanguage = prefs.getString('languageCode') ?? 'en';
      });
    } catch (e) {
      // Default to English if there's an error
      setState(() {
        _selectedLanguage = 'en';
      });
    }
  }

  // Save selected language to shared preferences
  Future<void> _saveLanguage(String languageCode) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('languageCode', languageCode);
      
      // Update app locale using the localization package of your choice
      // This example uses easy_localization
      // await easy.EasyLocalization.of(context)?.setLocale(Locale(languageCode));
      
      setState(() {
        _selectedLanguage = languageCode;
        _isLoading = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageCode == 'en' 
              ? 'Language changed to English' 
              : 'भाषा हिंदी में बदल गई है',
            style: TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(12),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to change language. Please try again.',
            style: TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(12),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final accentColor = Theme.of(context).colorScheme.secondary;
    final backgroundColor = Colors.grey.shade50;
    
    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            'Select Language', // This would be localized in a real app
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
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
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, -0.2),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOut,
                    )),
                    child: FadeTransition(
                      opacity: _animationController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Your Language',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Select your preferred language for the app interface',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  
                  // Language selection cards
                  ...List.generate(_languages.length, (index) {
                    final language = _languages[index];
                    final isSelected = language['code'] == _selectedLanguage;
                    
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0, 0.2 + (index * 0.1)),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeOut,
                      )),
                      child: FadeTransition(
                        opacity: _animationController,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: _buildLanguageCard(
                            language: language,
                            isSelected: isSelected,
                            primaryColor: primaryColor,
                            onTap: () => _saveLanguage(language['code']),
                          ),
                        ),
                      ),
                    );
                  }),
                  
                  SizedBox(height: 32),
                  
                  // Language info
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, 0.4),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOut,
                    )),
                    child: FadeTransition(
                      opacity: _animationController,
                      child: Container(
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
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: accentColor,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Language Information',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            _buildInfoRow(
                              icon: Icons.translate,
                              text: 'App interface language can be changed anytime',
                            ),
                            SizedBox(height: 8),
                            _buildInfoRow(
                              icon: Icons.refresh,
                              text: 'Some changes may require app restart',
                            ),
                            SizedBox(height: 8),
                            _buildInfoRow(
                              icon: Icons.help_outline,
                              text: 'Contact support if you need help with languages',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Loading overlay
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withAlpha(76),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Changing language...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLanguageCard({
    required Map<String, dynamic> language,
    required bool isSelected,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withAlpha(25) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected 
              ? primaryColor.withAlpha(51) 
              : Colors.black.withAlpha(12),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Row(
              children: [
                // Language flag/icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? primaryColor.withAlpha(25) 
                      : Colors.grey.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    language['flag'],
                    style: TextStyle(fontSize: 30),
                  ),
                ),
                SizedBox(width: 20),
                
                // Language details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        language['nativeName'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Selection indicator
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? primaryColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isSelected 
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.blue.shade300,
          size: 18,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}