import 'package:firebase_database/firebase_database.dart';

class UniversityServices {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<List<String>> fetchUniversityNames() async {
    try {
      DatabaseEvent event = await _database.child('University').once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
        return data.keys.toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching university names: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> fetchStoresByUniversity(String universityName) async {
    try {
      DatabaseEvent event = await _database.child('University/$universityName').once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
        List<Map<String, String>> stores = [];

        data.forEach((storeId, managerName) {
          stores.add({storeId: managerName});
        });

        return stores;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching stores for university $universityName: $e');
      return [];
    }
  }
}