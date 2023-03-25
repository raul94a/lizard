// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:example/src/cache_manager.dart';
import 'package:hive/hive.dart' as hive;
import 'package:http/http.dart' as http;


void main(List<String> args) async {
  final lizard =
      Lizard().setOnlineCache(seconds: 15).setOfflineCache(seconds: 600);
  final res = await lizard.get(
    Uri.parse('https://rickandmortyapi.com/api/episode'),
  );
  print(res.body);
}
typedef LizardResponse = http.Response;
class Lizard {
  //one day
  static const int _defaultOfflineCacheSeconds = 60 * 60 * 24;
  //30 seconds
  static const int _defaultOnlineCacheSeconds = 30;
  OfflineCache? offlineCache;
  OnlineCache? onlineCache;
  Lizard({
    this.offlineCache,
    this.onlineCache,
  });

  Lizard setOfflineCache({required int seconds}) {
    return copyWith(
        offlineCache: OfflineCache(invalidationMillisFromEpoch: seconds));
  }

  Lizard setOnlineCache({required int seconds}) {
    return copyWith(
        onlineCache: OnlineCache(invalidationMillisFromEpoch: seconds));
  }

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    bool onlineCacheIsSet = false;
    bool offlineCacheIsSet = false;
    final cacheManager = CacheManager.instance;
    await cacheManager.openHive();
    print('Hive is opend!!!');
    
    hive.Box box = await cacheManager.getBox();
    final onlineAliveMillisKey =
        '${uri.toString()}-alive-${OnlineCache.tailKey}';

    //online cache -
    if (onlineCache != null) {
      onlineCacheIsSet = true;
      //check the online cache key
      final cachedResponse = box.get(uri.toString()) as String?;
      final onlineAliveCacheMillis = box.get(onlineAliveMillisKey) as int?;
      if (cachedResponse != null &&
          onlineAliveCacheMillis != null &&
          (DateTime.now().millisecondsSinceEpoch < onlineAliveCacheMillis)) {
        print('GETTING DATA FROM CACHE');
        return http.Response.bytes(cachedResponse.codeUnits, 200);
      }
    }

    if (offlineCache != null) {
      offlineCacheIsSet = true;
    }

    final offlineAliveMillisKey =
        '${uri.toString()}-alive-${OfflineCache.tailKey}';
    try {
      final response = await http.get(uri, headers: headers).timeout(Duration(seconds: 20));

      cacheManager.save(
          key: uri.toString(),
          value: response.body,
          onlineAliveCacheKey: onlineAliveMillisKey,
          onlineAliveUntil: onlineCacheIsSet
              ? onlineCache?.invalidationMillisFromEpoch
              : _defaultOnlineCacheSeconds,
          offlineAliveCacheKey: offlineAliveMillisKey,
          offlineAliveUntil: offlineCacheIsSet
              ? offlineCache?.invalidationMillisFromEpoch
              : _defaultOfflineCacheSeconds);
  print('GETTING DATA FROM RESPONSE');
      return response;
    } on SocketException {
      //offline cache
      final invalidateIn = box.get(offlineAliveMillisKey) as int?;
      final cache = box.get(uri.toString()) as String?;
      //cannot use the cache... the request is gonna fail
      if (cache == null || invalidateIn == null) {
        throw Exception('SocketException');
      }
      print('Now: ${DateTime.now().millisecondsSinceEpoch}');
      print('Invalidate in: $invalidateIn');
      //there is a cache, but is not valid anymore
      if (DateTime.now().millisecondsSinceEpoch > invalidateIn) {
        throw Exception('SocketException');
      }
      print('Cache offline!');
      return http.Response.bytes(cache.codeUnits, 200);
    }
  }

  Lizard copyWith({
    OfflineCache? offlineCache,
    OnlineCache? onlineCache,
  }) {
    return Lizard(
      offlineCache: offlineCache ?? this.offlineCache,
      onlineCache: onlineCache ?? this.onlineCache,
    );
  }
}

abstract class CacheStrategy {
  final int invalidationMillisFromEpoch = 0;
  CacheStrategy addSeconds(int seconds);
}

class OfflineCache implements CacheStrategy {
  static const String tailKey = 'offline';
  @override
  final int invalidationMillisFromEpoch;
  OfflineCache({
    required this.invalidationMillisFromEpoch,
  });
  @override
  OfflineCache addSeconds(int seconds) {
    final date =
        DateTime.fromMillisecondsSinceEpoch(invalidationMillisFromEpoch);
    final millis = seconds * 1000;
    final sum = date.millisecondsSinceEpoch + millis;
    return OfflineCache(invalidationMillisFromEpoch: sum);
  }
}

class OnlineCache implements CacheStrategy {
  static const String tailKey = 'online';
  @override
  final int invalidationMillisFromEpoch;
  OnlineCache({
    required this.invalidationMillisFromEpoch,
  });

  @override
  OnlineCache addSeconds(int seconds) {
    final date =
        DateTime.fromMillisecondsSinceEpoch(invalidationMillisFromEpoch);
    final millis = seconds * 1000;
    final sum = date.millisecondsSinceEpoch + millis;
    return OnlineCache(invalidationMillisFromEpoch: sum);
  }
}
