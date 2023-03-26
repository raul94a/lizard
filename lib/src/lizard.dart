// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart' as hive;
import 'package:http/http.dart' as http;
import 'package:lizard/src/cache_encryption_key.dart';
import 'package:lizard/src/cache_manager.dart';
import 'package:lizard/src/cache_strategy.dart';


///Example of usage:
///```dart
/// //The offline and cache seconds can be configured for each individual request
/// final lizard = Lizard().setOfflineCache(seconds: 60 * 60 * 24).setOnlineCache(seconds : 20);
/// 
/// final response = await lizard.get(Uri.parse('ENDPOINT_URL'));
/// 
/// 
/// 
/// //Also, the API offers a way for the encryption of the cache. The key is used globally for store all the cached responses.
/// //Once the encription key is set, you cannot set it up again. It's recommended to declare it at the app start.
/// //the key must not be empty. Otherwise a BadFormedCacheKey exception will be raised.
/// Lizard.initializeEncryptionKey(key: 'MY_ENCRYPTION_KEY);
///
///```
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
  ///[offlineCache] declares the invalidation time for the cache in case the internet connection is gone. 
  ///_You can set a invalidation cache time for each individual request_.
  OfflineCache? offlineCache;
  
  ///[onlineCache] declares the invalidation time for the cache before the request is made. If there is a cache for
  ///the request and the invalidation time is still valid, the cached response will be returned.
  ///
  ///Even though the internet connection is lost, if a cache exists and the online invalidation time is valid, the cached response will be
  ///returned. For this reason, it is recomended that the onlineCache invalidation time is lower than the offlineCache invalidation time. 
  ///You can set a invalidation cache time for each individual request.
  ///
  ///Example:
  ///```dart
  /// //the online cache will be of 30 seconds and the offline cache will be of one day
  /// final lizard = Lizard().setOfflineCache(seconds: 60 * 60 * 24).setOnlineCache(seconds: 30)
  ///```
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
    //this will starts Hive
    await cacheManager.openHive();
    hive.Box box = await cacheManager.getBox(_encryptionKey?.key);
    final onlineInvalidationCacheKey =
        '${uri.toString()}-alive-${OnlineCache.tailKey}';

    //online cache - beware if there's not internet connection but the Online cache is not yet invalidated,
    //the cache will be fetched using the online invalidation restriction.
    
    if (onlineCache != null) {
      onlineCacheIsSet = true;
      //check the online cache key
      final cachedResponse = box.get(uri.toString()) as String?;
      final onlineAliveCacheMillis = box.get(onlineInvalidationCacheKey) as int?;
      if (cachedResponse != null &&
          onlineAliveCacheMillis != null &&
          (DateTime.now().millisecondsSinceEpoch < onlineAliveCacheMillis)) {
        print('Accessing to cached response');
        return http.Response.bytes(cachedResponse.codeUnits, 200);
      }
    }

    if (offlineCache != null) {
      offlineCacheIsSet = true;
    }

    final offlineInvalidationCacheKey =
        '${uri.toString()}-alive-${OfflineCache.tailKey}';

    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200 || response.statusCode == 204) {
        //not needed to be awaited
        cacheManager.save(
            key: uri.toString(),
            value: response.body,
            onlineAliveCacheKey: onlineInvalidationCacheKey,
            onlineAliveUntil: onlineCacheIsSet
                ? onlineCache?.invalidationMillisFromEpoch
                : _defaultOnlineCacheSeconds,
            offlineAliveCacheKey: offlineInvalidationCacheKey,
            offlineAliveUntil: offlineCacheIsSet
                ? offlineCache?.invalidationMillisFromEpoch
                : _defaultOfflineCacheSeconds);
      }

      return response;
    } on SocketException {
      //offline cache
      final invalidateIn = box.get(offlineInvalidationCacheKey) as int?;
      final cache = box.get(uri.toString()) as String?;
      //the cache does not exist
      if (cache == null || invalidateIn == null) {
        throw Exception('SocketException');
      }
  
      //there is a cache, but it is not valid anymore
      if (DateTime.now().millisecondsSinceEpoch > invalidateIn) {
        throw Exception('SocketException');
      }
      print('Accessing to offline cache');
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
