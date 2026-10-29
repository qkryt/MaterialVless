import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

class SingleInstanceService {
  static const int _ipcPort = 49281;
  static ServerSocket? _serverSocket;
  static void Function(String message)? _onMessage;

  /// Проверяет, запущен ли уже инстанс программы.
  /// Возвращает `true`, если этот процесс является главным (первым).
  /// Возвращает `false`, если рабочий инстанс уже существует и ему отправлен сигнал.
  static Future<bool> ensureSingleInstance(List<String> args) async {
    final payload = args.isNotEmpty ? args.first : 'SHOW';

    try {
      // Пытаемся подключиться к возможно работающему экземпляру
      final socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        _ipcPort,
        timeout: const Duration(milliseconds: 600),
      );

      // Экземпляр ответил — передаём аргументы и активируем его окно
      socket.write('$payload\n');
      await socket.flush();

      // Ожидаем подтверждения
      final completer = Completer<bool>();
      socket.listen(
        (data) {
          final resp = utf8.decode(data).trim();
          if (resp == 'OK') {
            completer.complete(true);
          }
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(false);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(false);
        },
      );

      final acknowledged = await completer.future.timeout(
        const Duration(milliseconds: 800),
        onTimeout: () => false,
      );

      await socket.close();

      if (acknowledged) {
        // Рабочий инстанс жив и принял команду — второй инстанс не открываем!
        return false;
      }
    } catch (_) {
      // Подключение не удалось — активного рабочего инстанса нет
    }

    // Если порт занят зависшим "нерабочим" процессом, либо свободен:
    try {
      _serverSocket = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        _ipcPort,
        shared: false,
      );

      _serverSocket!.listen((client) {
        client.listen((data) async {
          final message = utf8.decode(data).trim();
          client.write('OK\n');
          await client.flush();
          client.close();

          // Активируем окно на передний план
          try {
            await windowManager.show();
            await windowManager.focus();
          } catch (_) {}

          if (_onMessage != null && message.isNotEmpty) {
            _onMessage!(message);
          }
        });
      });

      return true;
    } catch (e) {
      debugPrint('SingleInstance bind warning: $e');
      return true;
    }
  }

  static void setMessageHandler(void Function(String message) handler) {
    _onMessage = handler;
  }

  static Future<void> close() async {
    await _serverSocket?.close();
  }
}
