import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hundred_days/utils/fab_offset.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_notes.dart';
import 'package:hundred_days/utils/notes_theme_list.dart';

import 'hidden_notes_page.dart';

class NotesListPage extends StatefulWidget {
  const NotesListPage({Key? key}) : super(key: key);
  @override
  _NotesListPageState createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  final String _notesKey = 'cached_notes';
  final String _sortOrderKey = 'sort_order';
  String _sortOrder = 'Descending';
  bool _isOnline = false;
  bool _showDeleteButton = false;
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadSortOrderPreference().then((_) {
      _fetchNotes();
      _loadCachedNotes();
      _syncNotes();
      _isOnline = false;
      _checkInternetConnectivity();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkInitialConnectivity();
      });
    });
  }

  Future<void> _loadSortOrderPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _sortOrder = prefs.getString(_sortOrderKey) ?? 'Descending';
  }

  Future<void> _saveSortOrderPreference(String sortOrder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortOrderKey, sortOrder);
  }

  Future<void> _myCheck() async {
    List<ConnectivityResult> connectivityResults =
        await Connectivity().checkConnectivity();
    bool isConnected = connectivityResults.any(
      (result) => result != ConnectivityResult.none,
    );
  }

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
            'No internet connection, fetching notes from local device. Process may be slow',
            const Color.fromARGB(255, 83, 83, 83));
      }
    }
  }

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

      if (!isOnline) {
        _showSnackBar(
            'No internet connection, fetching notes from local device. Process may be slow',
            const Color.fromARGB(255, 83, 83, 83));
      }

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
        duration: const Duration(seconds: 4),
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
      data['pinned'] = data['pinned'] ?? false;
      data['hidden'] = data['hidden'] ?? false; // <-- add this line
      return data;
    }).toList();

    await _saveNotesToCache(notes);

    return notes;
  }

  Future<void> _fetchNotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('userNotes')
          .doc(user.uid)
          .collection('notes')
          .get();

      final notes = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['pinned'] = data['pinned'] ?? false; // Initialize pinned field
        data['hidden'] = data['hidden'] ?? false; // Initialize hidden field
        return data;
      }).toList();

      await _saveNotesToCache(notes);

      setState(() => _notes = notes);
      _sortNotes();
    } catch (e) {
      await _loadCachedNotes();
    }
  }

  Future<void> _syncNotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('userNotes')
          .doc(user.uid)
          .collection('notes')
          .get();

      final notes = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['pinned'] = data['pinned'] ?? false; // Initialize pinned field
        data['hidden'] = data['hidden'] ?? false; // Initialize hidden field
        return data;
      }).toList();

      await _saveNotesToCache(notes);

      setState(() => _notes = notes);
      _sortNotes();
    } catch (e) {
      //print("Error syncing notes: $e");
    }
  }

  Future<void> _togglePinNote(String noteId, bool currentlyPinned) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('userNotes')
          .doc(user.uid)
          .collection('notes')
          .doc(noteId)
          .update({'pinned': !currentlyPinned});
      _fetchNotes();
    }
  }

  Future<void> _toggleHideNote(String noteId, bool currentlyHidden) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('userNotes')
          .doc(user.uid)
          .collection('notes')
          .doc(noteId)
          .update({'hidden': !currentlyHidden});
      _fetchNotes();
    }
  }

  void _filterNotes(String query) {
    setState(() {
      _filteredNotes = _notes.where((note) {
        final title = note['title']?.toString().toLowerCase() ?? '';
        final body = note['body']?.toString().toLowerCase() ?? '';
        return title.contains(query.toLowerCase()) ||
            body.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      _filteredNotes = List.from(_notes);
    });
  }

  void _endSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _filteredNotes.clear();
    });
  }

  void _sortNotes() {
    final notesToSort = _isSearching ? _filteredNotes : _notes;

    notesToSort.sort((a, b) {
      // Sort pinned notes first
      final aPinned = a['pinned'] ?? false;
      final bPinned = b['pinned'] ?? false;
      if (aPinned != bPinned) {
        return aPinned ? -1 : 1;
      }

      DateTime dateA =
          DateTime.parse(a['lastModifiedDate'] ?? a['createdDate']);
      DateTime dateB =
          DateTime.parse(b['lastModifiedDate'] ?? b['createdDate']);
      return _sortOrder == 'Descending'
          ? dateB.compareTo(dateA)
          : dateA.compareTo(dateB);
    });
  }

  Map<String, dynamic> _getTheme(int themeIndex) {
    return themes[themeIndex % themes.length];
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search notes...',
        border: InputBorder.none,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14.sp),
        suffixIcon: IconButton(
          icon: Icon(Icons.close),
          onPressed: _endSearch,
        ),
      ),
      style: GoogleFonts.plusJakartaSans(fontSize: 14.sp),
      onChanged: _filterNotes,
    );
  }

  Widget _buildAppBarTitle() {
    return Row(
      children: [
        Text(
          'My Notes',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          _isOnline ? Icons.cloud : Icons.cloud_off,
          size: 18.sp,
          color: _isOnline ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note, BuildContext context) {
    final theme = _getTheme(note['themeIndex']);
    final textColor = theme['textColor'];
    final backgroundColor = theme['backgroundColor'];

    DateTime createdDate = DateTime.parse(note['createdDate']);
    final formattedDate = DateFormat('MMM dd, yyyy').format(createdDate);
    final isPinned = note['pinned'] ?? false;

    return GestureDetector(
      onTap: () => openNote(note),
      onLongPress: () {
        setState(() {
          _showDeleteButton = true;
        });
      },
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.all(1.5.w),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
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
          if (isPinned)
            Positioned(
              top: 12,
              right: 12,
              child: Icon(Icons.push_pin, color: Colors.brown, size: 16.sp),
            ),
          Visibility(
            visible: _showDeleteButton,
            child: Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showDeleteButton = false;
                  });
                  _showNoteOptions(context, note['id'], isPinned);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
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

  void _showNoteOptions(BuildContext context, String noteId, bool isPinned) {
    final note = _notes.firstWhere((n) => n['id'] == noteId,
        orElse: () => <String, dynamic>{});
    final isHidden = note.isNotEmpty && note['hidden'] == true;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                    isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: Colors.amber),
                title: Text(
                  isPinned ? 'Unpin Note' : 'Pin Note',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    color: Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _togglePinNote(noteId, isPinned);
                },
              ),
              ListTile(
                leading: Icon(
                  isHidden ? Icons.visibility : Icons.visibility_off,
                  color: Colors.blueGrey,
                ),
                title: Text(
                  isHidden ? 'Unhide Note' : 'Hide Note',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    color: Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleHideNote(noteId, isHidden);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Delete Note',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteNote(noteId);
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
        return AlertDialog(
          title: const Text('Delete Note'),
          content: const Text('Are you sure you want to delete this note?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteNote(noteId);
              },
            ),
          ],
        );
      },
    );
  }

  void openNote(Map<String, dynamic>? note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNotePage(note: note),
      ),
    ).then((_) => _fetchNotes());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final notesToDisplay = (_isSearching ? _filteredNotes : _notes)
        .where((note) => note['hidden'] != true)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchNotes();
        _checkInternetConnectivity();
        _checkInitialConnectivity();
      },
      child: Scaffold(
        backgroundColor: Color.fromRGBO(243, 243, 243, 1),
        appBar: AppBar(
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          title: _isSearching ? _buildSearchField() : _buildAppBarTitle(),
          actions: [
            if (!_isSearching)
              IconButton(
                icon: Icon(Icons.search),
                onPressed: _startSearch,
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  _sortOrder = value;
                  _saveSortOrderPreference(value);
                  _sortNotes();
                });
              },
              itemBuilder: (BuildContext context) {
                return {'Descending', 'Ascending'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
              icon: const Icon(Icons.sort, color: Colors.black),
            ),
          ],
          elevation: 0,
        ),
        body: notesToDisplay.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.note_add, size: 20.w, color: Colors.grey),
                    SizedBox(height: 2.h),
                    Text(
                      _isSearching ? 'No matching notes' : 'No Notes Found',
                      style: GoogleFonts.poppins(
                          fontSize: 16.sp, color: Colors.grey),
                    ),
                    if (!_isSearching)
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 2.w,
                          crossAxisSpacing: 2.w,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: notesToDisplay.length,
                        itemBuilder: (context, index) => FadeInUp(
                          delay: Duration(milliseconds: 100 * index),
                          child: _buildNoteCard(notesToDisplay[index], context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        floatingActionButtonLocation: CustomFABLocationWithSizer(),
        floatingActionButton: GestureDetector(
          onDoubleTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => HiddenNotesPage(
                  notes: _notes.where((n) => n['hidden'] == true).toList(),
                  onUnhide: (noteId) async {
                    await _toggleHideNote(noteId, true);
                  },
                ),
                transitionsBuilder: (_, animation, __, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
              ),
            );
          },
          child: FloatingActionButton(
            onPressed: () => openNote(null),
            backgroundColor: Colors.teal,
            child: Icon(Icons.add, size: 20.sp),
            tooltip: 'Tap to add a new note\nDouble tap to view hidden notes',
          ),
        ),
      ),
    );
  }
}
