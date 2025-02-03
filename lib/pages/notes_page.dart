import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_notes.dart';
import 'package:hundred_days/utils/notes_theme_list.dart';

class NotesListPage extends StatefulWidget {
  @override
  _NotesListPageState createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  List<Map<String, dynamic>> _notes = [];
  final String _notesKey = 'cached_notes';
  String _sortOrder = 'Descending'; // Default sort order
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
    _loadCachedNotes();
    _syncNotes();
    _myCheck();
    _isOnline = false;
    _checkInternetConnectivity();
    // Delay the initial connectivity check until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialConnectivity();
    });
  }

  // Updated _myCheck method
  Future<void> _myCheck() async {
    List<ConnectivityResult> connectivityResults =
        await Connectivity().checkConnectivity();
    bool isConnected = connectivityResults.any(
      (result) => result != ConnectivityResult.none,
    );

    if (!isConnected) {
      log("Device is offline");
      print("Device is offline");
    } else {
      log("Device is online");
      print("Device is online");
    }
  }

// Updated _checkInitialConnectivity method
  Future<void> _checkInitialConnectivity() async {
    List<ConnectivityResult> connectivityResults =
        await Connectivity().checkConnectivity();
    bool isOnline = connectivityResults.any(
      (result) => result != ConnectivityResult.none,
    );

    if (mounted) {
      setState(() => _isOnline = isOnline);
      if (!_isOnline) {
        _showSnackBar(
            'No internet connection, fetching notes from local device',
            Colors.red);
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(
        //         'No internet connection, fetching notes from local device'),
        //     duration: Duration(seconds: 4),
        //   ),
        // );
      }
    }
  }

// Updated connectivity listener
  void _checkInternetConnectivity() {
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      bool isOnline = results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (mounted) {
        setState(() => _isOnline = isOnline);
      }

      isOnline
          ? _showSnackBar('Back online', Colors.green)
          : _showSnackBar(
              'No internet connection, fetching notes from local device ',
              Colors.red);

      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(isOnline
      //         ? 'Back online'
      //         : 'No internet connection, fetching notes from local device '),
      //     duration: Duration(seconds: isOnline ? 2 : 4),
      //   ),
      // );

      if (isOnline) _syncNotes();
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        showCloseIcon: true,
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadCachedNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedNotes = prefs.getString(_notesKey);
    if (cachedNotes != null) {
      setState(() {
        _notes = (jsonDecode(cachedNotes) as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    }
  }

  Future<void> _saveNotesToCache(List<Map<String, dynamic>> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notesKey, jsonEncode(notes));
  }

  Future<List<Map<String, dynamic>>> fetchNotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('userNotes')
        .doc(user.uid)
        .collection('notes')
        .get();

    final notes = querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    // Save the fetched notes to cache
    await _saveNotesToCache(notes);

    return notes;
  }

  Future<void> _fetchNotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Fetch notes from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('userNotes')
          .doc(user.uid)
          .collection('notes')
          .get();

      final notes = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Save notes to SharedPreferences
      await _saveNotesToCache(notes);

      setState(() => _notes = notes);
      _sortNotes();
    } catch (e) {
      // If Firestore fails (e.g., offline), load cached notes
      print("Error fetching notes from Firestore: $e");
      await _loadCachedNotes();
    }
  }

  Future<void> _syncNotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Fetch notes from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('userNotes')
          .doc(user.uid)
          .collection('notes')
          .get();

      final notes = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Save notes to SharedPreferences
      await _saveNotesToCache(notes);

      setState(() => _notes = notes);
      _sortNotes();
    } catch (e) {
      print("Error syncing notes: $e");
    }
  }

  void _sortNotes() {
    _notes.sort((a, b) {
      DateTime dateA = DateTime.parse(a['createdDate']);
      DateTime dateB = DateTime.parse(b['createdDate']);
      return _sortOrder == 'Ascending'
          ? dateA.compareTo(dateB)
          : dateB.compareTo(dateA);
    });
  }

  Map<String, dynamic> _getTheme(int themeIndex) {
    return themes[themeIndex % themes.length];
  }

  Widget _buildNoteCard(Map<String, dynamic> note, BuildContext context) {
    final theme = _getTheme(note['themeIndex']);
    final textColor = theme['textColor'];
    final backgroundColor = theme['backgroundColor'];

    // Use DateTime.parse to parse the createdDate string
    DateTime createdDate = DateTime.parse(note['createdDate']);
    final formattedDate = DateFormat('MMM dd, yyyy').format(createdDate);

    return GestureDetector(
      onTap: () => _openNote(note),
      onLongPress: () => _showNoteOptions(context, note['id']),
      child: Container(
        margin: EdgeInsets.all(1.5.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNoteTitle(note, theme, textColor),
              SizedBox(height: 1.h),
              _buildNoteBody(note, theme, textColor),
              SizedBox(height: 1.h),
              _buildNoteFooter(note, theme, textColor, formattedDate),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTitle(
      Map<String, dynamic> note, Map<String, dynamic> theme, Color textColor) {
    return Text(
      note['title'] ?? 'Untitled',
      style: GoogleFonts.getFont(
        theme['titleFont'],
        color: textColor,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildNoteBody(
      Map<String, dynamic> note, Map<String, dynamic> theme, Color textColor) {
    return Expanded(
      child: Text(
        note['body'] ?? '',
        style: GoogleFonts.getFont(
          theme['bodyFont'],
          color: textColor.withOpacity(0.9),
          fontSize: 12.sp,
        ),
        maxLines: 5,
        overflow: TextOverflow.fade,
      ),
    );
  }

  Widget _buildNoteFooter(Map<String, dynamic> note, Map<String, dynamic> theme,
      Color textColor, String formattedDate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          formattedDate,
          style: GoogleFonts.getFont(
            theme['bodyFont'],
            color: textColor.withOpacity(0.7),
            fontSize: 9.sp,
          ),
        ),
      ],
    );
  }

  Future<void> _deleteNote(String noteId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('userNotes')
          .doc(user.uid)
          .collection('notes')
          .doc(noteId)
          .delete();
      _fetchNotes();
    }
  }

  void _showNoteOptions(BuildContext context, String noteId) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20), // Rounded corners for the bottom sheet
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header for the bottom sheet
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Note Options',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Divider(), // Divider to separate the header from options
              // Delete Option
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Delete Note',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    color: Colors.red,
                  ),
                ),
                subtitle: Text(
                  'Permanently remove this note',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: Colors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _confirmDeleteNote(noteId); // Show confirmation dialog
                },
              ),
              // Edit Option
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text(
                  'Edit Note',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    color: Colors.blue,
                  ),
                ),
                subtitle: Text(
                  'Modify the content of this note',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: Colors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  // Add logic to edit the note
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteNote(String noteId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FlipInX(
          child: AlertDialog(
            title: Text('Delete Note'),
            content: Text('Are you sure you want to delete this note?'),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Delete'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteNote(noteId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openNote(Map<String, dynamic>? note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNotePage(note: note),
      ),
    ).then((_) => _fetchNotes());
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchNotes();
        _checkInternetConnectivity();
        _checkInitialConnectivity();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text('My Notes',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18.sp, fontWeight: FontWeight.w600)),
              SizedBox(width: 8),
              Icon(
                _isOnline ? Icons.cloud : Icons.cloud_off,
                size: 18.sp,
                color: _isOnline ? Colors.green : Colors.red,
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  _sortOrder = value;
                  _sortNotes(); // Sort notes when the order is changed
                });
              },
              itemBuilder: (BuildContext context) {
                return {'Ascending', 'Descending'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
              icon: Icon(Icons.sort, color: Colors.black),
            ),
          ],
          elevation: 0,
        ),
        body: _notes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.note_add, size: 20.w, color: Colors.grey),
                    SizedBox(height: 2.h),
                    Text(
                      'No Notes Found',
                      style: GoogleFonts.poppins(
                          fontSize: 16.sp, color: Colors.grey),
                    ),
                    Text(
                      'Tap + to create your first note',
                      style: GoogleFonts.poppins(
                          fontSize: 12.sp, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: EdgeInsets.all(2.w),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 2.w,
                    crossAxisSpacing: 2.w,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) => FadeInUp(
                    delay: Duration(milliseconds: 100 * index),
                    child: _buildNoteCard(_notes[index], context),
                  ),
                ),
              ),
        floatingActionButton: Bounce(
          child: FloatingActionButton(
            onPressed: () => _openNote(null),
            backgroundColor: Colors.teal,
            child: Icon(Icons.add, size: 20.sp),
          ),
        ),
      ),
    );
  }
}
