// ignore_for_file: public_member_api_docs, sort_constructors_first
abstract class BaseException implements Exception {
  final String message;
  BaseException({
    required this.message,
  });

  @override
  String toString() => 'BaseException(message: $message)';


}
