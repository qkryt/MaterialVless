import 'dart:ffi';
import 'dart:io';

typedef IsUserAnAdminC = Int32 Function();
typedef IsUserAnAdminDart = int Function();

class AdminHelper {
  /// Проверяет, запущен ли текущий процесс с правами Администратора на Windows
  static bool isRunningAsAdmin() {
    if (!Platform.isWindows) return true;
    try {
      final shell32 = DynamicLibrary.open('shell32.dll');
      final isUserAnAdmin = shell32
          .lookupFunction<IsUserAnAdminC, IsUserAnAdminDart>('IsUserAnAdmin');
      return isUserAnAdmin() != 0;
    } catch (_) {
      try {
        final result = Process.runSync('net', ['session'], runInShell: true);
        return result.exitCode == 0;
      } catch (_) {
        return false;
      }
    }
  }

  /// Проверяет права Администратора при запуске приложения.
  /// Если прав нет — вызывает системный запрос UAC (runas).
  /// Если пользователь нажал "Да" — запускается экземпляр с правами админа, а текущий возвращает false (завершается).
  /// Если пользователь нажал "Нет" (отклонил) — возвращает false (приложение немедленно вылетает/закрывается).
  static Future<bool> ensureAdminPrivileges() async {
    if (!Platform.isWindows) return true;

    if (isRunningAsAdmin()) {
      return true;
    }

    final exePath = Platform.resolvedExecutable;

    try {
      // Запуск этого же exe через powershell Start-Process с глаголом RunAs (вызывает диалог UAC)
      final process = await Process.start(
        'powershell',
        [
          '-NoProfile',
          '-WindowStyle',
          'Hidden',
          '-Command',
          'Start-Process',
          '-FilePath',
          '"$exePath"',
          '-Verb',
          'RunAs',
        ],
      );

      await process.exitCode;
    } catch (_) {}

    // Текущий непривилегированный процесс завершается в любом случае
    return false;
  }
}
