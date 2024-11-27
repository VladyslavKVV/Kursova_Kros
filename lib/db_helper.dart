import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  DBHelper._internal();

  factory DBHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'workouts.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE workouts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER,
            date TEXT,
            exercise TEXT,
            repetitions INTEGER,
            weight REAL,
            FOREIGN KEY (userId) REFERENCES users (id)
          );
        ''');
      },
      version: 1,
    );
  }

  Future<int> insertUser(String username, String password) async {
    final db = await database;
    return await db.insert('users', {'username': username, 'password': password});
  }

  Future<Map<String, dynamic>?> getUser(String username, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> insertWorkout(int userId, String date, String exercise, int repetitions, double? weight) async {
    final db = await database;
    return await db.insert('workouts', {
      'userId': userId,
      'date': date,
      'exercise': exercise,
      'repetitions': repetitions,
      'weight': weight ?? 0.0,
    });
  }

  Future<List<Map<String, dynamic>>> getWorkouts(int userId) async {
    final db = await database;
    return await db.query(
      'workouts',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }
}
