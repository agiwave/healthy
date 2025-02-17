import 'dart:html';
import 'storage_interface.dart';
import '../models/health_record.dart';

StorageInterface createStorage() => WebStorage.instance;

class WebStorage implements StorageInterface {
  static final WebStorage instance = WebStorage._init();
  
  WebStorage._init();

  @override
  Future<void> init() async {
    // Web 实现不需要初始化
  }

  @override
  Future<int> insertRecord(HealthRecord record) async {
    window.localStorage[DateTime.now().millisecondsSinceEpoch.toString()] = 
        record.toMap().toString();
    return DateTime.now().millisecondsSinceEpoch;
  }

  @override
  Future<List<HealthRecord>> getRecords(String type) async {
    return window.localStorage.entries
        .map((e) => HealthRecord.fromMap(Map<String, dynamic>.from(e.value as Map)))
        .where((record) => record.type == type)
        .toList();
  }

  @override
  Future<int> updateRecord(HealthRecord record) async {
    window.localStorage[record.id.toString()] = record.toMap().toString();
    return record.id!;
  }

  @override
  Future<int> deleteRecord(int id) async {
    window.localStorage.remove(id.toString());
    return id;
  }
} 