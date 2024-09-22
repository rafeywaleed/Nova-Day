import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
}