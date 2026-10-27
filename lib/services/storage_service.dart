import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/subscription_model.dart';
import '../models/vless_node.dart';
import '../models/app_settings.dart';

class StorageService {
  static const String _fileName = 'material_vless_data.json';

  static Future<List<File>> _getFiles() async {
    final list = <File>[];
    // 1. Файл в корне проекта / рабочей директории
    try {
      list.add(File(_fileName));
      list.add(File('${Directory.current.path}/$_fileName'));
    } catch (_) {}

    // 2. Файл в системной директории данных приложения
    try {
      final appDir = await getApplicationSupportDirectory();
      list.add(File('${appDir.path}/$_fileName'));
    } catch (_) {}

    return list;
  }

  /// Сохранение всех данных в файл проекта
  static Future<void> saveData({
    required List<SubscriptionModel> subscriptions,
    required List<VlessNode> manualNodes,
    String? selectedNodeId,
    AppSettings? settings,
  }) async {
    try {
      final data = {
        'version': 1,
        'appName': 'MaterialVless',
        'updatedAt': DateTime.now().toIso8601String(),
        'selectedNodeId': selectedNodeId,
        'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
        'manualNodes': manualNodes.map((n) => n.toJson()).toList(),
        if (settings != null)
          'settings': {
            'routingPreset': settings.routingPreset,
            'pingUrl': settings.pingUrl,
            'pingTimeoutMs': settings.pingTimeoutMs,
            'speedtestUrl': settings.speedtestUrl,
            'autoUpdateRulesOnStart': settings.autoUpdateRulesOnStart,
            'userAgent': settings.userAgent,
            'sendHwid': settings.sendHwid,
            'themeMode': settings.themeMode,
            'fontFamily': settings.fontFamily,
            'useDynamicColor': settings.useDynamicColor,
          },
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final files = await _getFiles();
      for (final file in files) {
        try {
          await file.writeAsString(jsonString);
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Загрузка сохраненных данных
  static Future<(List<SubscriptionModel>, List<VlessNode>, String?, AppSettings?)> loadData() async {
    try {
      final files = await _getFiles();
      File? targetFile;
      for (final f in files) {
        if (await f.exists()) {
          targetFile = f;
          break;
        }
      }

      if (targetFile == null) {
        return (const <SubscriptionModel>[], const <VlessNode>[], null, null);
      }

      final content = await targetFile.readAsString();
      if (content.trim().isEmpty) {
        return (const <SubscriptionModel>[], const <VlessNode>[], null, null);
      }

      final json = jsonDecode(content) as Map<String, dynamic>;

      final subs = (json['subscriptions'] as List<dynamic>?)
              ?.map((s) => SubscriptionModel.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [];

      final nodes = (json['manualNodes'] as List<dynamic>?)
              ?.map((n) => VlessNode.fromJson(n as Map<String, dynamic>))
              .toList() ??
          [];

      final selectedNodeId = json['selectedNodeId'] as String?;

      AppSettings? settings;
      if (json['settings'] != null) {
        final sJson = json['settings'] as Map<String, dynamic>;
        settings = AppSettings(
          routingPreset: sJson['routingPreset']?.toString() ?? 'none',
          pingUrl: sJson['pingUrl']?.toString() ?? 'http://cp.cloudflare.com/',
          pingTimeoutMs: int.tryParse(sJson['pingTimeoutMs']?.toString() ?? '1000') ?? 1000,
          speedtestUrl: sJson['speedtestUrl']?.toString() ?? 'http://cachefly.cachefly.net/1mb.test',
          autoUpdateRulesOnStart: sJson['autoUpdateRulesOnStart'] == true,
          userAgent: sJson['userAgent']?.toString() ?? 'MaterialVless',
          sendHwid: sJson['sendHwid'] != false,
          themeMode: sJson['themeMode']?.toString() ?? 'system',
          fontFamily: sJson['fontFamily']?.toString() ?? 'Google Sans',
          useDynamicColor: sJson['useDynamicColor'] != false,
        );
      }

      return (subs, nodes, selectedNodeId, settings);
    } catch (_) {
      return (const <SubscriptionModel>[], const <VlessNode>[], null, null);
    }
  }
}
