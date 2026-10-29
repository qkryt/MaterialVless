import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../providers/vpn_provider.dart';

class UrlSchemeService {
  /// Регистрация протоколов material:// и happ:// в реестре Windows (HKCU)
  static Future<void> registerWindowsProtocolHandlers() async {
    if (!Platform.isWindows) return;

    try {
      final exePath = Platform.resolvedExecutable;
      for (final scheme in ['material', 'happ']) {
        final regScript = '''
\$scheme = "$scheme"
\$exe = "$exePath"
\$regPath = "HKCU:\\Software\\Classes\\\$scheme"
New-Item -Path \$regPath -Force | Out-Null
Set-ItemProperty -Path \$regPath -Name "(Default)" -Value "URL:\$scheme Protocol" -Force
Set-ItemProperty -Path \$regPath -Name "URL Protocol" -Value "" -Force
\$cmdPath = "\$regPath\\shell\\open\\command"
New-Item -Path \$cmdPath -Force | Out-Null
Set-ItemProperty -Path \$cmdPath -Name "(Default)" -Value "`"\$exe`" `"%1`"" -Force
''';
        await Process.run('powershell', ['-NoProfile', '-Command', regScript]);
      }
    } catch (e) {
      debugPrint('UrlSchemeService register error: $e');
    }
  }

  /// Парсинг и обработка URL команд
  static Future<void> handleUrl(String rawUrl, VpnNotifier vpnNotifier) async {
    try {
      final clean = rawUrl.trim().replaceAll('"', '');
      if (clean.isEmpty) return;

      // Нормализуем протокол
      String path = clean;
      if (clean.startsWith('material://')) {
        path = clean.substring('material://'.length);
      } else if (clean.startsWith('happ://')) {
        path = clean.substring('happ://'.length);
      } else {
        return;
      }

      // 1. Команды подключения
      if (path == 'connect' || path == 'open' || path == '/connect' || path == '/open') {
        await vpnNotifier.connect();
        return;
      }

      // 2. Команды отключения
      if (path == 'disconnect' || path == 'close' || path == '/disconnect' || path == '/close') {
        await vpnNotifier.disconnect();
        return;
      }

      // 3. Переключение VPN
      if (path == 'toggle' || path == '/toggle') {
        await vpnNotifier.toggleConnection();
        return;
      }

      // 4. Добавление сервера / подписки
      // material://add{URL}, happ://add{URL}, material://crypt{URL}, material://crypt2{URL}
      final addPrefixes = [
        'add/', 'add',
        'crypt/', 'crypt',
        'crypt2/', 'crypt2',
      ];

      for (final p in addPrefixes) {
        if (path.startsWith(p)) {
          final target = path.substring(p.length).trim();
          String finalUrl = target;

          // Проверяем, закодирован ли URL в base64
          if (!target.startsWith('http://') && !target.startsWith('https://') && !target.contains('://')) {
            try {
              final decoded = utf8.decode(base64.decode(base64.normalize(target)));
              if (decoded.contains('://')) finalUrl = decoded.trim();
            } catch (_) {}
          }

          if (finalUrl.isNotEmpty) {
            await vpnNotifier.addSubscription(finalUrl);
          }
          return;
        }
      }

      // 5. Маршрутизация
      // material://routing/add/{base64}
      // material://routing/onadd/{base64}
      // material://routing/off
      if (path.startsWith('routing/add/') || path.startsWith('routing/onadd/')) {
        final isAdd = path.startsWith('routing/add/');
        final b64 = path.substring(isAdd ? 'routing/add/'.length : 'routing/onadd/'.length).trim();
        try {
          final decoded = utf8.decode(base64.decode(base64.normalize(b64))).trim();
          final rules = decoded.split(RegExp(r'[\r\n,;]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          for (final r in rules) {
            vpnNotifier.addCustomRoutingRule(r);
          }
        } catch (_) {}
        return;
      }

      if (path == 'routing/off' || path == '/routing/off') {
        vpnNotifier.clearCustomRoutingRules();
        vpnNotifier.updateSettings(
          vpnNotifier.state.settings.copyWith(routingPreset: 'none'),
        );
        return;
      }
    } catch (e) {
      debugPrint('Error handling URL scheme: $e');
    }
  }
}
