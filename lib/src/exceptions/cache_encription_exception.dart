// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:lizard/src/exceptions/base_exception.dart';

class BadFormedCacheKey implements BaseException {
  @override
  final String message;
  BadFormedCacheKey({
    required this.message,
  });
  


  @override
  String toString() => 'BadFormedCacheKey(message: $message)';

  
}
