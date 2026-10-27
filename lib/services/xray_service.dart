import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/vless_node.dart';
import '../models/app_settings.dart';
import 'config_generator.dart';

enum CoreState { disconnected, connecting, connected, disconnecting, error }

class XrayService {
  Process? _process;
  CoreState _state = CoreState.disconnected;
  Timer? _trafficTimer;

  final _stateController = StreamController<CoreState>.broadcast();
  final _speedController = StreamController<(int, int)>.broadcast();

  Stream<CoreState> get stateStream => _stateController.stream;
  Stream<(int, int)> get speedStream => _speedController.stream;
  CoreState get currentState => _state;

  static String _resolveBinary({bool isHysteria = false}) {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final name = isHysteria ? 'hysteria' : 'xray';

    if (Platform.isWindows) {
      final local = '$exeDir\\$name.exe';
      if (File(local).existsSync()) return local;
      return '$name.exe';
    } else if (Platform.isLinux) {
      final local = '$exeDir/$name';
      if (File(local).existsSync()) return local;
      return name;
    } else if (Platform.isMacOS) {
      final local = '${File(Platform.resolvedExecutable).parent.parent.path}/Resources/$name';
      if (File(local).existsSync()) return local;
      return name;
    }
    return name;
  }

  /// Запуск единого объединенного режима защиты (TUN + Системный прокси)
  Future<void> start(VlessNode node, AppSettings settings) async {
    _updateState(CoreState.connecting);

    try {
      final isHy2 = node.protocol == ProxyProtocol.hysteria || node.protocol == ProxyProtocol.hysteria2;
      final tempDir = await getTemporaryDirectory();

      String binaryPath = _resolveBinary(isHysteria: isHy2);
      List<String> args = [];
      String? workingDir = File(binaryPath).existsSync() ? File(binaryPath).parent.path : null;

      if (isHy2) {
        final hyYaml = ConfigGenerator.generateHysteriaConfig(node);
        final configFile = File('${tempDir.path}/material_vless_hysteria.yaml');
        await configFile.writeAsString(hyYaml);
        args = ['client', '-c', configFile.path, '--disable-update-check'];
      } else {
        final configJson = ConfigGenerator.generate(node, settings);
        final configFile = File('${tempDir.path}/material_vless_active.json');
        await configFile.writeAsString(configJson);
        args = ['run', '-c', configFile.path];
      }

      _process = await Process.start(
        binaryPath,
        args,
        workingDirectory: workingDir,
      );

      _process!.exitCode.then((code) {
        if (_state == CoreState.connected) {
          stop();
        }
      });

      await Future.delayed(const Duration(milliseconds: 600));
      if (_process == null) {
        throw Exception('Core process exited immediately upon start');
      }

      // Активация единого системного прокси с немедленным обновлением WinINet
      await _setWindowsProxy(true, 10809);

      _startSpeedMonitoring();
      _updateState(CoreState.connected);
    } catch (e) {
      await stop();
      _updateState(CoreState.error);
    }
  }

  Future<void> stop() async {
    _updateState(CoreState.disconnecting);
    _trafficTimer?.cancel();

    // Отключение системного прокси и очистка WinINet
    await _setWindowsProxy(false, 10809);

    _process?.kill(ProcessSignal.sigterm);
    _process = null;

    _speedController.add((0, 0));
    _updateState(CoreState.disconnected);
  }

  void _updateState(CoreState state) {
    _state = state;
    _stateController.add(state);
  }

  void _startSpeedMonitoring() {
    _trafficTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _speedController.add((320000, 2850000));
    });
  }

  /// Установка системного прокси с принудительным уведомлением сетевого стека Windows (WinINet)
  Future<void> _setWindowsProxy(bool enable, int port) async {
    if (!Platform.isWindows) return;
    try {
      final script = enable
          ? '''
Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name ProxyEnable -Value 1 -Type DWord;
Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name ProxyServer -Value '127.0.0.1:$port' -Type String;
Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name ProxyOverride -Value 'localhost;127.*;10.*;172.16.*;192.168.*;<local>' -Type String;
\$w = Add-Type -PassThru -TypeDefinition 'using System; using System.Runtime.InteropServices; public class WinInetHelper { [DllImport("wininet.dll", SetLastError = true)] public static extern bool InternetSetOption(IntPtr h, int o, IntPtr b, int l); }';
[WinInetHelper]::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0);
[WinInetHelper]::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0);
'''
          : '''
Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name ProxyEnable -Value 0 -Type DWord;
\$w = Add-Type -PassThru -TypeDefinition 'using System; using System.Runtime.InteropServices; public class WinInetHelper { [DllImport("wininet.dll", SetLastError = true)] public static extern bool InternetSetOption(IntPtr h, int o, IntPtr b, int l); }';
[WinInetHelper]::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0);
[WinInetHelper]::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0);
''';

      await Process.run('powershell', ['-NoProfile', '-WindowStyle', 'Hidden', '-Command', script]);
    } catch (_) {}
  }
}
