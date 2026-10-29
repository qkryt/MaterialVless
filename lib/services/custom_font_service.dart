import 'dart:io';
import 'package:flutter/services.dart';

class CustomFontService {
  static final Set<String> _loadedFontFamilies = {};

  /// Возвращает путь к папке /MaterialVless/customfonts
  static Directory getFontsDirectory() {
    final exeDir = File(Platform.resolvedExecutable).parent;
    final customDir = Directory('${exeDir.path}${Platform.pathSeparator}customfonts');
    if (!customDir.existsSync()) {
      try {
        customDir.createSync(recursive: true);
      } catch (_) {}
    }
    return customDir;
  }

  /// Список установленных файлов шрифтов (.ttf и .otf)
  static List<File> getInstalledFontFiles() {
    final dir = getFontsDirectory();
    if (!dir.existsSync()) return [];

    try {
      return dir
          .listSync()
          .whereType<File>()
          .where((f) {
            final ext = f.path.split('.').last.toLowerCase();
            return ext == 'ttf' || ext == 'otf';
          })
          .toList();
    } catch (_) {
      return [];
    }
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
      // Игнорируем ошибки повреждённых шрифтов
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
