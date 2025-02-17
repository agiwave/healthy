import '../models/health_record.dart';

abstract class StorageInterface {
  Future<void> init();
  Future<int> insertRecord(HealthRecord record);
  Future<List<HealthRecord>> getRecords(String type);
  Future<int> updateRecord(HealthRecord record);
  Future<int> deleteRecord(int id);
} 