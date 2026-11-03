import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

class PingService {
  /// 1. TCP Handshake Ping (честный замер сетевого 3-way handshake к хосту и порту сервера)
  static Future<int> pingTcp(String host, int port, {int timeoutMs = 2500}) async {
    final sw = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(
        host,
        port,
        timeout: Duration(milliseconds: timeoutMs),
      );
      sw.stop();
      socket.destroy();
      final ms = sw.elapsedMilliseconds;
      return ms > 0 ? ms : 1;
    } catch (_) {
      try {
        socket?.destroy();
      } catch (_) {}
      return -1;
    }
  }

  /// 2. ICMP Echo Ping (системный эхо-запрос ping)
  static Future<int> pingIcmp(String host, {int timeoutMs = 2500}) async {
    try {
      ProcessResult result;
      if (Platform.isWindows) {
        result = await Process.run(
          'ping',
          ['-n', '1', '-w', '$timeoutMs', host],
          runInShell: true,
        ).timeout(Duration(milliseconds: timeoutMs + 800));
      } else {
        final sec = (timeoutMs / 1000).ceil();
        result = await Process.run(
          'ping',
          ['-c', '1', '-W', '$sec', host],
        ).timeout(Duration(milliseconds: timeoutMs + 800));
      }

      final out = result.stdout.toString();
      // Поиск строки времени: time=XXms / время=XXмс / time<1ms
      final match = RegExp(r'(?:time|время)[=< ]+([0-9.]+)\s*m?s?', caseSensitive: false).firstMatch(out);
      if (match != null) {
        final val = double.tryParse(match.group(1) ?? '');
        if (val != null) {
          return val.round().clamp(1, 9999);
        }
      }
      return -1;
    } catch (_) {
      return -1;
    }
  }

  /// 3. via Proxy (GET) — HTTP GET через прокси к тестовому эндпоинту
  static Future<int> pingProxyGet(
    VlessNode node, {
    String url = 'http://cp.cloudflare.com/generate_204',
    int timeoutMs = 3500,
    int proxyPort = 10809,
    bool isConnected = false,
  }) async {
    return _pingHttpThroughProxy(
      node: node,
      method: 'GET',
      url: url,
      timeoutMs: timeoutMs,
      proxyPort: proxyPort,
      isConnected: isConnected,
    );
  }

  /// 4. via Proxy (HEAD) — HTTP HEAD через прокси (быстрый запрос только заголовков)
  static Future<int> pingProxyHead(
    VlessNode node, {
    String url = 'http://cp.cloudflare.com/generate_204',
    int timeoutMs = 3500,
    int proxyPort = 10809,
    bool isConnected = false,
  }) async {
    return _pingHttpThroughProxy(
      node: node,
      method: 'HEAD',
      url: url,
      timeoutMs: timeoutMs,
      proxyPort: proxyPort,
      isConnected: isConnected,
    );
  }

  static Future<int> _pingHttpThroughProxy({
    required VlessNode node,
    required String method,
    required String url,
    required int timeoutMs,
    required int proxyPort,
    required bool isConnected,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final client = HttpClient();
      client.connectionTimeout = Duration(milliseconds: timeoutMs);

      if (isConnected) {
        // Если VPN туннель активен, направляем через локальный HTTP прокси Xray (10809)
        client.findProxy = (uri) => "PROXY 127.0.0.1:$proxyPort";
      }

      final uri = Uri.parse(url);
      final HttpClientRequest request = method == 'HEAD'
          ? await client.headUrl(uri).timeout(Duration(milliseconds: timeoutMs))
          : await client.getUrl(uri).timeout(Duration(milliseconds: timeoutMs));

      request.headers.set('User-Agent', 'MaterialVless/3.0');
      request.headers.set('Connection', 'close');

      final response = await request.close().timeout(Duration(milliseconds: timeoutMs));
      sw.stop();
      client.close(force: true);

      if (response.statusCode >= 200 && response.statusCode < 400) {
        final ms = sw.elapsedMilliseconds;
        return ms > 0 ? ms : 1;
      }

      // Если туннель не запущен для этого узла, измеряем реальное TCP-рукопожатие к его порту
      if (!isConnected) {
        return await pingTcp(node.address, node.port, timeoutMs: timeoutMs);
      }
      return -1;
    } catch (_) {
      if (!isConnected) {
        return await pingTcp(node.address, node.port, timeoutMs: timeoutMs);
      }
      return -1;
    }
  }

  /// Универсальный вызов выбранного метода пинга для одного узла
  static Future<int> testNode(
    VlessNode node,
    PingType type, {
    String url = 'http://cp.cloudflare.com/generate_204',
    int timeoutMs = 3000,
    int proxyPort = 10809,
    bool isConnected = false,
  }) async {
    switch (type) {
      case PingType.proxyGet:
        return pingProxyGet(node, url: url, timeoutMs: timeoutMs, proxyPort: proxyPort, isConnected: isConnected);
      case PingType.proxyHead:
        return pingProxyHead(node, url: url, timeoutMs: timeoutMs, proxyPort: proxyPort, isConnected: isConnected);
      case PingType.tcp:
        return pingTcp(node.address, node.port, timeoutMs: timeoutMs);
      case PingType.icmp:
        return pingIcmp(node.address, timeoutMs: timeoutMs);
    }
  }
}
