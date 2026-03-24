import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Cross-Platform SQLite Datenbank
/// Funktioniert auf: Android, iOS, Windows, macOS, Linux, Web
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Desktop (Windows, Linux, macOS) benötigt FFI-Initialisierung
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'health_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // BMI Einträge
    await db.execute('''
      CREATE TABLE bmi_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        height REAL NOT NULL,
        bmi REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Wasser-Tracker
    await db.execute('''
      CREATE TABLE water_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount_ml INTEGER NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Aktivitäts-Tracker
    await db.execute('''
      CREATE TABLE activity_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_type TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        calories_burned INTEGER NOT NULL,
        steps INTEGER DEFAULT 0,
        date TEXT NOT NULL
      )
    ''');

    // Schlaf-Tracker
    await db.execute('''
      CREATE TABLE sleep_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sleep_start TEXT NOT NULL,
        sleep_end TEXT NOT NULL,
        duration_hours REAL NOT NULL,
        quality INTEGER NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Ernährungs-Tracker
    await db.execute('''
      CREATE TABLE nutrition_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_name TEXT NOT NULL,
        calories INTEGER NOT NULL,
        protein REAL DEFAULT 0,
        carbs REAL DEFAULT 0,
        fat REAL DEFAULT 0,
        date TEXT NOT NULL
      )
    ''');
  }

  // ── BMI ─────────────────────────────────────────────
  Future<int> insertBmi(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('bmi_entries', data);
  }

  Future<List<Map<String, dynamic>>> getBmiEntries() async {
    final db = await database;
    return await db.query('bmi_entries', orderBy: 'date DESC', limit: 30);
  }

  // ── Wasser ──────────────────────────────────────────
  Future<int> insertWater(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('water_entries', data);
  }

  Future<List<Map<String, dynamic>>> getWaterToday() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await db.query(
      'water_entries',
      where: 'date LIKE ?',
      whereArgs: ['$today%'],
    );
  }

  Future<List<Map<String, dynamic>>> getWaterLast7Days() async {
    final db = await database;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return await db.query(
      'water_entries',
      where: 'date >= ?',
      whereArgs: [sevenDaysAgo.toIso8601String()],
      orderBy: 'date ASC',
    );
  }

  Future<void> deleteWaterEntry(int id) async {
    final db = await database;
    await db.delete('water_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ── Aktivität ───────────────────────────────────────
  Future<int> insertActivity(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('activity_entries', data);
  }

  Future<List<Map<String, dynamic>>> getActivitiesToday() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await db.query(
      'activity_entries',
      where: 'date LIKE ?',
      whereArgs: ['$today%'],
    );
  }

  Future<List<Map<String, dynamic>>> getActivitiesLast7Days() async {
    final db = await database;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return await db.query(
      'activity_entries',
      where: 'date >= ?',
      whereArgs: [sevenDaysAgo.toIso8601String()],
      orderBy: 'date ASC',
    );
  }

  Future<void> deleteActivity(int id) async {
    final db = await database;
    await db.delete('activity_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ── Schlaf ──────────────────────────────────────────
  Future<int> insertSleep(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('sleep_entries', data);
  }

  Future<List<Map<String, dynamic>>> getSleepEntries() async {
    final db = await database;
    return await db.query('sleep_entries', orderBy: 'date DESC', limit: 14);
  }

  Future<void> deleteSleep(int id) async {
    final db = await database;
    await db.delete('sleep_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ── Ernährung ───────────────────────────────────────
  Future<int> insertNutrition(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('nutrition_entries', data);
  }

  Future<List<Map<String, dynamic>>> getNutritionToday() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await db.query(
      'nutrition_entries',
      where: 'date LIKE ?',
      whereArgs: ['$today%'],
    );
  }

  Future<void> deleteNutrition(int id) async {
    final db = await database;
    await db.delete('nutrition_entries', where: 'id = ?', whereArgs: [id]);
  }
}
