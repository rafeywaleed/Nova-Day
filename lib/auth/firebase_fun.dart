import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userId;

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
        userId = user.uid;

        await _saveUserDetails(name, email, user.uid);
      }
    } on FirebaseAuthException catch (e) {
      print('Error signing up: ${e.message}');
      throw e;
    }
  }

  // Method to save user details in Firestore and SharedPreferences
  Future<void> _saveUserDetails(String name, String email, String uid) async {
    String joinedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

    try {
      await FirebaseFirestore.instance.collection('userDetails').doc(uid).set({
        'name': name,
        'email': email,
        'joinedDate': joinedDate,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('User data stored in Firestore');
    } catch (error) {
      print('Error storing user data in Firestore: $error');
    }

    // Save user data in SharedPreferences
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);
      await prefs.setString('userEmail', email);
      await prefs.setString('joinedDate', joinedDate);
      print('User data stored in SharedPreferences');
    } catch (error) {
      print('Error storing user data in SharedPreferences: $error');
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
      throw e;
    }
  }

  // Change name function
  Future<void> changeName(String newName) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('userDetails').doc(user.uid).update({
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
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User is not logged in.");
    }

    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!snapshot.exists) {
      throw Exception("User data not found in Firestore.");
    }

    return snapshot.data() as Map<String, dynamic>;
  }
}
