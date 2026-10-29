import 'dart:io';
import 'package:flutter/services.dart';

class CustomFontService {
  static final Set<String> _loadedFontFamilies = {};

  /// Возвращает директорию для сохранения кастомных шрифтов
  static Directory getFontsDirectory() {
    final exeDir = File(Platform.resolvedExecutable).parent;
    final localDir = Directory('${exeDir.path}${Platform.pathSeparator}customfonts');
    try {
      if (!localDir.existsSync()) {
        localDir.createSync(recursive: true);
      }
      // Проверка прав на запись
      final testFile = File('${localDir.path}${Platform.pathSeparator}.write_test');
      testFile.writeAsStringSync('ok');
      testFile.deleteSync();
      return localDir;
    } catch (_) {
      // Если прав на запись в Program Files нет, сохраняем в AppData
      if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
        if (appData != null) {
          final fallbackDir = Directory('$appData${Platform.pathSeparator}MaterialVless${Platform.pathSeparator}customfonts');
          try {
            if (!fallbackDir.existsSync()) fallbackDir.createSync(recursive: true);
            return fallbackDir;
          } catch (_) {}
        }
      }
      return localDir;
    }
  }

  /// Список установленных файлов шрифтов (.ttf и .otf) из всех доступных локаций
  static List<File> getInstalledFontFiles() {
    final dirs = <Directory>[];
    final exeDir = File(Platform.resolvedExecutable).parent;
    dirs.add(Directory('${exeDir.path}${Platform.pathSeparator}customfonts'));

    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
      if (appData != null) {
        dirs.add(Directory('$appData${Platform.pathSeparator}MaterialVless${Platform.pathSeparator}customfonts'));
      }
    }

    final result = <File>[];
    final seenNames = <String>{};
    for (final dir in dirs) {
      if (!dir.existsSync()) continue;
      try {
        final files = dir.listSync().whereType<File>().where((f) {
          final ext = f.path.split('.').last.toLowerCase();
          return ext == 'ttf' || ext == 'otf';
        });
        for (final f in files) {
          final name = f.uri.pathSegments.last.toLowerCase();
          if (!seenNames.contains(name)) {
            seenNames.add(name);
            result.add(f);
          }
        }
      } catch (_) {}
    }
    return result;
  }

  /// Поиск пути к файлу шрифта по названию семейства
  static String? findFontPathForFamily(String familyName) {
    final files = getInstalledFontFiles();
    for (final f in files) {
      final filename = f.uri.pathSegments.last;
      final name = filename.replaceAll(RegExp(r'\.(ttf|otf)$', caseSensitive: false), '');
      if (name.toLowerCase() == familyName.toLowerCase()) {
        return f.path;
      }
    }
    return null;
  }

  /// Список названий загруженных кастомных шрифтов
  static List<String> getAvailableCustomFontFamilies() {
    final files = getInstalledFontFiles();
    return files.map((f) {
      final filename = f.uri.pathSegments.last;
      return filename.replaceAll(RegExp(r'\.(ttf|otf)$', caseSensitive: false), '');
    }).toList();
  }

  /// Загрузка одного файла шрифта в движок Flutter
  static Future<bool> loadFont(File file) async {
    final filename = file.uri.pathSegments.last;
    final fontName = filename.replaceAll(RegExp(r'\.(ttf|otf)$', caseSensitive: false), '');

    if (_loadedFontFamilies.contains(fontName)) {
      return true;
    }

    try {
      final fontLoader = FontLoader(fontName);
      final bytes = await file.readAsBytes();
      fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
      await fontLoader.load();
      _loadedFontFamilies.add(fontName);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Загрузка всех шрифтов из папки /customfonts при старте приложения
  static Future<void> loadAllCustomFonts() async {
    final files = getInstalledFontFiles();
    for (final file in files) {
      await loadFont(file);
    }
  }

  /// Копирование файла шрифта в папку /customfonts и мгновенная регистрация
  static Future<String?> addCustomFontFromFile(File sourceFile) async {
    if (!sourceFile.existsSync()) return null;

    final filename = sourceFile.uri.pathSegments.last;
    final targetDir = getFontsDirectory();
    final targetFile = File('${targetDir.path}${Platform.pathSeparator}$filename');

    try {
      await sourceFile.copy(targetFile.path);
      await loadFont(targetFile);
      final fontName = filename.replaceAll(RegExp(r'\.(ttf|otf)$', caseSensitive: false), '');
      return fontName;
    } catch (e) {
      return null;
    }
  }

  /// Удаление шрифта из папки
  static Future<bool> deleteFont(File file) async {
    try {
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Нативный диалог выбора файла шрифта на Windows
  static Future<String?> pickFontFile() async {
    if (Platform.isWindows) {
      try {
        final result = await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          r'''Add-Type -AssemblyName System.Windows.Forms
$dlg = New-Object System.Windows.Forms.OpenFileDialog
$dlg.Filter = "Файлы шрифтов (*.ttf;*.otf)|*.ttf;*.otf|Все файлы (*.*)|*.*"
$dlg.Title = "Выберите файл шрифта"
if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  [Console]::Out.Write($dlg.FileName)
}'''
        ]);
        final path = result.stdout.toString().trim();
        if (path.isNotEmpty && File(path).existsSync()) {
          return path;
        }
      } catch (_) {}
    }
    return null;
  }
}
