import 'package:flutter/material.dart';

class DialogBox extends StatelessWidget {
  final Controller;

  final VoidCallback onSave;
  final VoidCallback onCancel;

  DialogBox({
    super.key,
    this.Controller,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.all(16), // Add padding
      content: Container(
        height: MediaQuery.of(context).size.height * 0.2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Get user input
            TextField(
              controller: Controller,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: "Add a new Task",
                hintStyle: const TextStyle(fontFamily: 'Poppins'),
              ),
            ),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Save
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Change button color
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Make corners rounded
                    ),
                  ),
                  onPressed: onSave,
                  child: const Text(
                    "Add",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Cancel
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.red,
                    backgroundColor: Colors.white, // Change text color
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Make corners rounded
                      side: const BorderSide(color: Colors.red), // Add border
                    ),
                  ),
                  onPressed: onCancel,
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      fontFamily: 'Poppins', // Change font family
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
