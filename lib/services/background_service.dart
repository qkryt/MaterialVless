import 'dart:io';
import 'package:flutter/painting.dart';
import 'log_service.dart';

class BackgroundService {
  static const List<String> supportedExtensions = [
    'png',
    'jpg',
    'jpeg',
    'webp',
    'bmp',
    'gif',
  ];

  /// Получение корневой директории клиента для хранения background.(формат)
  static Directory getRootDirectory() {
    try {
      final exeFile = File(Platform.resolvedExecutable);
      final exeDir = exeFile.parent;
      if (exeDir.existsSync()) {
        return exeDir;
      }
    } catch (_) {}

    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
      if (appData != null) {
        final fallbackDir = Directory('$appData${Platform.pathSeparator}MaterialVless');
        try {
          if (!fallbackDir.existsSync()) fallbackDir.createSync(recursive: true);
          return fallbackDir;
        } catch (_) {}
      }
    }

    return Directory.current;
  }

  /// Поиск существующего файла background.(формат) в корневой папке
  static String? findExistingBackgroundInRoot() {
    try {
      final rootDir = getRootDirectory();
      for (final ext in supportedExtensions) {
        final candidate = File('${rootDir.path}${Platform.pathSeparator}background.$ext');
        if (candidate.existsSync() && candidate.lengthSync() > 0) {
          return candidate.path;
        }
      }
    } catch (_) {}

    // Также проверяем AppData/MaterialVless на случай если корень защищен
    if (Platform.isWindows) {
      try {
        final appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
        if (appData != null) {
          final fallbackDir = Directory('$appData${Platform.pathSeparator}MaterialVless');
          if (fallbackDir.existsSync()) {
            for (final ext in supportedExtensions) {
              final candidate = File('${fallbackDir.path}${Platform.pathSeparator}background.$ext');
              if (candidate.existsSync() && candidate.lengthSync() > 0) {
                return candidate.path;
              }
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }

  /// Нативный диалог выбора файла изображения на Windows
  static Future<String?> pickImageFile() async {
    if (Platform.isWindows) {
      try {
        final result = await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          r'''Add-Type -AssemblyName System.Windows.Forms
$dlg = New-Object System.Windows.Forms.OpenFileDialog
$dlg.Filter = "Изображения и GIF (*.png;*.jpg;*.jpeg;*.webp;*.bmp;*.gif)|*.png;*.jpg;*.jpeg;*.webp;*.bmp;*.gif|Все файлы (*.*)|*.*"
$dlg.Title = "Выберите фоновое изображение или GIF (автоподстройка под разрешение)"
if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  [Console]::Out.Write($dlg.FileName)
}'''
        ]);
        final path = result.stdout.toString().trim();
        if (path.isNotEmpty && File(path).existsSync()) {
          return path;
        }
      } catch (e) {
        LogService.log('pickImageFile error: $e');
      }
    }
    return null;
  }

  /// Сохранение копии фонового изображения в корневую папку как background.(формат)
  /// чтобы при удалении исходного файла картинка продолжала гарантированно работать в реальном времени
  static Future<String?> saveBackgroundImage(File sourceFile) async {
    try {
      // 1. Очищаем кэш изображений Flutter, чтобы мгновенно освободить дескрипторы и память
      try {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      } catch (_) {}

      // 2. Читаем байты исходного файла (включая анимированные GIF)
      final bytes = await sourceFile.readAsBytes();
      if (bytes.isEmpty) return null;

      final rootDir = getRootDirectory();
      var ext = sourceFile.path.split('.').last.toLowerCase();
      if (!supportedExtensions.contains(ext)) {
        ext = 'jpg';
      }

      final destFile = File('${rootDir.path}${Platform.pathSeparator}background.$ext');

      // 3. Удаляем старые файлы background.* других расширений
      for (final oldExt in supportedExtensions) {
        final oldFile = File('${rootDir.path}${Platform.pathSeparator}background.$oldExt');
        if (oldFile.existsSync()) {
          try {
            oldFile.deleteSync();
          } catch (_) {}
        }
      }

      // 4. Записываем байты в корень программы
      await destFile.writeAsBytes(bytes, flush: true);
      LogService.log('Background image successfully saved to root: ${destFile.path} (${bytes.length} bytes)');

      // Дублируем в AppData для максимальной надежности
      if (Platform.isWindows) {
        try {
          final appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
          if (appData != null) {
            final fallbackDir = Directory('$appData${Platform.pathSeparator}MaterialVless');
            if (!fallbackDir.existsSync()) fallbackDir.createSync(recursive: true);
            final fallbackFile = File('${fallbackDir.path}${Platform.pathSeparator}background.$ext');
            await fallbackFile.writeAsBytes(bytes, flush: true);
          }
        } catch (_) {}
      }

      return destFile.path;
    } catch (e) {
      LogService.log('saveBackgroundImage error: $e');

      // Fallback на AppData если запись в корень заблокирована
      if (Platform.isWindows) {
        try {
          final appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
          if (appData != null) {
            final fallbackDir = Directory('$appData${Platform.pathSeparator}MaterialVless');
            if (!fallbackDir.existsSync()) fallbackDir.createSync(recursive: true);
            var ext = sourceFile.path.split('.').last.toLowerCase();
            if (!supportedExtensions.contains(ext)) ext = 'jpg';
            final destFile = File('${fallbackDir.path}${Platform.pathSeparator}background.$ext');
            final bytes = await sourceFile.readAsBytes();
            await destFile.writeAsBytes(bytes, flush: true);
            LogService.log('Background image saved to fallback directory: ${destFile.path}');
            return destFile.path;
          }
        } catch (_) {}
      }

      return sourceFile.path;
    }
  }

  /// Удаление сохраненного фонового изображения и сброс кэша
  static Future<void> deleteBackgroundImage(String path) async {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (_) {}

    try {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
        LogService.log('Deleted background image: $path');
      }
    } catch (e) {
      LogService.log('deleteBackgroundImage error: $e');
    }

    // Подчищаем любые background.* в корне
    try {
      final rootDir = getRootDirectory();
      for (final ext in supportedExtensions) {
        final f = File('${rootDir.path}${Platform.pathSeparator}background.$ext');
        if (f.existsSync()) {
          try {
            f.deleteSync();
          } catch (_) {}
        }
      }
    } catch (_) {}

    // И в AppData
    if (Platform.isWindows) {
      try {
        final appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
        if (appData != null) {
          final fallbackDir = Directory('$appData${Platform.pathSeparator}MaterialVless');
          if (fallbackDir.existsSync()) {
            for (final ext in supportedExtensions) {
              final f = File('${fallbackDir.path}${Platform.pathSeparator}background.$ext');
              if (f.existsSync()) {
                try {
                  f.deleteSync();
                } catch (_) {}
              }
            }
          }
        }
      } catch (_) {}
    }
  }
}
