import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<List<Map<String, dynamic>>> fetchNotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('userNotes')
        .doc(user.uid)
        .collection('notes')
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> _fetchNotes() async {
    final notes = await fetchNotes();
    setState(() => _notes = notes);
  }

  Map<String, dynamic> _getTheme(int themeIndex) {
    return themes[themeIndex % themes.length];
  }

  Widget _buildNoteCard(Map<String, dynamic> note, BuildContext context) {
    final theme = _getTheme(note['themeIndex']);
    final textColor = theme['textColor'];
    final backgroundColor = theme['backgroundColor'];
    final createdDate = DateTime.parse(note['createdDate']);
    final formattedDate = DateFormat('MMM dd, yyyy').format(createdDate);

    return Dismissible(
      key: Key(note['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 5.w),
        child: Icon(Icons.delete, color: Colors.white, size: 24.sp),
      ),
      onDismissed: (direction) => _deleteNote(note['id']),
      child: GestureDetector(
        onTap: () => _openNote(note),
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
        if (note['pinned'] == true)
          Icon(Icons.push_pin, color: textColor.withOpacity(0.7), size: 12.sp),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('My Notes',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18.sp, fontWeight: FontWeight.w600)),
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
                itemBuilder: (context, index) =>
                    _buildNoteCard(_notes[index], context),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNote(null),
        backgroundColor: Colors.teal,
        child: Icon(Icons.add, size: 20.sp),
      ),
    );
  }
}
