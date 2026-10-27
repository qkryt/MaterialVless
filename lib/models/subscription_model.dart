import 'dart:convert';
import 'vless_node.dart';

class SubscriptionModel {
  final String id;
  final String name;
  final String url;
  final DateTime lastUpdated;
  final int uploadBytes;
  final int downloadBytes;
  final int totalBytes;
  final DateTime? expireDate;
  final List<VlessNode> nodes;
  final bool autoUpdate;

  SubscriptionModel({
    required this.id,
    required this.name,
    required this.url,
    required this.lastUpdated,
    this.uploadBytes = 0,
    this.downloadBytes = 0,
    this.totalBytes = 0,
    this.expireDate,
    this.nodes = const [],
    this.autoUpdate = true,
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

  SubscriptionModel copyWith({
    String? name,
    DateTime? lastUpdated,
    int? uploadBytes,
    int? downloadBytes,
    int? totalBytes,
    DateTime? expireDate,
    List<VlessNode>? nodes,
    bool? autoUpdate,
  }) {
    return SubscriptionModel(
      id: id,
      name: name ?? this.name,
      url: url,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      uploadBytes: uploadBytes ?? this.uploadBytes,
      downloadBytes: downloadBytes ?? this.downloadBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      expireDate: expireDate ?? this.expireDate,
      nodes: nodes ?? this.nodes,
      autoUpdate: autoUpdate ?? this.autoUpdate,
    );
  }
}
