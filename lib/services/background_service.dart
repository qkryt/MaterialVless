import 'dart:io';
import 'log_service.dart';

class BackgroundService {
  /// Получение директории для хранения фоновых изображений (/MaterialVless/backgrounds)
  static Directory getBackgroundsDirectory() {
    final exeDir = File(Platform.resolvedExecutable).parent;
    final localDir = Directory('${exeDir.path}${Platform.pathSeparator}backgrounds');
    try {
      if (!localDir.existsSync()) {
        localDir.createSync(recursive: true);
      }
      return localDir;
    } catch (_) {
      if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
        if (appData != null) {
          final fallbackDir = Directory('$appData${Platform.pathSeparator}MaterialVless${Platform.pathSeparator}backgrounds');
          try {
            if (!fallbackDir.existsSync()) fallbackDir.createSync(recursive: true);
            return fallbackDir;
          } catch (_) {}
        }
      }
      return localDir;
    }
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
$dlg.Title = "Выберите фоновое изображение (любой формат, 800x600)"
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

  /// Сохранение копии фонового изображения в постоянное хранилище
  static Future<String?> saveBackgroundImage(File sourceFile) async {
    try {
      final bgDir = getBackgroundsDirectory();
      final ext = sourceFile.path.split('.').last.toLowerCase();
      final fileName = 'wallpaper_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final destFile = File('${bgDir.path}${Platform.pathSeparator}$fileName');

      // Очистка старых обоев если есть
      try {
        if (bgDir.existsSync()) {
          for (final f in bgDir.listSync().whereType<File>()) {
            try { f.deleteSync(); } catch (_) {}
          }
        }
      } catch (_) {}

      await sourceFile.copy(destFile.path);
      LogService.log('Background image saved to: ${destFile.path}');
      return destFile.path;
    } catch (e) {
      LogService.log('saveBackgroundImage error: $e');
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
  }
}
