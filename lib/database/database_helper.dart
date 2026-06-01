import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE tasks (
        id $idType,
        title $textType,
        description TEXT,
        priority $intType,
        isCompleted $intType,
        isDeleted $intType DEFAULT 0,
        timerDuration INTEGER,
        createdAt $textType,
        completedAt TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN isDeleted INTEGER NOT NULL DEFAULT 0');
    }
  }

  Future<int> createTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  // 🔹 НОВЫЙ МЕТОД: Получить все задачи (для статистики)
  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'isDeleted = ?',
      whereArgs: [0],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<Task>> getActiveTasks() async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'isCompleted = ? AND isDeleted = ?',
      whereArgs: [0, 0],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<Task>> getCompletedTasks() async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'isCompleted = ? AND isDeleted = ?',
      whereArgs: [1, 0],
      orderBy: 'completedAt DESC',
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<Task>> getTrashedTasks() async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'isDeleted = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> moveToTrash(int id) async {
    final db = await database;
    return await db.update('tasks', {'isDeleted': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> restoreFromTrash(int id) async {
    final db = await database;
    return await db.update('tasks', {'isDeleted': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> restoreTask(int id) async {
    final db = await database;
    return await db.update(
      'tasks',
      {'isCompleted': 0, 'completedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePermanently(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearTrash() async {
    final db = await database;
    return await db.delete('tasks', where: 'isDeleted = ?', whereArgs: [1]);
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}