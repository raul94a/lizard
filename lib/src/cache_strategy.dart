
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
