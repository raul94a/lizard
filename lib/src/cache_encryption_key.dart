import 'package:lizard/src/exceptions/cache_encription_exception.dart';

class CacheEncryptionKey {
  CacheEncryptionKey();

  CacheEncryptionKey._createKey({required String key}) {
    _key = key;
  }

  static String _key = '';

  factory CacheEncryptionKey.fromString({required String key}) {
    if (key.isEmpty) {
      throw BadFormedCacheKey(message: 'The key value must not be empty');
    }
    int length = key.length;
    String parsedKey = key;
    if (length > 32) {
      parsedKey = key.substring(0, 32);
    } else if (length < 32) {
      parsedKey = key;
      while (parsedKey.length < 32) {
        parsedKey += parsedKey[length - 1];
      }
    }
    return CacheEncryptionKey._createKey(key: parsedKey);
  }

  String get key => _key;
}


void main(List<String> args) {

  final key = CacheEncryptionKey.fromString(key: 'a').key;
  print('key: $key => length: ${key.length}');
  final key2 = CacheEncryptionKey.fromString(key: 'abcdefghijklmnopqrstuvwxyzabcdeijflasdjflasdfkasbf').key;
  print('key: $key2 => length: ${key2.length}');
   final key3 = CacheEncryptionKey.fromString(key: '01234567890123456789012345678912').key;
  print('key: $key3 => length: ${key3.length}');
  try{

   final key2 = CacheEncryptionKey.fromString(key: '').key;
  print('key: $key2 => length: ${key2.length}');
  }catch(e){
    print(e);
  }
}