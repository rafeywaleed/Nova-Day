import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class DialogBox extends StatelessWidget {
  final TextEditingController Controller;
  final TextEditingController? descriptionController;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool isDailyTask;

  const DialogBox({
    required this.Controller,
    required this.onSave,
    required this.onCancel,
    this.descriptionController,
    this.isDailyTask = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'Add Task',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: Controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Task Name',
              labelStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
          ),
          if (!isDailyTask)
            TextField(
              controller: descriptionController,
              maxLines: null,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            'Cancel',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.red,
            ),
          ),
        ),
        TextButton(
          onPressed: onSave,
          child: Text(
            'Save',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}
