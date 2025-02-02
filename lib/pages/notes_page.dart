// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:sizer/sizer.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'dart:convert';
// import 'package:hundred_days/utils/notes_theme_list.dart';
// import 'add_notes.dart';

// class NotesListPage extends StatefulWidget {
//   @override
//   _NotesListPageState createState() => _NotesListPageState();
// }

// class _NotesListPageState extends State<NotesListPage> {
//   List<Map<String, dynamic>> _notes = [];

//   @override
//   void initState() {
//     super.initState();
//     _fetchNotes();
//   }

//   Future<void> _fetchNotes() async {
//     final prefs = await SharedPreferences.getInstance();
//     final user = FirebaseAuth.instance.currentUser;

//     // Fetch notes from SharedPreferences
//     print("Fetching notes from SharedPreferences...");
//     _notes = prefs
//         .getKeys()
//         .where((key) =>
//             prefs.getString(key) != null) // Filter keys with String values
//         .map((key) {
//           final noteJson = prefs.getString(key);
//           if (noteJson != null) {
//             try {
//               return jsonDecode(noteJson) as Map<String, dynamic>;
//             } catch (e) {
//               print("Error decoding note for key $key: $e");
//               return null;
//             }
//           }
//           return null;
//         })
//         .where((note) => note != null) // Filter out null values
//         .cast<Map<String, dynamic>>()
//         .toList();

//     print("Notes from SharedPreferences: $_notes");

//     // If no notes are found in SharedPreferences, fetch from Firebase
//     if (_notes.isEmpty && user != null) {
//       print("Fetching notes from Firebase...");
//       try {
//         final snapshot = await FirebaseFirestore.instance
//             .collection('userNotes') // Consistent collection name
//             .doc(user.uid) // Use user ID
//             .collection('notes') // Subcollection for notes
//             .get();

//         _notes = snapshot.docs.map((doc) {
//           final data = doc.data();
//           if (data['createdDate'] is Timestamp) {
//             data['createdDate'] = (data['createdDate'] as Timestamp).toDate();
//           }
//           if (data['lastModifiedDate'] is Timestamp) {
//             data['lastModifiedDate'] =
//                 (data['lastModifiedDate'] as Timestamp).toDate();
//           }
//           return data;
//         }).toList();

//         print("Notes from Firebase: $_notes");

//         // Save fetched notes to SharedPreferences
//         for (final note in _notes) {
//           final uniqueId = _generateUniqueId();
//           await prefs.setString(uniqueId, jsonEncode(note));
//         }
//       } catch (e) {
//         print("Error fetching notes from Firebase: $e");
//       }
//     }

//     setState(() {});
//   }

//   String _generateUniqueId() {
//     final now = DateTime.now();
//     final day = now.day.toString().padLeft(2, '0');
//     final month = now.month.toString().padLeft(2, '0');
//     final year = now.year.toString();
//     final hour = now.hour.toString().padLeft(2, '0');
//     final minute = now.minute.toString().padLeft(2, '0');
//     return '$day$month$year$hour$minute';
//   }

//   void _openNote(Map<String, dynamic>? note) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => AddNotePage(note: note),
//       ),
//     ).then((_) => _fetchNotes());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'My Notes',
//           style: GoogleFonts.poppins(
//             fontSize: 20.sp,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//       body: ListView.builder(
//         padding: EdgeInsets.all(16),
//         itemCount: _notes.length + 1,
//         itemBuilder: (context, index) {
//           if (index == 0) {
//             return Card(
//               elevation: 2,
//               child: ListTile(
//                 leading: Icon(Icons.add, color: Colors.blue),
//                 title: Text(
//                   'Add New Note',
//                   style: GoogleFonts.poppins(
//                     fontSize: 14.sp,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 onTap: () => _openNote(null),
//               ),
//             );
//           }

//           final note = _notes[index - 1];
//           final theme = themes[note['themeIndex']];
//           final textColor = theme['textColor'];
//           final backgroundColor = theme['backgroundColor'];

//           return Card(
//             elevation: 2,
//             color: backgroundColor,
//             child: ListTile(
//               title: Text(
//                 note['title'],
//                 style: GoogleFonts.getFont(
//                   theme['titleFont'],
//                   fontSize: 14.sp,
//                   fontWeight: FontWeight.bold,
//                   color: textColor,
//                 ),
//               ),
//               subtitle: Text(
//                 note['body'],
//                 style: GoogleFonts.getFont(
//                   theme['bodyFont'],
//                   fontSize: 12.sp,
//                   color: textColor,
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               onTap: () => _openNote(note),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
