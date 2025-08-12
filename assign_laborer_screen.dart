// FILE: lib/screens/assign_laborer_screen.dart
// This screen displays a list of all available laborers to assign to a project.

import 'package:flutter/material.dart';
import 'package:right_angle_interior/models/laborer.dart';
import 'package:right_angle_interior/utils/database_helper.dart';

class AssignLaborerScreen extends StatefulWidget {
  const AssignLaborerScreen({super.key});

  @override
  State<AssignLaborerScreen> createState() => _AssignLaborerScreenState();
}

class _AssignLaborerScreenState extends State<AssignLaborerScreen> {
  late Future<List<Laborer>> _laborersFuture;

  @override
  void initState() {
    super.initState();
    _laborersFuture = DatabaseHelper.instance.getLaborers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Laborer'),
      ),
      body: FutureBuilder<List<Laborer>>(
        future: _laborersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No laborers found. Go to the "Labor" section to add one.'));
          }

          final availableLaborers = snapshot.data!;
          return ListView.builder(
            itemCount: availableLaborers.length,
            itemBuilder: (context, index) {
              final laborer = availableLaborers[index];
              return ListTile(
                title: Text(laborer.name),
                subtitle: Text(laborer.trade),
                onTap: () {
                  // When a laborer is tapped, pop the screen and return the selected laborer.
                  Navigator.of(context).pop(laborer);
                },
              );
            },
          );
        },
      ),
    );
  }
}
