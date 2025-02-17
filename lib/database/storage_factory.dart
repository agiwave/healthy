import 'storage_interface.dart';
import 'storage_stub.dart'
    if (dart.library.html) 'web_storage.dart'
    if (dart.library.io) 'sqlite_storage.dart';

class StorageFactory {
  static StorageInterface? _instance;

  static StorageInterface get instance {
    _instance ??= createStorage();
    return _instance!;
  }
} 