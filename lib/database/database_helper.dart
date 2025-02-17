import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/health_record.dart';
import '../models/indicator_type.dart';
import 'dart:async';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Add a StreamController to notify about changes
  final StreamController<void> _updateController = StreamController.broadcast();

  // Expose a stream for listeners to subscribe to
  Stream<void> get onUpdate => _updateController.stream;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('health_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // 删除现有数据库文件（仅用于开发测试）
    // await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        // 检查表是否存在
        final tables = await db.query('sqlite_master', 
            where: 'type = ? AND name = ?',
            whereArgs: ['table', 'indicator_types']);
        
        // 如果表为空，插入默认数据
        if (tables.isEmpty) {
          await _createDB(db, 1);
        } else {
          final count = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM indicator_types'));
          if (count == 0) {
            // 插入默认指标
            await db.insert('indicator_types', {
              'code': 'blood_pressure',
              'name': '血压',
              'unit': 'mmHg',
              'is_multi_value': 1,
              'secondary_name': '舒张压'
            });

            await db.insert('indicator_types', {
              'code': 'heart_rate',
              'name': '心率',
              'unit': 'bpm',
              'is_multi_value': 0,
              'secondary_name': null
            });
          }
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 创建指标类型表
    await db.execute('''
      CREATE TABLE indicator_types(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        is_multi_value INTEGER NOT NULL DEFAULT 0,
        secondary_name TEXT
      )
    ''');

    // 创建健康记录表
    await db.execute('''
      CREATE TABLE health_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        value REAL NOT NULL,
        systolic REAL,
        diastolic REAL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (type) REFERENCES indicator_types(code)
      )
    ''');
  }

  Future<int> insertRecord(HealthRecord record) async {
    final db = await database;
    return await db.insert('health_records', record.toMap());
  }

  Future<List<HealthRecord>> getRecords(String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'health_records',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => HealthRecord.fromMap(maps[i]));
  }

  Future<int> updateRecord(HealthRecord record) async {
    final db = await database;
    return await db.update(
      'health_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete(
      'health_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 添加指标类型相关方法
  Future<List<IndicatorType>> getIndicatorTypes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('indicator_types');
    return List.generate(maps.length, (i) => IndicatorType.fromMap(maps[i]));
  }

  Future<int> insertIndicatorType(IndicatorType type) async {
    final db = await database;
    final result = await db.insert('indicator_types', type.toMap());
    _updateController.add(null); // Notify listeners
    return result;
  }

  Future<int> updateIndicatorType(IndicatorType type) async {
    final db = await database;
    final result = await db.update(
      'indicator_types',
      type.toMap(),
      where: 'id = ?',
      whereArgs: [type.id],
    );
    _updateController.add(null); // Notify listeners
    return result;
  }

  Future<int> deleteIndicatorType(int id) async {
    final db = await database;
    // 先删除相关的健康记录
    await db.delete(
      'health_records',
      where: 'type = (SELECT code FROM indicator_types WHERE id = ?)',
      whereArgs: [id],
    );
    // 再删除指标类型
    final result = await db.delete(
      'indicator_types',
      where: 'id = ?',
      whereArgs: [id],
    );
    _updateController.add(null); // Notify listeners
    return result;
  }
} 