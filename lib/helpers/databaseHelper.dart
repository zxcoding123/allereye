import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
        version: 6, // Increment to force upgrade
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
      await _createScansTable(db);
      print('Database created with signup and scans tables');
    } catch (e) {
      print('Error creating database: $e');
      rethrow;
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    try {
      print('Upgrading database from version $oldVersion to $newVersion');
      // Older versions may or may not have the scans table, so check
      // instead of relying on the version number.
      await _createScansTable(db);
      final columns = await db.rawQuery('PRAGMA table_info(scans)');
      if (!columns.any((column) => column['name'] == 'mayContain')) {
        await db.execute('ALTER TABLE scans ADD COLUMN mayContain TEXT');
      }
    } catch (e) {
      print('Error upgrading database: $e');
      rethrow;
    }
  }

  Future<void> _createScansTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS scans (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userEmail TEXT NOT NULL,
      productName TEXT NOT NULL,
      allergensFound TEXT,
      mayContain TEXT,
      scanDate TEXT NOT NULL
    )
    ''');
  }

  Future<void> insertScan(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert('scans', row);
  }

  /// Most recent scans for one user, newest first.
  Future<List<Map<String, dynamic>>> getRecentScans(String email,
      {int limit = 10}) async {
    final db = await database;
    return db.query(
      'scans',
      where: 'userEmail = ?',
      whereArgs: [email],
      orderBy: 'scanDate DESC',
      limit: limit,
    );
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
