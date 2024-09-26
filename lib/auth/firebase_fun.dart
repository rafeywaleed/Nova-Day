import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userId; // Variable to store user ID

  // Signup function
  Future<void> signUp(String name, String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null) {
        userId = user.uid; // Store user ID locally

        // Store user data in Firestore under UserDetails
        await _firestore.collection('UserDetails').doc(user.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Save user data in SharedPreferences
        await _saveUserDetailsToPreferences(name, email);
      }
    } on FirebaseAuthException catch (e) {
      print('Error signing up: ${e.message}');
      throw e;
    }
  }

  Future<void> _saveUserDetailsToPreferences(String name, String email) async {
    String? joinedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    await prefs.setString('joinedDate', joinedDate);
  }

  // Signin function
  Future<void> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null) {
        userId = user.uid; // Store user ID locally
      } else {
        throw Exception("User not found after sign in.");
      }
    } on FirebaseAuthException catch (e) {
      print('Error signing in: ${e.message}');
      throw e;
    }
  }

  // Signout function
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      userId = null; // Clear stored user ID
    } on FirebaseAuthException catch (e) {
      print('Error signing out: ${e.message}');
      throw e; // Optionally, throw a custom exception
    }
  }

  // Change name function
  Future<void> changeName(String newName) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'name': newName,
        });
      } else {
        throw Exception("No user signed in.");
      }
    } on FirebaseAuthException catch (e) {
      print('Error changing name: ${e.message}');
      throw e; // Optionally, throw a custom exception
    }
  }

  // Change password function
  Future<void> changePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception("No user signed in.");
      }
    } on FirebaseAuthException catch (e) {
      print('Error changing password: ${e.message}');
      throw e; // Optionally, throw a custom exception
    }
  }

  // Get saved email from Firestore using Stream
  Stream<String?> getEmailStream() {
    User? user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snapshot) {
        if (snapshot.exists) {
          return snapshot.data()?['email'] as String?;
        }
        return null;
      });
    }
    return Stream.value(null);
  }

    // FirebaseService class
Future<Map<String, dynamic>> fetchUserData() async {
  User? user = FirebaseAuth.instance.currentUser; // Get the current user
  if (user == null) {
    throw Exception("User is not logged in."); // Handle the case where there's no logged-in user
  }

  DocumentSnapshot snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get(); // Fetch user data from Firestore

  if (!snapshot.exists) {
    throw Exception("User data not found in Firestore."); // Handle the case where user data doesn't exist
  }

  return snapshot.data() as Map<String, dynamic>; // Return user data
}

}
