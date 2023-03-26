// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart' as hive;
import 'package:http/http.dart' as http;
import 'package:lizard/src/cache_encryption_key.dart';
import 'package:lizard/src/cache_manager.dart';
import 'package:lizard/src/cache_strategy.dart';

void main(List<String> args) async {
  Lizard.initializeEncryptionKey(key: 'aa');
  final lizard =
      Lizard().setOnlineCache(seconds: 15).setOfflineCache(seconds: 600);
  final res = await lizard.get(
    Uri.parse('https://rickandmortyapi.com/api/episode'),
  );
  print(res.body);
}

class Lizard {
  //one day
  static const int _defaultOfflineCacheSeconds = 60 * 60 * 24;
  static CacheEncryptionKey? _encryptionKey;
  //30 seconds
  static const int _defaultOnlineCacheSeconds = 30;

  static void initializeEncryptionKey({required String key}) {
    if (_encryptionKey == null) {
      try {
        _encryptionKey = CacheEncryptionKey.fromString(key: key);
      } catch (exception) {
        print(exception);
        _encryptionKey = null;
      }
    }
  }

  OfflineCache? offlineCache;
  OnlineCache? onlineCache;
  Lizard({
    this.offlineCache,
    this.onlineCache,
  });

  Lizard setOfflineCache({required int seconds}) {
    return _copyWith(
        offlineCache: OfflineCache(invalidationMillisFromEpoch: seconds));
  }

  Lizard setOnlineCache({required int seconds}) {
    return _copyWith(
        onlineCache: OnlineCache(invalidationMillisFromEpoch: seconds));
  }

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    bool onlineCacheIsSet = false;
    bool offlineCacheIsSet = false;
    final cacheManager = CacheManager.instance;
    await cacheManager.openHive();
    hive.Box box = await cacheManager.getBox(_encryptionKey?.key);
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
      final response = await http.get(uri, headers: headers);

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

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    try {
      final response = await http.post(url,
          headers: headers, body: body, encoding: encoding);
      return response;
    } catch (ex) {
      rethrow;
    }
  }

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    try {
      final response =
          await http.put(url, headers: headers, body: body, encoding: encoding);
      return response;
    } catch (ex) {
      rethrow;
    }
  }

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    try {
      final response = await http.delete(url,
          headers: headers, body: body, encoding: encoding);
      return response;
    } catch (ex) {
      rethrow;
    }
  }

  Lizard _copyWith({
    OfflineCache? offlineCache,
    OnlineCache? onlineCache,
  }) {
    return Lizard(
      offlineCache: offlineCache ?? this.offlineCache,
      onlineCache: onlineCache ?? this.onlineCache,
    );
  }
}
