// FILE: lib/screens/select_project_for_attendance_screen.dart
// This screen allows the user to select a project to mark attendance for.

import 'package:flutter/material.dart';
import 'package:right_angle_interior/models/project.dart';
import 'package:right_angle_interior/screens/mark_attendance_screen.dart';
import 'package:right_angle_interior/utils/database_helper.dart';

class SelectProjectForAttendanceScreen extends StatefulWidget {
  const SelectProjectForAttendanceScreen({super.key});

  @override
  State<SelectProjectForAttendanceScreen> createState() => _SelectProjectForAttendanceScreenState();
}

class _SelectProjectForAttendanceScreenState extends State<SelectProjectForAttendanceScreen> {
  late Future<List<Project>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _refreshProjects();
  }

  void _refreshProjects() {
    setState(() {
      _projectsFuture = DatabaseHelper.instance.getProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Project for Attendance'),
      ),
      body: FutureBuilder<List<Project>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No projects found.'));
          }

          final activeProjects = snapshot.data!.where((p) => p.status == 'Ongoing').toList();

          if (activeProjects.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'There are no ongoing projects to mark attendance for.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: activeProjects.length,
            itemBuilder: (context, index) {
              final project = activeProjects[index];
              return Card(
                child: ListTile(
                  title: Text(project.name),
                  subtitle: Text(project.clientName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    if (project.assignedLaborers.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Go to Project Details to assign laborers first.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    } else {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MarkAttendanceScreen(
                            project: project,
                          ),
                        ),
                      );
                      _refreshProjects();
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
