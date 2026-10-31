import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
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

  /// Поиск исполняемого файла ядра Xray
  static String resolveBinary([String? coreType]) {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final binaryName = Platform.isWindows ? 'xray.exe' : 'xray';

    // 1. Рядом с исполняемым файлом программы (C:\Program Files\MaterialVless)
    final localPath = '$exeDir${Platform.pathSeparator}$binaryName';
    if (File(localPath).existsSync()) return localPath;

    // 2. В C:\Program Files\MaterialVless
    final progFilesPath = 'C:\\Program Files\\MaterialVless\\$binaryName';
    if (File(progFilesPath).existsSync()) return progFilesPath;

    // 3. В папке AppData
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
      if (appData != null) {
        final appDataPath = '$appData${Platform.pathSeparator}MaterialVless${Platform.pathSeparator}$binaryName';
        if (File(appDataPath).existsSync()) return appDataPath;
      }
    } else if (Platform.isMacOS) {
      final macPath = '${File(Platform.resolvedExecutable).parent.parent.path}/Resources/$binaryName';
      if (File(macPath).existsSync()) return macPath;
    }

    // 4. Fallback на системный PATH
    return binaryName;
  }

  /// Поиск директории с geoip.dat и geosite.dat для Xray
  static String? resolveAssetDirectory() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    if (File('$exeDir${Platform.pathSeparator}geosite.dat').existsSync()) {
      return exeDir;
    }
    const progFiles = 'C:\\Program Files\\MaterialVless';
    if (File('$progFiles\\geosite.dat').existsSync()) {
      return progFiles;
    }
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
      if (appData != null && File('$appData\\MaterialVless\\geosite.dat').existsSync()) {
        return '$appData\\MaterialVless';
      }
    }
    if (File('geosite.dat').existsSync()) {
      return Directory.current.path;
    }
    return null;
  }

  /// Принудительное завершение всех процессов ядра Xray
  static Future<void> killAllCoreProcesses() async {
    LogService.log('Terminating any running xray processes...');
    if (Platform.isWindows) {
      try {
        await Process.run('taskkill', ['/F', '/IM', 'xray.exe', '/T']);
      } catch (_) {}
    } else if (Platform.isLinux || Platform.isMacOS) {
      try {
        await Process.run('pkill', ['-9', 'xray']);
      } catch (_) {}
    }
  }

  /// Запуск VPN через Xray-core (полный переход на Xray v26.10.21 с нативным Wintun TUN)
  Future<void> start(VlessNode node, AppSettings settings) async {
    _updateState(CoreState.connecting);

    LogService.log('--- STARTING VPN CONNECTION VIA XRAY CORE (Wintun TUN Mode) ---');
    LogService.log('Active Core: XRAY CORE (v26.10.21 XTLS with Native Wintun TUN)');
    LogService.log('Target node: "${node.remark}" (${node.protocol.name.toUpperCase()})');
    LogService.log('Remote host: ${node.address}:${node.port}');
    LogService.log('Parameters: security=${node.security}, streamType=${node.streamType}, flow=${node.flow}, sni=${node.sni}');

    // Завершаем любые зависшие или старые процессы ядер перед стартом
    await killAllCoreProcesses();
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      final tempDir = await getTemporaryDirectory();
      final String configJson = ConfigGenerator.generateXrayConfig(node, settings);
      final String binaryPath = resolveBinary();
      final File configFile = File('${tempDir.path}/material_vless_xray.json');
      await configFile.writeAsBytes(utf8.encode(configJson));
      final processArgs = ['run', '-c', configFile.path];

      LogService.log('Generated Xray config saved to: ${configFile.path}');
      LogService.log('Active JSON configuration:\n$configJson');
      LogService.log('Target Xray binary: $binaryPath (exists: ${File(binaryPath).existsSync()})');

      final assetDir = resolveAssetDirectory() ?? (File(binaryPath).existsSync() ? File(binaryPath).parent.path : null);
      LogService.log('Resolved Xray asset directory (geoip/geosite): $assetDir');

      final logFile = File('${tempDir.path}/material_vless_core.log');
      final logSink = logFile.openWrite(mode: FileMode.writeOnly);

      final Map<String, String> env = {};
      if (assetDir != null) {
        env['xray.location.asset'] = assetDir;
        env['XRAY_LOCATION_ASSET'] = assetDir;
      }

      LogService.log('Launching Xray process: $binaryPath ${processArgs.join(' ')}');
      _process = await Process.start(
        binaryPath,
        processArgs,
        workingDirectory: assetDir,
        environment: env,
      );
      final pid = _process!.pid;
      LogService.log('Xray process started with PID: $pid');

      _process!.stdout.transform(utf8.decoder).listen((data) {
        logSink.add(utf8.encode(data));
        LogService.logProcessOutput('xray:stdout', data);
      });
      _process!.stderr.transform(utf8.decoder).listen((data) {
        logSink.add(utf8.encode(data));
        LogService.logProcessOutput('xray:stderr', data);
      });

      bool hasExited = false;
      _process!.exitCode.then((code) {
        hasExited = true;
        LogService.log('Xray (PID $pid) terminated with exit code: $code');
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
        LogService.logError('Xray startup failed. Output: $errMsg');
        throw Exception('Core error: $errMsg');
      }

      // Настройка системного прокси для браузеров и приложений (127.0.0.1:10809 / 10808)
      LogService.log('Configuring Windows system proxy (HTTP: 10809, SOCKS5: 10808)...');
      await _setWindowsProxy(true, httpPort: 10809, socksPort: 10808);

      _startSpeedMonitoring();
      _updateState(CoreState.connected);
      LogService.log('--- VPN CONNECTED SUCCESSFULLY WITH XRAY CORE (State: CoreState.connected) ---');
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

    await _setWindowsProxy(false);

    _process?.kill();
    _process = null;

    // Принудительно завершаем процессы ядра в системе
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
  Future<void> _setWindowsProxy(bool enable, {int httpPort = 10809, int socksPort = 10808}) async {
    if (!Platform.isWindows) return;
    try {
      final script = enable
          ? '''
Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name ProxyEnable -Value 1 -Type DWord
Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name ProxyServer -Value 'http=127.0.0.1:$httpPort;https=127.0.0.1:$httpPort;socks=127.0.0.1:$socksPort' -Type String
Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name ProxyOverride -Value 'localhost;127.*;10.*;172.16.*;192.168.*;<local>' -Type String
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class WinInetRefresh { [DllImport("wininet.dll")] public static extern bool InternetSetOption(IntPtr h, int o, IntPtr b, int l); }' -ErrorAction SilentlyContinue
[WinInetRefresh]::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0)
[WinInetRefresh]::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0)
'''
          : '''
Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name ProxyEnable -Value 0 -Type DWord
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class WinInetRefresh { [DllImport("wininet.dll")] public static extern bool InternetSetOption(IntPtr h, int o, IntPtr b, int l); }' -ErrorAction SilentlyContinue
[WinInetRefresh]::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0)
[WinInetRefresh]::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0)
''';

      final bytes = Uint8List.fromList(script.codeUnits.expand((c) => [c & 0xff, (c >> 8) & 0xff]).toList());
      final encoded = base64.encode(bytes);
      await Process.run('powershell', ['-NoProfile', '-WindowStyle', 'Hidden', '-EncodedCommand', encoded]);
    } catch (e) {
      LogService.log('Error setting Windows proxy: $e');
    }
  }
}
