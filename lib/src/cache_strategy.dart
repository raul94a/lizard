
abstract class CacheStrategy {
  final int invalidationSeconds = 0;
  CacheStrategy addSeconds(int seconds);
}

class OfflineCache implements CacheStrategy {
  static const String tailKey = 'offline';
  @override
  final int invalidationSeconds;
  OfflineCache({
    required this.invalidationSeconds,
  });
  @override
  OfflineCache addSeconds(int seconds) {
    final date =
        DateTime.fromMillisecondsSinceEpoch(invalidationSeconds);
    final millis = seconds * 1000;
    final sum = date.millisecondsSinceEpoch + millis;
    return OfflineCache(invalidationSeconds: sum);
  }
}

class OnlineCache implements CacheStrategy {
  static const String tailKey = 'online';
  @override
  final int invalidationSeconds;
  OnlineCache({
    required this.invalidationSeconds,
  });

  @override
  OnlineCache addSeconds(int seconds) {
    final date =
        DateTime.fromMillisecondsSinceEpoch(invalidationSeconds);
    final millis = seconds * 1000;
    final sum = date.millisecondsSinceEpoch + millis;
    return OnlineCache(invalidationSeconds: sum);
  }
}
