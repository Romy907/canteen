import 'package:firebase_database/firebase_database.dart';

class StudentMenuServices {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  Future<List<Map<String, dynamic>>> getMenuItems(List<String> ids) async {
    print(ids);
    List<Map<String, dynamic>> menuItems = [];

    for (String id in ids) {
      DatabaseEvent snapshot =
          await _databaseReference.child(id).child('menu').once();
      if (snapshot.snapshot.value != null) {
        Map<dynamic, dynamic> items =
            snapshot.snapshot.value as Map<dynamic, dynamic>;
        items.forEach((key, value) {
          menuItems.add(Map<String, dynamic>.from(value));
        });
      }
    }

    return menuItems;
  }
}
