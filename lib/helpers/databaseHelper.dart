import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null && !_database!.isOpen) {
      _database = null; // Reset if database is closed
    }
    if (_database == null) {
      _database = await _initDB('signup.db');
    }
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    print('Database path: $path'); // Debug

    try {
      return await openDatabase(
        path,
        version: 5, // Increment to force upgrade
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
        onOpen: (db) async {
          print('Database opened, version: ${await db.getVersion()}');
        },
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    try {
      await db.execute('''
      CREATE TABLE signup (
        email TEXT PRIMARY KEY,
        password TEXT NOT NULL,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        dateOfBirth TEXT,
        height REAL,
        weight REAL,
        visualImpairment TEXT,
        allergens TEXT,
        otherAllergens TEXT
      )
      ''');
      await db.execute('''
      CREATE TABLE scans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userEmail TEXT NOT NULL,
        productName TEXT NOT NULL,
        allergensFound TEXT,
        scanDate TEXT NOT NULL
      )
      ''');
      print('Database created with signup and scans tables');
    } catch (e) {
      print('Error creating database: $e');
      rethrow;
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    try {
      print('Upgrading database from version $oldVersion to $newVersion');
      if (oldVersion > 2) {
        await db.execute('''
        CREATE TABLE scans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userEmail TEXT NOT NULL,
          productName TEXT NOT NULL,
          allergensFound TEXT,
          scanDate TEXT NOT NULL
        )
        ''');
        print('Added scans table in upgrade to version 2');
      }
      if (oldVersion < 3) {
        // Placeholder for future upgrades
        print('Performed upgrade to version 3 (no changes needed)');
      }
    } catch (e) {
      print('Error upgrading database: $e');
      rethrow;
    }
  }

  Future<void> insertSignUpData(Map<String, dynamic> data) async {
    final db = await database;
    try {
      await db.insert(
        'signup',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Inserted signup data for email: ${data['email']}');
    } catch (e) {
      print('Error inserting signup data: $e');
      rethrow;
    }
  }

  Future<void> updateSignUpData(Map<String, dynamic> data) async {
    final db = await database;
    try {
      await db.update(
        'signup',
        data,
        where: 'email = ?',
        whereArgs: [data['email']],
      );
      print('Updated signup data for email: ${data['email']}');
    } catch (e) {
      print('Error updating signup data: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSignUpData() async {
    final db = await database;
    try {
      final result = await db.query('signup');
      print('Retrieved ${result.length} signup records');
      return result;
    } catch (e) {
      print('Error retrieving signup data: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    try {
      final result = await db.query(
        'signup',
        where: 'email = ?',
        whereArgs: [email],
      );
      print('getUserByEmail: Found ${result.length} users for email: $email');
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Error retrieving user by email: $e');
      return null;
    }
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      print('Database closed');
    }
  }
}
