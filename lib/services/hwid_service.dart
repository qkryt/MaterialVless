import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

class HwidService {
  static String? _cachedHwid;

  static Future<String> getHWID() async {
    if (_cachedHwid != null) return _cachedHwid!;

    String rawHardwareIdentifier = '';
    try {
      if (Platform.isWindows) {
        final result = await Process.run('reg', [
          'query',
          r'HKLM\SOFTWARE\Microsoft\Cryptography',
          '/v',
          'MachineGuid',
        ]);
        rawHardwareIdentifier = result.stdout.toString();
      } else if (Platform.isLinux) {
        final machineId = File('/etc/machine-id');
        if (await machineId.exists()) {
          rawHardwareIdentifier = await machineId.readAsString();
        } else {
          final dbusId = File('/var/lib/dbus/machine-id');
          if (await dbusId.exists()) {
            rawHardwareIdentifier = await dbusId.readAsString();
          }
        }
      } else if (Platform.isMacOS) {
        final result = await Process.run('ioreg', ['-rd1', '-c', 'IOPlatformExpertDevice']);
        final lines = result.stdout.toString().split('\n');
        for (var line in lines) {
          if (line.contains('IOPlatformUUID')) {
            rawHardwareIdentifier = line;
            break;
          }
        }
      } else if (Platform.isAndroid) {
        rawHardwareIdentifier = Platform.localHostname;
      }
    } catch (_) {
      rawHardwareIdentifier = '';
    }

    if (rawHardwareIdentifier.trim().isEmpty) {
      rawHardwareIdentifier =
          '${Platform.operatingSystem}-${Platform.numberOfProcessors}-${Platform.localHostname}';
    }

    final hash = sha256.convert(utf8.encode(rawHardwareIdentifier)).toString();
    _cachedHwid =
        '${hash.substring(0, 8)}-${hash.substring(8, 12)}-${hash.substring(12, 16)}-${hash.substring(16, 20)}-${hash.substring(20, 32)}';
    return _cachedHwid!;
  }
}
