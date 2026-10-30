import 'dart:io';
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
$dlg.Filter = "Изображения (*.png;*.jpg;*.jpeg;*.webp;*.bmp;*.gif)|*.png;*.jpg;*.jpeg;*.webp;*.bmp;*.gif|Все файлы (*.*)|*.*"
$dlg.Title = "Выберите фоновое изображение (любой формат, автоподстройка под разрешение)"
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
  /// чтобы при удалении исходного файла картинка продолжала гарантированно работать
  static Future<String?> saveBackgroundImage(File sourceFile) async {
    try {
      final rootDir = getRootDirectory();
      var ext = sourceFile.path.split('.').last.toLowerCase();
      if (!supportedExtensions.contains(ext)) {
        ext = 'jpg';
      }

      final destFile = File('${rootDir.path}${Platform.pathSeparator}background.$ext');

      // Очистка старых background.* файлов других форматов
      for (final oldExt in supportedExtensions) {
        final oldFile = File('${rootDir.path}${Platform.pathSeparator}background.$oldExt');
        if (oldFile.existsSync()) {
          try {
            oldFile.deleteSync();
          } catch (_) {}
        }
      }

      // Копируем исходный файл в корень, если они не совпадают
      if (sourceFile.absolute.path != destFile.absolute.path) {
        await sourceFile.copy(destFile.path);
      }

      LogService.log('Background image saved to root directory: ${destFile.path}');
      return destFile.path;
    } catch (e) {
      LogService.log('saveBackgroundImage error: $e');

      // Fallback на AppData если корень защищен
      if (Platform.isWindows) {
        try {
          final appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
          if (appData != null) {
            final fallbackDir = Directory('$appData${Platform.pathSeparator}MaterialVless');
            if (!fallbackDir.existsSync()) fallbackDir.createSync(recursive: true);
            var ext = sourceFile.path.split('.').last.toLowerCase();
            if (!supportedExtensions.contains(ext)) ext = 'jpg';
            final destFile = File('${fallbackDir.path}${Platform.pathSeparator}background.$ext');
            await sourceFile.copy(destFile.path);
            LogService.log('Background image saved to fallback directory: ${destFile.path}');
            return destFile.path;
          }
        } catch (_) {}
      }

      return sourceFile.path;
    }
  }

  /// Удаление сохраненного фонового изображения
  static Future<void> deleteBackgroundImage(String path) async {
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
