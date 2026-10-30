import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/subscription_model.dart';
import '../models/vless_node.dart';
import '../models/app_settings.dart';
import 'log_service.dart';

class StorageService {
  static const String _fileName = 'material_vless_data.json';

  static Future<List<File>> _getFiles() async {
    final list = <File>[];

    // 1. Директория исполняемого файла программы (exe)
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      list.add(File('$exeDir${Platform.pathSeparator}$_fileName'));
    } catch (_) {}

    // 2. Системная директория данных приложения (ApplicationSupport)
    try {
      final appDir = await getApplicationSupportDirectory();
      if (!appDir.existsSync()) appDir.createSync(recursive: true);
      list.add(File('${appDir.path}${Platform.pathSeparator}$_fileName'));
    } catch (_) {}

    // 3. Папка AppData/MaterialVless на Windows
    if (Platform.isWindows) {
      try {
        final appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
        if (appData != null) {
          final dir = Directory('$appData${Platform.pathSeparator}MaterialVless');
          if (!dir.existsSync()) dir.createSync(recursive: true);
          list.add(File('${dir.path}${Platform.pathSeparator}$_fileName'));
        }
      } catch (_) {}
    }

    // 4. Текущая рабочая директория
    try {
      list.add(File(_fileName));
      list.add(File('${Directory.current.path}${Platform.pathSeparator}$_fileName'));
    } catch (_) {}

    return list;
  }

  /// Сохранение всех данных в файл проекта (запись во все доступные хранилища)
  static Future<void> saveData({
    required List<SubscriptionModel> subscriptions,
    required List<VlessNode> manualNodes,
    String? selectedNodeId,
    AppSettings? settings,
  }) async {
    try {
      final data = {
        'version': 2,
        'appName': 'MaterialVless',
        'updatedAt': DateTime.now().toIso8601String(),
        'selectedNodeId': selectedNodeId,
        'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
        'manualNodes': manualNodes.map((n) => n.toJson()).toList(),
        if (settings != null) 'settings': settings.toJson(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final files = await _getFiles();
      for (final file in files) {
        try {
          await file.writeAsString(jsonString, flush: true);
        } catch (_) {}
      }
    } catch (e) {
      LogService.log('StorageService.saveData error: $e');
    }
  }

  /// Загрузка сохраненных данных (выбирает самый свежий файл по дате изменения)
  static Future<(List<SubscriptionModel>, List<VlessNode>, String?, AppSettings?)> loadData() async {
    try {
      final files = await _getFiles();
      File? targetFile;
      DateTime? newestDate;

      for (final f in files) {
        try {
          if (f.existsSync() && f.lengthSync() > 10) {
            final mod = f.lastModifiedSync();
            if (newestDate == null || mod.isAfter(newestDate)) {
              newestDate = mod;
              targetFile = f;
            }
          }
        } catch (_) {}
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
        settings = AppSettings.fromJson(sJson);
      }

      return (subs, nodes, selectedNodeId, settings);
    } catch (e) {
      LogService.log('StorageService.loadData error: $e');
      return (const <SubscriptionModel>[], const <VlessNode>[], null, null);
    }
  }
}
