import 'package:flutter/material.dart';

class StudentUniversitySearch extends StatefulWidget {
  final Function(String) onUniversitySelected;

  StudentUniversitySearch({required this.onUniversitySelected});

  @override
  _StudentUniversitySearchState  createState() => _StudentUniversitySearchState ();
}

class _StudentUniversitySearchState extends State<StudentUniversitySearch> {
  TextEditingController _searchController = TextEditingController();
  List<String> _universityList = [
    'California Institute of Technology',
    'Harvard University',
    'Massachusetts Institute of Technology',
    'Princeton University',
    'Stanford University',
    'University of California, Berkeley',
    'University of Oxford',
    'University of Cambridge', 
    'Yale University',
  ];
  List<String> _filteredUniversityList = [];

  // Future<void> _fetchUniversities() async {
  //   DatabaseReference ref = FirebaseDatabase.instance.ref().child('universities');
  //   DatabaseEvent snapshot = await ref.once();
  //   List<String> universities = [];
  //   Map<dynamic, dynamic> universityData = snapshot.snapshot.value as Map<dynamic, dynamic>;
  //   universityData.forEach((key, value) {
  //     universities.add(value);
  //   });

  //   setState(() {
  //     _universityList = universities;
  //     _filteredUniversityList = universities;
  //   });
  // }

  @override
  void initState() {
    super.initState();
    // _fetchUniversities();
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
          .where((university) => university.toLowerCase().contains(value.toLowerCase()))
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
                  onTap: () {
                    widget.onUniversitySelected(_filteredUniversityList[index]);
                    Navigator.pop(context);
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