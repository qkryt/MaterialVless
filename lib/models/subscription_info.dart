class SubscriptionInfo {
  final int uploadBytes;
  final int downloadBytes;
  final int totalBytes;
  final DateTime expireDate;

  SubscriptionInfo({
    required this.uploadBytes,
    required this.downloadBytes,
    required this.totalBytes,
    required this.expireDate,
  });

  int get usedBytes => uploadBytes + downloadBytes;

  double get usedPercentage =>
      totalBytes > 0 ? (usedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }
}