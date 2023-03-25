import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart' as hive;

class CacheManager {
  static const String _box = 'http-cache';
  static CacheManager? _cacheManager;
  static CacheManager get instance => _cacheManager ??= CacheManager._();
  CacheManager._() {
    openHive();
  }
  Future<void>  openHive() async {
    final path = Directory.current.path;
    print(path);
    await hive.Hive.initFlutter();
  }

  Future<hive.Box> getBox() async {
    await _openHttpCacheBox();
    final box = hive.Hive.box(_box);
    return box;
  }

  Future<hive.Box> save(
      {required String key,
      required String value,
      String? onlineAliveCacheKey,
      dynamic onlineAliveUntil,
      String? offlineAliveCacheKey,
      dynamic offlineAliveUntil}) async {
    final box = hive.Hive.box(_box);
    box.put(key, value);
    if (onlineAliveCacheKey != null && onlineAliveUntil != null) {
      final millis =
          DateTime.now().millisecondsSinceEpoch + (onlineAliveUntil * 1000);
      box.put(onlineAliveCacheKey, millis);
    }
    if (offlineAliveCacheKey != null && offlineAliveUntil != null) {
      final millis =
          DateTime.now().millisecondsSinceEpoch + (offlineAliveUntil * 1000);

      box.put(offlineAliveCacheKey, millis);
    }
    return box;
  }

  dynamic get(hive.Box box, String key) {
    return box.get(key);
  }

  Future<void> _openHttpCacheBox() async {
    await hive.Hive.openBox(_box);
  }

  void closeBoxes() {
    hive.Hive.close();
  }
}
