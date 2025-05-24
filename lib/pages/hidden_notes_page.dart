import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hundred_days/pages/add_notes.dart';
import 'package:sizer/sizer.dart';

class HiddenNotesPage extends StatefulWidget {
  final List<Map<String, dynamic>> notes;
  final Future<void> Function(String noteId) onUnhide;

  const HiddenNotesPage({Key? key, required this.notes, required this.onUnhide})
      : super(key: key);

  @override
  State<HiddenNotesPage> createState() => _HiddenNotesPageState();
}

class _HiddenNotesPageState extends State<HiddenNotesPage> {
  late List<Map<String, dynamic>> _hiddenNotes;

  @override
  void initState() {
    super.initState();
    _hiddenNotes = List<Map<String, dynamic>>.from(widget.notes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Hidden Notes',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _hiddenNotes.isEmpty
          ? Center(
              child: Text(
                'No hidden notes',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 14.sp,
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(3.w),
              itemCount: _hiddenNotes.length,
              itemBuilder: (context, index) {
                final note = _hiddenNotes[index];
                return Card(
                  color: Colors.grey[900],
                  margin: EdgeInsets.only(bottom: 3.w),
                  child: ListTile(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddNotePage(note: note),
                        ),
                      );
                    },
                    title: Text(
                      note['title'] ?? 'Untitled',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                    subtitle: Text(
                      note['body'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontSize: 12.sp,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.teal),
                      tooltip: 'Unhide',
                      onPressed: () async {
                        await widget.onUnhide(note['id']);
                        setState(() {
                          _hiddenNotes.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
