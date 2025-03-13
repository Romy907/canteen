import 'package:canteen/Services/UniversityServices.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentUniversitySearch extends StatefulWidget {
  final Function(String) onUniversitySelected;

  StudentUniversitySearch({required this.onUniversitySelected});

  @override
  _StudentUniversitySearchState createState() =>
      _StudentUniversitySearchState();
}

class _StudentUniversitySearchState extends State<StudentUniversitySearch> {
  TextEditingController _searchController = TextEditingController();
  List<String> _universityList = [];
  List<String> _filteredUniversityList = [];

  @override
  void initState() {
    _getUniversityList();
    super.initState();
  }

  Future<void> _getUniversityList() async {
    final universityList = await UniversityServices().fetchUniversityNames();
    print(universityList);
    setState(() {
      _universityList = universityList;
      _filteredUniversityList = universityList;
    });
  }
  Future<void> _saveToPreferences(String university) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('selectedUniversity', university);
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search University',
            hintStyle: TextStyle(color: Colors.white54),
            prefixIcon: Icon(Icons.search, color: Colors.white),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _filteredUniversityList = _universityList
                  .where((university) =>
                      university.toLowerCase().contains(value.toLowerCase()))
                  .toList();
            });
          },
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6C63FF),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUniversityList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_filteredUniversityList[index]),
                  onTap: () async {
                    widget.onUniversitySelected.call(_filteredUniversityList[index]);

                    // Save to SharedPreferences
                    _saveToPreferences(_filteredUniversityList[index]);

                    // Return the selected university to the previous screen
                    Navigator.pop(context, _filteredUniversityList[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
