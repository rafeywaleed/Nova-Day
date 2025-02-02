import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:hundred_days/utils/notes_theme_list.dart';
import 'add_notes.dart';

class NotesListPage extends StatefulWidget {
  @override
  _NotesListPageState createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<List<Map<String, dynamic>>> fetchNotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return []; // Return an empty list if the user is not logged in
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('userNotes')
        .doc(user.uid)
        .collection('notes')
        .get();

    final notes = querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Include the document ID in the note data
      return data;
    }).toList();

    return notes;
  }

  String _generateUniqueId() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$day$month$year$hour$minute';
  }

  void _openNote(Map<String, dynamic>? note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNotePage(note: note),
      ),
    ).then((_) => _fetchNotes());
  }

  Future<void> _fetchNotes() async {
    final notes = await fetchNotes();
    setState(() {
      _notes = notes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Notes'),
      ),
      body: _notes.isEmpty
          ? Center(child: Text('No notes found.'))
          : ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return ListTile(
                  title: Text(note['title']),
                  subtitle: Text(note['body']),
                  onTap: () {
                    // Navigate to the note detail page or edit page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddNotePage(note: note),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddNotePage(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
