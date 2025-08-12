// FILE: lib/utils/database_helper.dart
// This file manages all database creation and interaction logic.

import 'package:right_angle_interior/models/attendance_record.dart';
import 'package:right_angle_interior/models/expense.dart';
import 'package:right_angle_interior/models/laborer.dart';
import 'package:right_angle_interior/models/ledger_transfer.dart';
import 'package:right_angle_interior/models/measurement.dart';
import 'package:right_angle_interior/models/payer.dart';
import 'package:right_angle_interior/models/project.dart';
import 'package:right_angle_interior/models/project_laborer.dart';
import 'package:right_angle_interior/models/ra_bill.dart';
import 'package:right_angle_interior/models/settlement_payment.dart';
import 'package:right_angle_interior/models/wage_history.dart';
import 'package:right_angle_interior/models/wage_payment.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // version: 15 is important for the onUpgrade to trigger
    return await openDatabase(path, version: 15, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    // ... create projects, laborers, project_laborers, etc. tables
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        clientName TEXT NOT NULL,
        addressLine1 TEXT,
        addressLine2 TEXT,
        pincode TEXT,
        city TEXT,
        state TEXT,
        startDate TEXT NOT NULL,
        endDate TEXT,
        budget REAL NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE laborers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        fatherName TEXT,
        trade TEXT NOT NULL,
        contactNumber TEXT NOT NULL,
        address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE project_laborers (
        id TEXT PRIMARY KEY,
        projectId TEXT NOT NULL,
        laborerId TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE,
        FOREIGN KEY (laborerId) REFERENCES laborers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance_records (
        id TEXT PRIMARY KEY,
        projectLaborerId TEXT NOT NULL,
        date TEXT NOT NULL,
        daysWorked REAL NOT NULL,
        FOREIGN KEY (projectLaborerId) REFERENCES project_laborers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE wage_payments (
        id TEXT PRIMARY KEY,
        laborerId TEXT NOT NULL,
        payerId TEXT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT NOT NULL,
        FOREIGN KEY (laborerId) REFERENCES laborers (id) ON DELETE CASCADE,
        FOREIGN KEY (payerId) REFERENCES payers (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        projectId TEXT NOT NULL,
        payerId TEXT,
        description TEXT NOT NULL,
        type TEXT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE,
        FOREIGN KEY (payerId) REFERENCES payers (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE wage_history (
        id TEXT PRIMARY KEY,
        laborerId TEXT NOT NULL,
        perDayWage REAL NOT NULL,
        effectiveDate TEXT NOT NULL,
        FOREIGN KEY (laborerId) REFERENCES laborers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE measurements (
        id TEXT PRIMARY KEY,
        raBillId TEXT NOT NULL,
        description TEXT NOT NULL,
        length REAL NOT NULL,
        width REAL NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        rate REAL NOT NULL,
        FOREIGN KEY (raBillId) REFERENCES ra_bills (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ra_bills (
        id TEXT PRIMARY KEY,
        projectId TEXT NOT NULL,
        billName TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE payers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        openingBalance REAL NOT NULL DEFAULT 0.0,
        isCompanyAccount INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE settlement_payments (
        id TEXT PRIMARY KEY,
        payerId TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (payerId) REFERENCES payers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ledger_transfers (
        id TEXT PRIMARY KEY,
        fromPayerId TEXT NOT NULL,
        toPayerId TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (fromPayerId) REFERENCES payers (id) ON DELETE CASCADE,
        FOREIGN KEY (toPayerId) REFERENCES payers (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // ... previous upgrade steps remain the same
    if (oldVersion < 15) {
      await db.execute('ALTER TABLE payers ADD COLUMN openingBalance REAL NOT NULL DEFAULT 0.0');
      await db.execute('''
        CREATE TABLE ledger_transfers (
          id TEXT PRIMARY KEY,
          fromPayerId TEXT NOT NULL,
          toPayerId TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          FOREIGN KEY (fromPayerId) REFERENCES payers (id) ON DELETE CASCADE,
          FOREIGN KEY (toPayerId) REFERENCES payers (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // --- Project Methods ---
  Future<void> insertProject(Project project) async {
    final db = await instance.database;
    await db.insert('projects', project.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProject(Project project) async {
    final db = await instance.database;
    await db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<List<Project>> getProjects() async {
    final db = await instance.database;
    final maps = await db.query('projects');
    if (maps.isEmpty) return [];

    List<Project> projects = [];
    for (var map in maps) {
      final project = Project.fromMap(map);
      project.assignedLaborers = await getAssignedLaborers(project.id);
      project.expenses = await getExpenses(project.id);
      projects.add(project);
    }
    return projects;
  }

  Future<void> deleteProject(String id) async {
    final db = await instance.database;
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  // --- Laborer Methods ---
  Future<void> insertLaborer(Laborer laborer) async {
    final db = await instance.database;
    await db.insert('laborers', laborer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateLaborer(Laborer laborer) async {
    final db = await instance.database;
    await db.update(
      'laborers',
      laborer.toMap(),
      where: 'id = ?',
      whereArgs: [laborer.id],
    );
  }

  Future<List<Laborer>> getLaborers() async {
    final db = await instance.database;
    final maps = await db.query('laborers');
    if (maps.isEmpty) return [];

    List<Laborer> laborers = [];
    for (var map in maps) {
      final laborer = Laborer.fromMap(map);
      laborer.wageHistory = await getWageHistoryForLaborer(laborer.id);
      laborers.add(laborer);
    }
    return laborers;
  }

  Future<void> deleteLaborer(String id) async {
    final db = await instance.database;
    await db.delete('laborers', where: 'id = ?', whereArgs: [id]);
  }

  // --- ProjectLaborer (Assignment) Methods ---
  Future<void> assignLaborerToProject(ProjectLaborer projectLaborer) async {
    final db = await instance.database;
    await db.insert('project_laborers', projectLaborer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> unassignLaborerFromProject(String id) async {
    final db = await instance.database;
    await db.update(
      'project_laborers',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> reassignLaborerToProject(String id) async {
    final db = await instance.database;
    await db.update(
      'project_laborers',
      {'isActive': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ProjectLaborer>> getAssignedLaborers(String projectId) async {
    final db = await instance.database;
    final maps = await db.query('project_laborers', where: 'projectId = ?', whereArgs: [projectId]);
    if (maps.isEmpty) return [];

    List<ProjectLaborer> assignedLaborers = [];
    for (var map in maps) {
      final laborerData = await db.query('laborers', where: 'id = ?', whereArgs: [map['laborerId']]);
      if(laborerData.isNotEmpty) {
        final laborer = Laborer.fromMap(laborerData.first);
        laborer.wageHistory = await getWageHistoryForLaborer(laborer.id);
        final projectLaborer = ProjectLaborer.fromMap(map, laborer);
        projectLaborer.attendance = await getAttendanceRecords(projectLaborer.id);
        assignedLaborers.add(projectLaborer);
      }
    }
    return assignedLaborers;
  }

  Future<List<ProjectLaborer>> getProjectsForLaborer(String laborerId) async {
    final db = await instance.database;
    final maps = await db.query('project_laborers', where: 'laborerId = ?', whereArgs: [laborerId]);
    if (maps.isEmpty) return [];

    List<ProjectLaborer> assignments = [];
    for (var map in maps) {
      final laborerData = await db.query('laborers', where: 'id = ?', whereArgs: [laborerId]);
      if (laborerData.isNotEmpty) {
        final laborer = Laborer.fromMap(laborerData.first);
        laborer.wageHistory = await getWageHistoryForLaborer(laborer.id);
        final projectLaborer = ProjectLaborer.fromMap(map, laborer);
        projectLaborer.attendance = await getAttendanceRecords(projectLaborer.id);
        assignments.add(projectLaborer);
      }
    }
    return assignments;
  }

  // --- Attendance Methods ---
  Future<void> insertAttendance(AttendanceRecord record) async {
    final db = await instance.database;
    await db.insert('attendance_records', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAttendance(AttendanceRecord record) async {
    final db = await instance.database;
    await db.update(
      'attendance_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> deleteAttendance(String id) async {
    final db = await instance.database;
    await db.delete('attendance_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<AttendanceRecord>> getAttendanceRecords(String projectLaborerId) async {
    final db = await instance.database;
    final maps = await db.query('attendance_records', where: 'projectLaborerId = ?', whereArgs: [projectLaborerId]);
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => AttendanceRecord.fromMap(maps[i]));
  }

  // --- Wage Payment Methods ---
  Future<void> insertWagePayment(WagePayment payment) async {
    final db = await instance.database;
    await db.insert('wage_payments', payment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateWagePayment(WagePayment payment) async {
    final db = await instance.database;
    await db.update(
      'wage_payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<void> deleteWagePayment(String id) async {
    final db = await instance.database;
    await db.delete('wage_payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<WagePayment>> getWagePayments(String laborerId) async {
    final db = await instance.database;
    final maps = await db.query('wage_payments', where: 'laborerId = ?', whereArgs: [laborerId]);
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => WagePayment.fromMap(maps[i]));
  }

  Future<List<WagePayment>> getWagePaymentsByPayer(String payerId) async {
    final db = await instance.database;
    final maps = await db.query('wage_payments', where: 'payerId = ?', whereArgs: [payerId]);
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => WagePayment.fromMap(maps[i]));
  }

  // --- Expense Methods ---
  Future<void> insertExpense(Expense expense) async {
    final db = await instance.database;
    await db.insert('expenses', expense.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await instance.database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await instance.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getExpenses(String projectId) async {
    final db = await instance.database;
    final maps = await db.query('expenses', where: 'projectId = ?', whereArgs: [projectId]);
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<List<Expense>> getExpensesByPayer(String payerId) async {
    final db = await instance.database;
    final maps = await db.query('expenses', where: 'payerId = ?', whereArgs: [payerId]);
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  // --- Wage History Methods ---
  Future<void> insertWageHistory(WageHistory wageHistory) async {
    final db = await instance.database;
    await db.insert('wage_history', wageHistory.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<WageHistory>> getWageHistoryForLaborer(String laborerId) async {
    final db = await instance.database;
    final maps = await db.query('wage_history', where: 'laborerId = ?', whereArgs: [laborerId], orderBy: 'effectiveDate DESC');
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => WageHistory.fromMap(maps[i]));
  }

  // --- Measurement Methods ---
  Future<void> insertMeasurement(Measurement measurement) async {
    final db = await instance.database;
    await db.insert('measurements', measurement.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertMultipleMeasurements(List<Measurement> measurements) async {
    final db = await instance.database;
    Batch batch = db.batch();
    for (var measurement in measurements) {
      batch.insert('measurements', measurement.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateMeasurement(Measurement measurement) async {
    final db = await instance.database;
    await db.update(
      'measurements',
      measurement.toMap(),
      where: 'id = ?',
      whereArgs: [measurement.id],
    );
  }

  Future<void> deleteMeasurement(String id) async {
    final db = await instance.database;
    await db.delete('measurements', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Measurement>> getMeasurements(String raBillId) async {
    final db = await instance.database;
    final maps = await db.query('measurements', where: 'raBillId = ?', whereArgs: [raBillId]);
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => Measurement.fromMap(maps[i]));
  }

  // --- RA Bill Methods ---
  Future<void> insertRABill(RABill bill) async {
    final db = await instance.database;
    await db.insert('ra_bills', bill.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateRABill(RABill bill) async {
    final db = await instance.database;
    await db.update(
      'ra_bills',
      bill.toMap(),
      where: 'id = ?',
      whereArgs: [bill.id],
    );
  }

  Future<void> deleteRABill(String id) async {
    final db = await instance.database;
    await db.delete('ra_bills', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<RABill>> getRABills(String projectId) async {
    final db = await instance.database;
    final maps = await db.query('ra_bills', where: 'projectId = ?', whereArgs: [projectId]);
    if (maps.isEmpty) return [];

    List<RABill> bills = [];
    for (var map in maps) {
      final bill = RABill.fromMap(map);
      bill.measurements = await getMeasurements(bill.id);
      bills.add(bill);
    }
    return bills;
  }

  // --- Payer Methods ---
  Future<void> insertPayer(Payer payer) async {
    final db = await instance.database;
    await db.insert('payers', payer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePayer(Payer payer) async {
    final db = await instance.database;
    await db.update(
      'payers',
      payer.toMap(),
      where: 'id = ?',
      whereArgs: [payer.id],
    );
  }

  Future<void> deletePayer(String id) async {
    final db = await instance.database;
    await db.delete('payers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Payer>> getPayers() async {
    final db = await instance.database;
    final maps = await db.query('payers');
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => Payer.fromMap(maps[i]));
  }

  // --- Settlement Payment Methods ---
  Future<void> insertSettlementPayment(SettlementPayment payment) async {
    final db = await instance.database;
    await db.insert('settlement_payments', payment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SettlementPayment>> getSettlementPaymentsForPayer(String payerId) async {
    final db = await instance.database;
    final maps = await db.query('settlement_payments', where: 'payerId = ?', whereArgs: [payerId]);
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => SettlementPayment.fromMap(maps[i]));
  }

  // --- Ledger Transfer Methods ---
  Future<void> insertLedgerTransfer(LedgerTransfer transfer) async {
    final db = await instance.database;
    await db.insert('ledger_transfers', transfer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<LedgerTransfer>> getLedgerTransfersForPayer(String payerId) async {
    final db = await instance.database;
    final maps = await db.query('ledger_transfers', where: 'fromPayerId = ? OR toPayerId = ?', whereArgs: [payerId, payerId]);
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => LedgerTransfer.fromMap(maps[i]));
  }
}
