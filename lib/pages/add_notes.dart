import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:hundred_days/utils/notes_theme_list.dart';

class AddNotePage extends StatefulWidget {
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
    _titleController.addListener(_updateAppBarTitle);
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateAppBarTitle);
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
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

    final note = {
      'title': _titleController.text,
      'body': _bodyController.text,
      'createdDate': _formatDateTime(_createdDate),
      'lastModifiedDate': _formatDateTime(DateTime.now()),
      'themeIndex': _selectedThemeIndex,
    };

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_titleController.text, jsonEncode(note));

    // Save to Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('notes')
          .doc(user.email)
          .collection(_titleController.text)
          .doc('details')
          .set(note);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Note saved successfully!')),
    );

    Navigator.pop(context);
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}-${dateTime.month}-${dateTime.year}';
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
          IconButton(
            icon: Icon(Icons.color_lens, color: textColor),
            onPressed: _showThemeModal,
          ),
          IconButton(
            icon: Icon(Icons.save, color: textColor),
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
              'Created: ${_formatDateTime(_createdDate)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8.sp,
                color: textColor.withOpacity(0.6),
              ),
            ),
            Text(
              'Last Modified: ${_formatDateTime(_lastModifiedDate)}',
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
