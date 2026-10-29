import 'dart:convert';
import 'dart:io';

class LogService {
  static File? _logFile;
  static IOSink? _sink;
  static bool _initialized = false;

  /// Получение файла log.txt в корневой папке программы (где лежит exe)
  static File getLogFile() {
    if (_logFile != null) return _logFile!;

    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final primaryFile = File('$exeDir${Platform.pathSeparator}log.txt');

    try {
      primaryFile.writeAsStringSync('', mode: FileMode.append);
      _logFile = primaryFile;
      return primaryFile;
    } catch (_) {
      // Если по какой-то причине корень защищен от записи, используем AppData
      if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
        if (appData != null) {
          final fallbackDir = Directory('$appData${Platform.pathSeparator}MaterialVless');
          try {
            fallbackDir.createSync(recursive: true);
            final fallbackFile = File('${fallbackDir.path}${Platform.pathSeparator}log.txt');
            _logFile = fallbackFile;
            return fallbackFile;
          } catch (_) {}
        }
      }
      _logFile = primaryFile;
      return primaryFile;
    }
  }

  /// Инициализация сервиса логирования
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final file = getLogFile();
      _sink = file.openWrite(mode: FileMode.append);

      final now = DateTime.now().toIso8601String().replaceFirst('T', ' ');
      final header = '''

================================================================================
MaterialVless 2.15 Log Session Started: $now
Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}
Executable: ${Platform.resolvedExecutable}
Root Directory: ${File(Platform.resolvedExecutable).parent.path}
Log File: ${file.path}
================================================================================
''';
      _sink?.writeln(header);
      await _sink?.flush();
    } catch (e) {
      print('LogService.init error: $e');
    }
  }

  /// Запись строки в лог с временной меткой
  static void log(String message) {
    final timestamp = DateTime.now().toIso8601String().replaceFirst('T', ' ');
    final line = '[$timestamp] $message';
    print(line);

    try {
      if (_sink != null) {
        _sink!.writeln(line);
        _sink!.flush();
      } else {
        final file = getLogFile();
        file.writeAsStringSync('$line\n', mode: FileMode.append);
      }
    } catch (_) {}
  }

  /// Запись ошибки в лог
  static void logError(String message, [dynamic error, StackTrace? stack]) {
    final errStr = error != null ? ' | Error: $error' : '';
    final stackStr = stack != null ? '\nStack trace:\n$stack' : '';
    log('ERROR: $message$errStr$stackStr');
  }

  /// Логирование вывода процесса
  static void logProcessOutput(String source, String text) {
    for (final line in text.split(RegExp(r'\r?\n'))) {
      if (line.trim().isNotEmpty) {
        log('[$source] ${line.trim()}');
      }
    }
  }

  /// Открытие файла логов в блокноте (Notepad на Windows) или текстовом редакторе
  static Future<void> openLogFile() async {
    final file = getLogFile();
    if (!file.existsSync()) {
      file.writeAsStringSync('MaterialVless Log File\n');
    }

    if (Platform.isWindows) {
      try {
        await Process.run('notepad.exe', [file.path]);
        return;
      } catch (_) {}
    } else if (Platform.isMacOS) {
      try {
        await Process.run('open', [file.path]);
        return;
      } catch (_) {}
    } else if (Platform.isLinux) {
      try {
        await Process.run('xdg-open', [file.path]);
        return;
      } catch (_) {}
    }
  }
}
