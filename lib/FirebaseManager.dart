import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseManager {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      email = email.trim(); 

      if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
        return {
          'status': 'error',
          'message': 'Please enter a valid email address',
        };
      }

      // Firebase Authentication
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Sanitize email for Firebase Realtime Database
      String sanitizedEmail = email.replaceAll(RegExp(r'[.#$[\]]'), '');
      // String sanitizedEmail = 'romykatiyar020306gmailcom';

      // Fetch user data
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref().child('User').child(sanitizedEmail);
      DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists && snapshot.value != null) {
        return {
          'status': 'success',
          'message': 'Login successful',
          'userId': userCredential.user?.uid,
          'data': snapshot.value,
        };
      } else {
        return {
          'status': 'error',
          'message': 'No user data found in database',
          'userId': userCredential.user?.uid,
        };
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format';
      } else if (e.code == 'user-not-found') {
        errorMessage = 'User not found';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password';
      } else {
        errorMessage = 'Login failed: ${e.message}';
      }
      return {
        'status': 'error',
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'An unexpected error occurred: $e',
      };
    }
  }
 
}
