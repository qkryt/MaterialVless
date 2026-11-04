import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/vless_node.dart';
import 'log_service.dart';

enum PingType {
  proxyGet('via Proxy(GET)'),
  proxyHead('via Proxy(HEAD)'),
  tcp('TCP'),
  icmp('ICMP');

  final String label;
  const PingType(this.label);

  static PingType fromString(String? val) {
    if (val == null) return PingType.proxyGet;
    final lower = val.toLowerCase().trim();
    if (lower.contains('head')) return PingType.proxyHead;
    if (lower.contains('tcp')) return PingType.tcp;
    if (lower.contains('icmp')) return PingType.icmp;
    return PingType.proxyGet;
  }
}

/// 1. Via Proxy (GET)
Future<double?> pingProxyGet(
  String url,
  String proxy, {
  Duration timeout = const Duration(seconds: 5),
}) => PingService.pingProxyGet(url, proxy, timeout: timeout);

/// 2. Via Proxy (HEAD)
Future<double?> pingProxyHead(
  String url,
  String proxy, {
  Duration timeout = const Duration(seconds: 5),
}) => PingService.pingProxyHead(url, proxy, timeout: timeout);

/// 3. TCP Ping
Future<double?> pingTcp(
  String host,
  int port, {
  Duration timeout = const Duration(seconds: 5),
}) => PingService.pingTcp(host, port, timeout: timeout);

/// 4. ICMP Ping
Future<double?> pingIcmp(
  String host, {
  Duration timeout = const Duration(seconds: 3),
}) => PingService.pingIcmp(host, timeout: timeout);

class PingService {
  /// 1. Via Proxy (GET)
  static Future<double?> pingProxyGet(
    String url,
    String proxy, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final httpClient = HttpClient()
      ..connectionTimeout = timeout
      ..findProxy = (_) => 'PROXY $proxy';
    final client = IOClient(httpClient);
    try {
      final stopwatch = Stopwatch()..start();
      final response = await client.get(Uri.parse(url)).timeout(timeout);
      stopwatch.stop();
      if (response.statusCode >= 200 && response.statusCode < 400) {
        return stopwatch.elapsedMicroseconds / 1000;
      }
      LogService.warning('Ping via Proxy (GET) HTTP ${response.statusCode} for $url');
      return null;
    } catch (e) {
      LogService.warning('Ping via Proxy (GET) error: $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// 2. Via Proxy (HEAD)
  static Future<double?> pingProxyHead(
    String url,
    String proxy, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final httpClient = HttpClient()
      ..connectionTimeout = timeout
      ..findProxy = (_) => 'PROXY $proxy';
    final client = IOClient(httpClient);
    try {
      final stopwatch = Stopwatch()..start();
      final response = await client.head(Uri.parse(url)).timeout(timeout);
      stopwatch.stop();
      if (response.statusCode >= 200 && response.statusCode < 400) {
        return stopwatch.elapsedMicroseconds / 1000;
      }
      LogService.warning('Ping via Proxy (HEAD) HTTP ${response.statusCode} for $url');
      return null;
    } catch (e) {
      LogService.warning('Ping via Proxy (HEAD) error: $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// 3. TCP Ping
  static Future<double?> pingTcp(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stopwatch = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(
        host,
        port,
        timeout: timeout,
      );
      stopwatch.stop();
      return stopwatch.elapsedMicroseconds / 1000;
    } catch (e) {
      LogService.warning('Ping TCP error ($host:$port): $e');
      return null;
    } finally {
      try {
        socket?.destroy();
      } catch (_) {}
    }
  }

  /// 4. ICMP Ping
  static Future<double?> pingIcmp(
    String host, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final timeoutMs = timeout.inMilliseconds;
      final timeoutSec = timeout.inSeconds <= 0 ? 1 : timeout.inSeconds;
      final result = await Process.run(
        'ping',
        Platform.isWindows
            ? ['-n', '1', '-w', '$timeoutMs', host]
            : ['-c', '1', '-W', '$timeoutSec', host],
      ).timeout(Duration(milliseconds: timeoutMs + 800));

      final output = result.stdout.toString();
      final match = RegExp(
        r'(?:time|время|време)[=<]\s*([\d.,]+)\s*(?:ms|мс)?',
        caseSensitive: false,
      ).firstMatch(output) ?? RegExp(
        r'time[=<]\s*([\d.,]+)\s*ms',
        caseSensitive: false,
      ).firstMatch(output);

      if (match == null) return null;
      return double.tryParse(
        match.group(1)!.replaceAll(',', '.'),
      );
    } catch (e) {
      LogService.warning('Ping ICMP error ($host): $e');
      return null;
    }
  }

  /// Test node with selected PingType and return ms (-1 on failure)
  static Future<int> testNode(
    VlessNode node,
    PingType type, {
    String url = 'http://cp.cloudflare.com/generate_204',
    int timeoutMs = 3000,
    int proxyPort = 10809,
    bool isConnected = false,
  }) async {
    final timeout = Duration(milliseconds: timeoutMs);
    double? result;

    switch (type) {
      case PingType.proxyGet:
        if (!isConnected) {
          result = await pingTcp(node.address, node.port, timeout: timeout);
        } else {
          result = await pingProxyGet(url, '127.0.0.1:$proxyPort', timeout: timeout);
        }
        break;

      case PingType.proxyHead:
        if (!isConnected) {
          result = await pingTcp(node.address, node.port, timeout: timeout);
        } else {
          result = await pingProxyHead(url, '127.0.0.1:$proxyPort', timeout: timeout);
        }
        break;

      case PingType.tcp:
        result = await pingTcp(node.address, node.port, timeout: timeout);
        break;

      case PingType.icmp:
        result = await pingIcmp(node.address, timeout: timeout);
        break;
    }

    if (result == null || result <= 0) {
      return -1;
    }
    return result.round().clamp(1, 9999);
  }
}
