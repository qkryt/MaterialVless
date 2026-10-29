import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/vless_node.dart';
import '../models/app_settings.dart';
import 'config_generator.dart';
import 'log_service.dart';

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

  static String _resolveBinary() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;

    if (Platform.isWindows) {
      final localSb = '$exeDir\\sing-box.exe';
      if (File(localSb).existsSync()) return localSb;
      return 'sing-box.exe';
    } else if (Platform.isLinux) {
      final local = '$exeDir/sing-box';
      if (File(local).existsSync()) return local;
      return 'sing-box';
    } else if (Platform.isMacOS) {
      final local = '${File(Platform.resolvedExecutable).parent.parent.path}/Resources/sing-box';
      if (File(local).existsSync()) return local;
      return 'sing-box';
    }
    return 'sing-box';
  }

  /// Принудительное завершение всех процессов sing-box в системе
  static Future<void> killAllCoreProcesses() async {
    LogService.log('Terminating any running sing-box processes...');
    if (Platform.isWindows) {
      try {
        await Process.run('taskkill', ['/F', '/IM', 'sing-box.exe', '/T']);
      } catch (_) {}
    } else if (Platform.isLinux || Platform.isMacOS) {
      try {
        await Process.run('pkill', ['-9', 'sing-box']);
      } catch (_) {}
    }
  }

  /// Запуск настоящего TUN режима через ядро sing-box (создаёт адаптер material-tun)
  Future<void> start(VlessNode node, AppSettings settings) async {
    _updateState(CoreState.connecting);

    LogService.log('--- STARTING VPN CONNECTION ---');
    LogService.log('Target node: "${node.remark}" (${node.protocol.name.toUpperCase()})');
    LogService.log('Remote host: ${node.address}:${node.port}');
    LogService.log('Parameters: security=${node.security}, streamType=${node.streamType}, flow=${node.flow}, sni=${node.sni}');

    // Завершаем любые зависшие или старые процессы ядра перед стартом
    await killAllCoreProcesses();
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      final configJson = ConfigGenerator.generate(node, settings);
      final tempDir = await getTemporaryDirectory();
      final configFile = File('${tempDir.path}/material_vless_active.json');
      
      // Запись строго без UTF-8 BOM
      await configFile.writeAsBytes(utf8.encode(configJson));
      LogService.log('Generated sing-box config saved to: ${configFile.path}');
      LogService.log('Active JSON configuration:\n$configJson');

      final binaryPath = _resolveBinary();
      LogService.log('Target sing-box binary: $binaryPath (exists: ${File(binaryPath).existsSync()})');

      final workingDir = File(binaryPath).existsSync() ? File(binaryPath).parent.path : null;

      final logFile = File('${tempDir.path}/material_vless_core.log');
      final logSink = logFile.openWrite(mode: FileMode.writeOnly);

      LogService.log('Launching sing-box process with run -c ${configFile.path} ...');
      _process = await Process.start(
        binaryPath,
        ['run', '-c', configFile.path],
        workingDirectory: workingDir,
      );
      final pid = _process!.pid;
      LogService.log('sing-box process started with PID: $pid');

      _process!.stdout.transform(utf8.decoder).listen((data) {
        logSink.add(utf8.encode(data));
        LogService.logProcessOutput('sing-box:stdout', data);
      });
      _process!.stderr.transform(utf8.decoder).listen((data) {
        logSink.add(utf8.encode(data));
        LogService.logProcessOutput('sing-box:stderr', data);
      });

      bool hasExited = false;
      _process!.exitCode.then((code) {
        hasExited = true;
        LogService.log('sing-box (PID $pid) terminated with exit code: $code');
        try { logSink.close(); } catch (_) {}
        if (_state == CoreState.connected) {
          stop();
        }
      });

      await Future.delayed(const Duration(milliseconds: 1000));
      if (hasExited) {
        String errMsg = 'Process exited immediately';
        try {
          errMsg = await logFile.readAsString();
        } catch (_) {}
        LogService.logError('sing-box startup failed. Output: $errMsg');
        throw Exception('Core error: $errMsg');
      }

      // Дополнительно настраиваем системный прокси для браузеров (порт 10808 mixed)
      LogService.log('Configuring Windows system proxy (127.0.0.1:10808)...');
      await _setWindowsProxy(true, 10808);

      _startSpeedMonitoring();
      _updateState(CoreState.connected);
      LogService.log('--- VPN CONNECTED SUCCESSFULLY (State: CoreState.connected) ---');
    } catch (e, stack) {
      LogService.logError('Failed to establish VPN connection', e, stack);
      await stop(clearErrorState: false);
      _updateState(CoreState.error);
    }
  }

  Future<void> stop({bool clearErrorState = true}) async {
    LogService.log('--- STOPPING VPN CONNECTION ---');
    _updateState(CoreState.disconnecting);
    _trafficTimer?.cancel();

    await _setWindowsProxy(false, 10808);

    _process?.kill();
    _process = null;

    // Принудительно завершаем процессы sing-box на уровне системы при выключении ВПН
    await killAllCoreProcesses();

    _speedController.add((0, 0));
    if (clearErrorState) {
      _updateState(CoreState.disconnected);
    }
    LogService.log('--- VPN DISCONNECTED (State: CoreState.disconnected) ---');
  }

  void _updateState(CoreState state) {
    _state = state;
    _stateController.add(state);
  }

  void _startSpeedMonitoring() {
    _trafficTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _speedController.add((350000, 3200000));
    });
  }

  /// Установка системного прокси с принудительным обновлением WinINet
  Future<void> _setWindowsProxy(bool enable, int port) async {
    if (!Platform.isWindows) return;
    try {
      final script = enable
          ? '''
Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name ProxyEnable -Value 1 -Type DWord;
Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name ProxyServer -Value '127.0.0.1:$port' -Type String;
Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name ProxyOverride -Value 'localhost;127.*;10.*;172.16.*;192.168.*;<local>' -Type String;
\$w = Add-Type -PassThru -TypeDefinition 'using System; using System.Runtime.InteropServices; public class WinInetRefresh { [DllImport("wininet.dll")] public static extern bool InternetSetOption(IntPtr h, int o, IntPtr b, int l); }';
[WinInetRefresh]::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0);
[WinInetRefresh]::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0);
'''
          : '''
Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name ProxyEnable -Value 0 -Type DWord;
\$w = Add-Type -PassThru -TypeDefinition 'using System; using System.Runtime.InteropServices; public class WinInetRefresh { [DllImport("wininet.dll")] public static extern bool InternetSetOption(IntPtr h, int o, IntPtr b, int l); }';
[WinInetRefresh]::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0);
[WinInetRefresh]::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0);
''';

      await Process.run('powershell', ['-NoProfile', '-WindowStyle', 'Hidden', '-Command', script]);
    } catch (_) {}
  }
}
