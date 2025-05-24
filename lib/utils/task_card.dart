import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:sizer/sizer.dart';

class TaskCard extends StatefulWidget {
  final Map<String, dynamic> task;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onDelete;
  final bool isDismissible;
  final bool isDailyTask;
  final VoidCallback? onEditTasks;

  const TaskCard({
    required this.task,
    required this.onChanged,
    this.onDelete,
    this.isDismissible = true,
    this.isDailyTask = false,
    this.onEditTasks,
    Key? key,
  }) : super(key: key);

  @override
  _TaskCardState createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _showDescription = false;

  @override
  Widget build(BuildContext context) {
    return widget.isDismissible
        ? Dismissible(
            key: Key(widget.task['task'] + widget.task['completed'].toString()),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              if (widget.isDailyTask) {
                return await _showDeleteAlertDialog(context, true);
              } else {
                return await _showDeleteAlertDialog(context, false);
              }
            },
            onDismissed: (direction) {
              // Reset the state of the task card
              setState(() {});
            },
            background: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(IconlyLight.delete, color: Colors.white),
            ),
            child: _buildTaskCard(),
          )
        : _buildTaskCard();
  }

  Widget _buildTaskCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                // Checkbox
                Checkbox(
                  value: widget.task['completed'] ?? false,
                  onChanged: widget.onChanged,
                ),
                // Task name
                Expanded(
                  child: Text(
                    widget.task['task'],
                    style: GoogleFonts.plusJakartaSans(
                      decoration: widget.task['completed'] == true
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: widget.task['completed'] == true
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
                // Description toggle icon
                if (!widget.isDailyTask)
                  IconButton(
                    icon: Icon(
                      _showDescription
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showDescription = !_showDescription;
                      });
                    },
                  ),
                // Draggable icon
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          if (_showDescription && !widget.isDailyTask)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  Divider(color: Colors.grey[300]),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.task['description'] ?? 'No description provided.',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteAlertDialog(
      BuildContext context, bool isDailyTask) async {
    return await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isDailyTask ? 'Cannot Delete Task' : 'Delete Task',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
              color: Colors.black87,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              isDailyTask
                  ? 'Daily tasks cannot be deleted. You can edit the tasks instead.'
                  : 'Are you sure you want to delete this task?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                color: Colors.black54,
              ),
              textAlign: TextAlign.start,
            ),
          ),
          actions: <Widget>[
            if (!isDailyTask)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                ),
                child: Text(
                  isDailyTask ? 'Edit Tasks' : 'Cancel',
                  // style: GoogleFonts.plusJakartaSans(
                  //   fontSize: 14.sp,
                  //   fontWeight: FontWeight.w500,
                  // ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(false);
                  if (isDailyTask) {
                    widget.onEditTasks?.call();
                  }
                },
              ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              ),
              child: Text(
                'Delete',
                // style: GoogleFonts.plusJakartaSans(
                //   fontSize: 14.sp,
                //   fontWeight: FontWeight.w500,
                // ),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
                widget.onDelete?.call();
              },
            ),
          ],
        );
      },
    ).then((value) {
      // Reset the state of the task card if the dialog is dismissed
      setState(() {});
      return value ?? false;
    });
  }
}
