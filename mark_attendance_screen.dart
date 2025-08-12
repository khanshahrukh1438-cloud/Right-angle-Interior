// FILE: lib/screens/mark_attendance_screen.dart
// This screen allows marking attendance for all laborers on a project for a specific date.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:right_angle_interior/models/project.dart';
import 'package:right_angle_interior/models/attendance_record.dart';
import 'package:right_angle_interior/utils/database_helper.dart';
import 'package:uuid/uuid.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final Project project;

  const MarkAttendanceScreen({super.key, required this.project});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  // A map to hold the attendance choice for each laborer for the selected date.
  late Map<String, double> _dailyAttendance;
  // A map to hold the ID of an existing record for the selected date.
  late Map<String, String?> _existingRecordIds;

  @override
  void initState() {
    super.initState();
    _initializeAttendanceForDate();
  }

  // Sets up the initial attendance values based on existing records for the selected date.
  void _initializeAttendanceForDate() {
    _dailyAttendance = {};
    _existingRecordIds = {};
    for (var pLaborer in widget.project.assignedLaborers) {
      final existingRecord = pLaborer.attendance.firstWhere(
            (rec) => DateUtils.isSameDay(rec.date, _selectedDate),
        orElse: () => AttendanceRecord(id: '', projectLaborerId: '', date: _selectedDate, daysWorked: 0.0),
      );
      _dailyAttendance[pLaborer.id] = existingRecord.daysWorked;
      // Store the ID if a record exists
      _existingRecordIds[pLaborer.id] = existingRecord.id.isNotEmpty ? existingRecord.id : null;
    }
  }

  // Shows a date picker to change the selected date.
  void _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _initializeAttendanceForDate();
      });
    }
  }

  // *** UPDATED: Logic to handle inserting, updating, or deleting attendance records ***
  void _saveAttendance() async {
    for (var pLaborer in widget.project.assignedLaborers) {
      final daysWorked = _dailyAttendance[pLaborer.id] ?? 0.0;
      final existingId = _existingRecordIds[pLaborer.id];

      if (existingId != null) {
        // A record for this day already exists
        if (daysWorked > 0) {
          // Update the existing record
          final updatedRecord = AttendanceRecord(
            id: existingId,
            projectLaborerId: pLaborer.id,
            date: _selectedDate,
            daysWorked: daysWorked,
          );
          await DatabaseHelper.instance.updateAttendance(updatedRecord);
        } else {
          // If the updated value is 0 (Absent), delete the record
          await DatabaseHelper.instance.deleteAttendance(existingId);
        }
      } else if (daysWorked > 0) {
        // No record exists, and the user marked attendance, so insert a new one
        final newRecord = AttendanceRecord(
          id: const Uuid().v4(),
          projectLaborerId: pLaborer.id,
          date: _selectedDate,
          daysWorked: daysWorked,
        );
        await DatabaseHelper.instance.insertAttendance(newRecord);
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAttendance,
            tooltip: 'Save Attendance',
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.yMMMMd().format(_selectedDate),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton(
                  onPressed: _pickDate,
                  child: const Text('Change Date'),
                )
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.project.assignedLaborers.length,
              itemBuilder: (ctx, index) {
                final projectLaborer = widget.project.assignedLaborers[index];
                final currentAttendance = _dailyAttendance[projectLaborer.id] ?? 0.0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          projectLaborer.laborer.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<double>(
                          segments: const [
                            ButtonSegment(value: 0.0, label: Text('Absent')),
                            ButtonSegment(value: 0.5, label: Text('Half')),
                            ButtonSegment(value: 1.0, label: Text('Full')),
                            ButtonSegment(value: 1.5, label: Text('1.5x')),
                            ButtonSegment(value: 2.0, label: Text('2.0x')),
                          ],
                          selected: {currentAttendance},
                          onSelectionChanged: (Set<double> newSelection) {
                            setState(() {
                              _dailyAttendance[projectLaborer.id] = newSelection.first;
                            });
                          },
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: Colors.teal.shade100,
                            selectedForegroundColor: Colors.teal.shade900,
                          ),
                        )
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
  }
}
