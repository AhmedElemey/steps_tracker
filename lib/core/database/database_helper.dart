import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/step_tracking/models/step_data.dart';
import '../../features/goals/models/goal.dart';
import '../../features/goals/models/daily_goal.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'steps_tracker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create step_data table
    await db.execute('''
      CREATE TABLE step_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        steps INTEGER NOT NULL,
        distance REAL NOT NULL,
        calories INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create goals table
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_steps INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        is_active INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create daily_goals table
    await db.execute('''
      CREATE TABLE daily_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_steps INTEGER NOT NULL,
        target_calories INTEGER NOT NULL,
        target_distance REAL NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create index on date for faster queries
    await db.execute('''
      CREATE INDEX idx_step_data_date ON step_data(date)
    ''');
  }

  // Step Data Methods
  Future<int> insertStepData(StepData stepData) async {
    final db = await database;
    final map = stepData.toMap();
    // Remove id from map for new inserts to let SQLite auto-generate it
    map.remove('id');
    return await db.insert('step_data', map);
  }

  Future<int> updateStepData(StepData stepData) async {
    final db = await database;
    return await db.update(
      'step_data',
      stepData.toMap(),
      where: 'id = ?',
      whereArgs: [stepData.id],
    );
  }

  Future<StepData?> getStepDataByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0]; // Get YYYY-MM-DD format
    
    final List<Map<String, dynamic>> maps = await db.query(
      'step_data',
      where: 'date LIKE ?',
      whereArgs: ['$dateStr%'],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return StepData.fromMap(maps.first);
    }
    return null;
  }

  Future<List<StepData>> getStepDataInRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'step_data',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return StepData.fromMap(maps[i]);
    });
  }

  Future<List<StepData>> getAllStepData() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'step_data',
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return StepData.fromMap(maps[i]);
    });
  }

  Future<int> deleteStepData(int id) async {
    final db = await database;
    return await db.delete(
      'step_data',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Goals Methods
  Future<int> insertGoal(Goal goal) async {
    final db = await database;
    return await db.insert('goals', goal.toMap());
  }

  Future<int> updateGoal(Goal goal) async {
    final db = await database;
    return await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<Goal?> getActiveGoal() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'goals',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Goal.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Goal>> getAllGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'goals',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Goal.fromMap(maps[i]);
    });
  }

  Future<int> deleteGoal(int id) async {
    final db = await database;
    return await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deactivateAllGoals() async {
    final db = await database;
    await db.update(
      'goals',
      {'is_active': 0},
    );
  }

  // Daily Goals Methods
  Future<int> insertDailyGoal(DailyGoal dailyGoal) async {
    final db = await database;
    return await db.insert('daily_goals', dailyGoal.toMap());
  }

  Future<int> updateDailyGoal(DailyGoal dailyGoal) async {
    final db = await database;
    return await db.update(
      'daily_goals',
      dailyGoal.toMap(),
      where: 'id = ?',
      whereArgs: [dailyGoal.id],
    );
  }

  Future<DailyGoal?> getActiveDailyGoal() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_goals',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return DailyGoal.fromMap(maps.first);
    }
    return null;
  }

  Future<List<DailyGoal>> getAllDailyGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_goals',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return DailyGoal.fromMap(maps[i]);
    });
  }

  Future<int> deleteDailyGoal(int id) async {
    final db = await database;
    return await db.delete(
      'daily_goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}