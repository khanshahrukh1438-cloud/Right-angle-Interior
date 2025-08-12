// FILE: lib/screens/edit_attendance_screen.dart
// This screen allows editing an existing attendance record.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:right_angle_interior/models/attendance_record.dart';
import 'package:right_angle_interior/utils/database_helper.dart';

class EditAttendanceScreen extends StatefulWidget {
  final AttendanceRecord attendanceRecord;

  const EditAttendanceScreen({super.key, required this.attendanceRecord});

  @override
  State<EditAttendanceScreen> createState() => _EditAttendanceScreenState();
}

class _EditAttendanceScreenState extends State<EditAttendanceScreen> {
  late double _daysWorked;

  @override
  void initState() {
    super.initState();
    _daysWorked = widget.attendanceRecord.daysWorked;
  }

  void _saveAttendance() async {
    final updatedRecord = AttendanceRecord(
      id: widget.attendanceRecord.id,
      projectLaborerId: widget.attendanceRecord.projectLaborerId,
      date: widget.attendanceRecord.date,
      daysWorked: _daysWorked,
    );

    if (_daysWorked == 0) {
      // If attendance is set to absent, delete the record
      await DatabaseHelper.instance.deleteAttendance(updatedRecord.id);
    } else {
      await DatabaseHelper.instance.updateAttendance(updatedRecord);
    }
    Navigator.of(context).pop();
  }

  void _deleteAttendance() async {
    await DatabaseHelper.instance.deleteAttendance(widget.attendanceRecord.id);
    Navigator.of(context).pop();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Attendance for ${DateFormat.yMd().format(widget.attendanceRecord.date)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              _deleteAttendance();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attendance record deleted.'), backgroundColor: Colors.red),
              );
            },
            tooltip: 'Delete Record',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select the updated attendance value:',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 0.0, label: Text('Absent')),
                ButtonSegment(value: 0.5, label: Text('Half')),
                ButtonSegment(value: 1.0, label: Text('Full')),
                ButtonSegment(value: 1.5, label: Text('1.5x')),
                ButtonSegment(value: 2.0, label: Text('2.0x')),
              ],
              selected: {_daysWorked},
              onSelectionChanged: (Set<double> newSelection) {
                setState(() {
                  _daysWorked = newSelection.first;
                });
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: Colors.teal.shade100,
                selectedForegroundColor: Colors.teal.shade900,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _saveAttendance,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
