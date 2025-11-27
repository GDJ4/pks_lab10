import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models.dart';

/// Открытие SQLite, создание таблиц и базовый CRUD по задачам.
class DBHelper {
  static const _dbName = 'app.db';
  static const _dbVersion = 1;
  static const tasksTable = 'tasks';

  static Database? _db;

  static Future<Database> _open() async {
    if (_db != null) return _db!;

    final docs = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docs.path, _dbName);

    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tasksTable(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            done INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL
          );
        ''');
        await db.execute('CREATE INDEX idx_tasks_created_at ON $tasksTable(created_at DESC);');
      },
      onUpgrade: (db, oldV, newV) async {
        // Добавляйте миграции по мере изменения схемы.
      },
    );

    return _db!;
  }

  static Future<List<Task>> fetchTasks() async {
    final db = await _open();
    final rows = await db.query(tasksTable, orderBy: 'created_at DESC');
    return rows.map((m) => Task.fromMap(m)).toList();
  }

  static Future<Task> insertTask(Task task) async {
    final db = await _open();
    final id = await db.insert(
      tasksTable,
      task.toMap(withId: false),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return task.copyWith(id: id);
  }

  static Future<int> updateTask(Task task) async {
    final db = await _open();
    return db.update(
      tasksTable,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  static Future<int> deleteTask(int id) async {
    final db = await _open();
    return db.delete(tasksTable, where: 'id = ?', whereArgs: [id]);
  }
}
