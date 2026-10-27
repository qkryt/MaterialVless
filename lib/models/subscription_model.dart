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
  final int autoUpdateIntervalHours; // 1, 2, 6, 12, 24
  final bool isExpanded;

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
    this.autoUpdateIntervalHours = 2,
    this.isExpanded = true,
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'lastUpdated': lastUpdated.toIso8601String(),
        'uploadBytes': uploadBytes,
        'downloadBytes': downloadBytes,
        'totalBytes': totalBytes,
        'expireDate': expireDate?.toIso8601String(),
        'autoUpdate': autoUpdate,
        'autoUpdateIntervalHours': autoUpdateIntervalHours,
        'isExpanded': isExpanded,
        'nodes': nodes.map((n) => n.toJson()).toList(),
      };

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) => SubscriptionModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        url: json['url'] ?? '',
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'])
            : DateTime.now(),
        uploadBytes: json['uploadBytes'] ?? 0,
        downloadBytes: json['downloadBytes'] ?? 0,
        totalBytes: json['totalBytes'] ?? 0,
        expireDate: json['expireDate'] != null ? DateTime.parse(json['expireDate']) : null,
        autoUpdate: json['autoUpdate'] ?? true,
        autoUpdateIntervalHours: json['autoUpdateIntervalHours'] ?? 2,
        isExpanded: json['isExpanded'] ?? true,
        nodes: (json['nodes'] as List<dynamic>?)
                ?.map((n) => VlessNode.fromJson(n as Map<String, dynamic>))
                .toList() ??
            [],
      );

  SubscriptionModel copyWith({
    String? name,
    String? url,
    DateTime? lastUpdated,
    int? uploadBytes,
    int? downloadBytes,
    int? totalBytes,
    DateTime? expireDate,
    List<VlessNode>? nodes,
    bool? autoUpdate,
    int? autoUpdateIntervalHours,
    bool? isExpanded,
  }) {
    return SubscriptionModel(
      id: id,
      name: name ?? this.name,
      url: url ?? this.url,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      uploadBytes: uploadBytes ?? this.uploadBytes,
      downloadBytes: downloadBytes ?? this.downloadBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      expireDate: expireDate ?? this.expireDate,
      nodes: nodes ?? this.nodes,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      autoUpdateIntervalHours: autoUpdateIntervalHours ?? this.autoUpdateIntervalHours,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}
