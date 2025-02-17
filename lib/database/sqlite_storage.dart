import 'package:sqflite/sqflite.dart';
import '../models/health_record.dart';
import 'storage_interface.dart';
import 'database_helper.dart';

StorageInterface createStorage() => SQLiteStorage.instance;

class SQLiteStorage implements StorageInterface {
  static final SQLiteStorage instance = SQLiteStorage._init();
  static Database? _database;

  SQLiteStorage._init();

  @override
  Future<void> init() async {
    if (_database != null) return;
    _database = await _initDB('health_tracker.db');
  }

  Future<Database> _initDB(String filePath) async {
    return await DatabaseHelper.instance.database;
  }

  @override
  Future<int> insertRecord(HealthRecord record) async {
    final db = _database!;
    return await db.insert('health_records', record.toMap());
  }

  @override
  Future<List<HealthRecord>> getRecords(String type) async {
    final db = _database!;
    final List<Map<String, dynamic>> maps = await db.query(
      'health_records',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => HealthRecord.fromMap(maps[i]));
  }

  @override
  Future<int> updateRecord(HealthRecord record) async {
    final db = _database!;
    return await db.update(
      'health_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  @override
  Future<int> deleteRecord(int id) async {
    final db = _database!;
    return await db.delete(
      'health_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
} 