import 'dart:developer';
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
  bool _isNoteSaved = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!['title'];
      _bodyController.text = widget.note!['body'];
      _selectedThemeIndex = widget.note!['themeIndex'];
      _isNoteSaved = true;
    }
    _titleController.addListener(_updateAppBarTitle);
    _checkInternetConnectivity();
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateAppBarTitle);
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  _checkInternetConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No Internet Connection'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateAppBarTitle() {
    setState(() {});
  }

  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in both title and body.')),
      );
      return;
    }

    final uniqueId =
        widget.note != null ? widget.note!['id'] : generateUniqueId();
    final note = {
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
    await prefs.setString(uniqueId, jsonEncode(note));
    log("Note saved to SharedPreferences with ID: $uniqueId");

    // Save to Firebase if online
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      log("Before Firebase");
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('userNotes')
              .doc(user.uid)
              .collection('notes')
              .doc(uniqueId)
              .set(note);
          log("saved to Firebase with ID: $uniqueId");
          _isNoteSaved = true;
        } catch (e) {
          log("Error saving to Firebase: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save note to Firebase.')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note saved locally. Will sync when online.')),
      );
      _isNoteSaved = true;
    }

    if (_isNoteSaved) {
      log("Before SnackBar");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note saved successfully!')),
      );
      log("After SnackBar");

      log("Before Navigator");
      Navigator.pop(context);
      log("After Navigator");
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isNoteSaved &&
        (_titleController.text.isNotEmpty || _bodyController.text.isNotEmpty)) {
      final shouldPop = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Unsaved Changes'),
          content:
              Text('You have unsaved changes. Are you sure you want to leave?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Yes'),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  String _formatDateTime(DateTime dateTime) => dateTime.toIso8601String();
  String _formatDateTimeForDisplay(DateTime dateTime) =>
      DateFormat('dd MMM yyyy HH:mm').format(dateTime);
  String generateUniqueId() =>
      DateFormat('ddMMyyyyHHmmss').format(DateTime.now());

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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
            IconButton(
              icon: Icon(Icons.color_lens, color: textColor.withOpacity(0.8)),
              onPressed: _showThemeModal,
            ),
            IconButton(
              icon: Icon(Icons.save, color: textColor.withOpacity(0.8)),
              onPressed: _saveNote,
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
                'Created: ${_formatDateTimeForDisplay(_createdDate)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8.sp,
                  color: textColor.withOpacity(0.6),
                ),
              ),
              Text(
                'Last Modified: ${_formatDateTimeForDisplay(_lastModifiedDate)}',
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
      ),
    );
  }
}
