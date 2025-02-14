import 'package:animate_do/animate_do.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:hundred_days/utils/notes_theme_list.dart';

class AddNotePage extends StatefulWidget {
  final Map<String, dynamic>? note;

  AddNotePage({this.note});

  @override
  _AddNotePageState createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  DateTime _createdDate = DateTime.now();
  DateTime _lastModifiedDate = DateTime.now();

  int _selectedThemeIndex = 0;

  @override
  void initState() {
    super.initState();

    if (widget.note != null) {
      _titleController.text = widget.note!['title'];
      _bodyController.text = widget.note!['body'];
      _selectedThemeIndex = widget.note!['themeIndex'];
      _createdDate = DateTime.parse(
          widget.note!['createdDate']); // Keep original creation date
    }

    _titleController.addListener(_autoSaveNote);
    _bodyController.addListener(_autoSaveNote);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInternetConnectivity();
      _informAutoSave();
    });
  }

  bool _isSaving = false; // Tracks if note is being saved

  void _autoSaveNote() async {
    if (_titleController.text.trim().isEmpty &&
        _bodyController.text.trim().isEmpty) {
      return; // Don't save empty notes
    }

    setState(() {
      _isSaving = true; // Show autosave indicator
    });

    if (_noteId == null) {
      _noteId = widget.note != null ? widget.note!['id'] : generateUniqueId();
    }

    final note = {
      'id': _noteId,
      'title': _titleController.text,
      'body': _bodyController.text,
      'createdDate': widget.note != null
          ? widget.note!['createdDate']
          : _formatDateTime(_createdDate),
      'lastModifiedDate': _formatDateTime(DateTime.now()),
      'themeIndex': _selectedThemeIndex,
    };

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_noteId!, jsonEncode(note));

    // Save to Firebase (if user is logged in)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('userNotes')
          .doc(user.uid)
          .collection('notes')
          .doc(_noteId)
          .set(note);
    }

    // Hide autosave indicator after a short delay
    Future.delayed(Duration(milliseconds: 1000), () {
      setState(() {
        _isSaving = false;
      });
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_autoSaveNote);
    _bodyController.removeListener(_autoSaveNote);
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  _checkInternetConnectivity() {
    final Connectivity _connectivity = Connectivity();
    Connectivity().checkConnectivity().then((value) {
      if (value == ConnectivityResult.none) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No Internet Connection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _updateAppBarTitle() {
    setState(() {});
  }

  String? _noteId; // Store the ID once

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty &&
        _bodyController.text.trim().isEmpty) {
      return; // Don't save empty notes
    }

    if (_noteId == null) {
      _noteId = widget.note != null
          ? widget.note!['id']
          : generateUniqueId(); // Only generate once
    }

    final note = {
      'id': _noteId,
      'title': _titleController.text,
      'body': _bodyController.text,
      'createdDate': widget.note != null
          ? widget.note!['createdDate']
          : _formatDateTime(_createdDate),
      'lastModifiedDate':
          _formatDateTime(DateTime.now()), // Update last modified date
      'themeIndex': _selectedThemeIndex,
    };

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_noteId!, jsonEncode(note));
    // log("Saved note (updated) with ID: $_noteId");

    // Save to Firebase (if user is logged in)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('userNotes')
          .doc(user.uid)
          .collection('notes')
          .doc(_noteId)
          .set(note);
      // log("Saved note (updated) to Firebase with ID: $_noteId");
    }
  }

  Future<void> deleteNote(String noteId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('userNotes')
          .doc(user.uid)
          .collection('notes')
          .doc(noteId)
          .delete();
    }
  }

  // Save date and time in ISO 8601 format
  String _formatDateTime(DateTime dateTime) {
    return dateTime.toIso8601String(); // ISO 8601 format
  }

  // Display date and time in dd MM yyyy hh:mm format
  String _formatDateTimeForDisplay(DateTime dateTime) {
    // Format the date as dd mm yyyy
    String formattedDate = DateFormat('dd MMM yyyy').format(dateTime);
    // Format the time as hh:mm
    String formattedTime = DateFormat('HH:mm').format(dateTime);
    return '$formattedDate $formattedTime'; // Combine date and time
  }

  String generateUniqueId() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0'); // Include seconds

    return '$day$month$year$hour$minute$second'; // Unique ID with seconds
  }

  void _informAutoSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: Text('AutoSave is enabled')),
        backgroundColor: Colors.grey,
        width: 50.w,
        elevation: 1,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  void _showThemeModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Theme:',
                style: GoogleFonts.getFont(
                  themes[_selectedThemeIndex]['titleFont'],
                  fontSize: 16,
                  color: themes[_selectedThemeIndex]['textColor'],
                ),
              ),
              SizedBox(height: 2.h),
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 2.w,
                    mainAxisSpacing: 2.h,
                  ),
                  itemCount: themes.length,
                  itemBuilder: (context, index) {
                    final theme = themes[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedThemeIndex = index;
                        });
                        _autoSaveNote();
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme['backgroundColor'],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedThemeIndex == index
                                ? Colors.blue
                                : Colors.grey,
                            width: 2,
                          ),
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Title',
                              style: GoogleFonts.getFont(
                                theme['titleFont'],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme['textColor'],
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Body',
                              style: GoogleFonts.getFont(
                                theme['bodyFont'],
                                fontSize: 14,
                                color: theme['textColor'],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = themes[_selectedThemeIndex];
    final textColor = theme['textColor'];
    final backgroundColor = theme['backgroundColor'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titleController.text.isEmpty ? 'Add Note' : _titleController.text,
          style: GoogleFonts.getFont(
            theme['titleFont'],
            fontSize: 20.sp,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (_isSaving)
            Padding(
              padding: EdgeInsets.only(right: 10),
              child: FadeIn(
                duration: Duration(milliseconds: 500),
                child: Icon(Icons.cloud_upload_outlined,
                    color: textColor.withOpacity(0.7)),
              ),
            ),
          IconButton(
            icon: Icon(Icons.save, color: textColor.withOpacity(0.8)),
            onPressed: _saveNote,
          ),
          Pulse(
            child: Swing(
              duration: Duration(milliseconds: 1000),
              child: IconButton(
                icon: Icon(Icons.color_lens, color: textColor.withOpacity(0.8)),
                onPressed: _showThemeModal,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Created: ${_formatDateTimeForDisplay(_createdDate)}', // Display in dd MM yyyy hh:mm format
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8.sp,
                color: textColor.withOpacity(0.6),
              ),
            ),
            Text(
              'Last Modified: ${_formatDateTimeForDisplay(_lastModifiedDate)}', // Display in dd MM yyyy hh:mm format
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8.sp,
                color: textColor.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  color: textColor,
                ),
                border: InputBorder.none,
              ),
              style: GoogleFonts.getFont(
                theme['titleFont'],
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 1,
            ),
            SizedBox(height: 1.h),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(
                labelText: 'Body',
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  color: textColor,
                ),
                border: InputBorder.none,
              ),
              style: GoogleFonts.getFont(
                theme['bodyFont'],
                fontSize: 14.sp,
                color: textColor,
              ),
              maxLines: null,
            ),
          ],
        ),
      ),
    );
  }
}
