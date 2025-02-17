import 'storage_interface.dart';
import 'sqlite_storage.dart';

StorageInterface createStorage() => SQLiteStorage.instance; 