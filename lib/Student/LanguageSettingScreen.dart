import 'package:flutter/material.dart';

class LanguageSettingsScreen extends StatelessWidget {
  final List<Map<String, String>> languages = [
    {'name': 'Hindi', 'localName': 'हिन्दी', 'color': '0xFFE57373'},
    {'name': 'English', 'localName': 'English', 'color': '0xFF81C784'},
    {'name': 'Punjabi', 'localName': 'ਪੰਜਾਬੀ', 'color': '0xFF64B5F6'},
    {'name': 'Bengali', 'localName': 'বাংলা', 'color': '0xFFFFD54F'},
    {'name': 'Urdu', 'localName': 'اردو', 'color': '0xFF4DB6AC'},
    {'name': 'Malayalam', 'localName': 'മലയാളം', 'color': '0xFFFF8A65'},
    {'name': 'Tamil', 'localName': 'தமிழ்', 'color': '0xFFBA68C8'},
  ];

  void _changeLanguage(BuildContext context, String language) {
    // Logic to change the language
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Language changed to $language')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Language'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
          ),
          itemCount: languages.length,
          itemBuilder: (context, index) {
            final language = languages[index];
            return GestureDetector(
              onTap: () => _changeLanguage(context, language['name']!),
              child: Container(
                decoration: BoxDecoration(
                  color: Color(int.parse(language['color']!)),
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        language['localName']!,
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        language['name']!,
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}