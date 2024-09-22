import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        // Store user ID in shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', user.uid);
        userId = user.uid; // Store user ID locally

        // Store user data in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      print('Error signing up: ${e.message}');
      throw e; // Optionally, throw a custom exception
    }

    Future<void> storeEmail(String email) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userEmail', email);
      print('Email stored: $email');
    }
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
        // Store user ID and email in shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', user.uid);
        await prefs.setString(
            'userEmail', user.email!); // Use ! since email is non-null
        userId = user.uid; // Store user ID locally
      } else {
        throw Exception("User not found after sign in.");
      }
    } on FirebaseAuthException catch (e) {
      print('Error signing in: ${e.message}');
      throw e;
    }
    Future<void> storeEmail(String email) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userEmail', email);
      print('Email stored: $email');
    }
  }

  // Signout function
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      userId = null; // Clear stored user ID

      // Optionally clear shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.remove('userEmail');
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
}
