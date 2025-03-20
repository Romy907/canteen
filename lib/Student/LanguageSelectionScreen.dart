import 'package:flutter/material.dart';

class LanguageSelectionScreen extends StatefulWidget {
  @override
  _LanguageSelectionScreenState createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String selectedLanguage = 'English';

  void _changeLanguage(String language) {
    setState(() {
      selectedLanguage = language;
    });
  }

  Widget _buildLanguageOption({
    required String language,
    required String subtitle,
    required String flagAsset,
  }) {
    bool isSelected = selectedLanguage == language;
    return GestureDetector(
      onTap: () => _changeLanguage(language),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFEDE7F6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF673AB7) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Country Flag
            CircleAvatar(
              radius: 25,
              backgroundImage: AssetImage(flagAsset),
            ),
            SizedBox(width: 25),

            // Language Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Selection Checkmark
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Color(0xFF673AB7),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Select Language'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Choose Your Language",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              "Select your preferred language for the app interface",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            SizedBox(height: 25),

            // Language Selection Options
            _buildLanguageOption(
              language: "English",
              subtitle: "English",
              flagAsset: "assets/img/us_image.png",
            ),
            _buildLanguageOption(
              language: "Hindi",
              subtitle: "हिन्दी",
              flagAsset: "assets/img/india_image.png",
            ),

            SizedBox(height: 65),

            // Language Information Box
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: const Color.fromARGB(255, 11, 12, 13)),
                      SizedBox(width: 8),
                      Text(
                        "Language Information",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  _infoText(Icons.language, "App interface language can be changed anytime"),
                  _infoText(Icons.refresh, "Some changes may require app restart"),
                  _infoText(Icons.help, "Contact support if you need help with languages"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoText(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
