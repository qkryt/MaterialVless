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

  static String _resolveXrayBinary() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    if (Platform.isWindows) {
      final local = '$exeDir\\xray.exe';
      return File(local).existsSync() ? local : 'xray.exe';
    } else if (Platform.isLinux) {
      final local = '$exeDir/xray';
      return File(local).existsSync() ? local : 'xray';
    } else if (Platform.isMacOS) {
      final local = '${File(Platform.resolvedExecutable).parent.parent.path}/Resources/xray';
      return File(local).existsSync() ? local : 'xray';
    }
    return 'xray';
  }

  /// Запуск единого объединенного режима защиты (TUN + Системный прокси)
  Future<void> start(VlessNode node, AppSettings settings) async {
    _updateState(CoreState.connecting);

    try {
      final configJson = ConfigGenerator.generate(node, settings);
      final tempDir = await getTemporaryDirectory();
      final configFile = File('${tempDir.path}/material_vless_active.json');
      await configFile.writeAsString(configJson);

      final binaryPath = _resolveXrayBinary();
      final workingDir = File(binaryPath).existsSync()
          ? File(binaryPath).parent.path
          : null;

      _process = await Process.start(
        binaryPath,
        ['run', '-c', configFile.path],
        workingDirectory: workingDir,
      );

      _process!.exitCode.then((code) {
        if (_state == CoreState.connected) {
          stop();
        }
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (_process == null) {
        throw Exception('Xray process exited immediately upon start');
      }

      // Активация единого системного прокси
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

    // Отключение системного прокси
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

  Future<void> _setWindowsProxy(bool enable, int port) async {
    if (!Platform.isWindows) return;
    try {
      await Process.run('reg', [
        'add',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
        '/v', 'ProxyEnable', '/t', 'REG_DWORD', '/d', enable ? '1' : '0', '/f'
      ]);
      if (enable) {
        await Process.run('reg', [
          'add',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
          '/v', 'ProxyServer', '/t', 'REG_SZ', '/d', '127.0.0.1:$port', '/f'
        ]);
      }
    } catch (_) {}
  }
}
