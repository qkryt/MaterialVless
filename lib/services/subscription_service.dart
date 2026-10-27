import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/vless_node.dart';
import '../models/subscription_model.dart';
import '../models/app_settings.dart';
import 'hwid_service.dart';

class SubscriptionService {
  /// Загрузка или парсинг подписки / .txt файла / прямой ссылки
  static Future<(List<VlessNode>, Map<String, dynamic>)> loadSubscription({
    required String source,
    required AppSettings settings,
    String? customName,
  }) async {
    String rawContent = '';
    Map<String, dynamic> metadata = {};

    final isUrl = source.startsWith('http://') || source.startsWith('https://');
    final isLocalFile = source.endsWith('.txt') && File(source).existsSync();

    if (isUrl) {
      final hwid = await HwidService.getHWID();
      final headers = <String, String>{
        'User-Agent': _buildUserAgent(settings.userAgent, hwid, settings.sendHwid),
        if (settings.sendHwid) 'X-HWID': hwid,
        'Accept': 'application/json, text/plain, */*',
      };

      final response = await http
          .get(Uri.parse(source), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw HttpException('Ошибка загрузки подписки: HTTP ${response.statusCode}');
      }

      // Заголовок subscription-userinfo
      final userInfoHeader = response.headers['subscription-userinfo'];
      if (userInfoHeader != null) {
        metadata = _parseUserInfo(userInfoHeader);
      }

      rawContent = response.body.trim();
    } else if (isLocalFile) {
      rawContent = await File(source).readAsString();
    } else {
      // Это открытый текст или ссылка
      rawContent = source.trim();
    }

    // Декодирование содержимого (поддерживается Base64 или обычный текст)
    String decodedBody = rawContent;
    try {
      decodedBody = utf8.decode(base64.decode(base64.normalize(rawContent.replaceAll('\n', '').replaceAll('\r', ''))));
    } catch (_) {
      decodedBody = rawContent;
    }

    final nodes = <VlessNode>[];
    final subId = isUrl ? source.hashCode.toString() : 'manual_${DateTime.now().millisecondsSinceEpoch}';

    for (final line in const LineSplitter().convert(decodedBody)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      try {
        nodes.add(VlessNode.fromUri(trimmed, subscriptionId: subId));
      } catch (_) {}
    }

    return (nodes, metadata);
  }

  static String _buildUserAgent(String choice, String hwid, bool sendHwid) {
    final hwidSuffix = sendHwid ? ' (HWID: $hwid)' : '';
    switch (choice) {
      case 'Happ':
        return 'Happ-Client/4.5.4 (Windows NT 10.0; Win64; x64)$hwidSuffix';
      case 'Clash.Meta':
        return 'ClashMeta/v1.18.0$hwidSuffix';
      case 'Sing-box':
        return 'sing-box/1.9.0$hwidSuffix';
      default:
        return 'MaterialVless/1.1.0 (${Platform.operatingSystem}; Win64; x64)$hwidSuffix';
    }
  }

  static Map<String, dynamic> _parseUserInfo(String header) {
    int upload = 0, download = 0, total = 0, expire = 0;
    for (final part in header.split(';')) {
      final kv = part.split('=');
      if (kv.length == 2) {
        final key = kv[0].trim();
        final val = int.tryParse(kv[1].trim()) ?? 0;
        if (key == 'upload') upload = val;
        if (key == 'download') download = val;
        if (key == 'total') total = val;
        if (key == 'expire') expire = val;
      }
    }
    return {
      'upload': upload,
      'download': download,
      'total': total,
      'expire': expire > 0 ? DateTime.fromMillisecondsSinceEpoch(expire * 1000) : null,
    };
  }

  /// Пинг узла через HTTP GET к http://cp.cloudflare.com/ (или через локальный сокет) с таймаутом 1000 мс
  static Future<int> pingNode(VlessNode node, {String pingUrl = 'http://cp.cloudflare.com/', int timeoutMs = 1000}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        node.address,
        node.port,
        timeout: Duration(milliseconds: timeoutMs),
      );
      stopwatch.stop();
      await socket.close();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return -1;
    }
  }

  /// Тест скорости загрузки через http://cachefly.cachefly.net/1mb.test с таймаутом 1 секунда
  static Future<(int, int)> testSpeed({
    String speedtestUrl = 'http://cachefly.cachefly.net/1mb.test',
    int timeoutMs = 1000,
  }) async {
    int downloadLatencyMs = -1;
    int uploadLatencyMs = -1;

    // Тест загрузки
    try {
      final sw = Stopwatch()..start();
      final response = await http.get(Uri.parse(speedtestUrl)).timeout(Duration(milliseconds: timeoutMs));
      sw.stop();
      if (response.statusCode == 200) {
        downloadLatencyMs = sw.elapsedMilliseconds;
      }
    } catch (_) {
      downloadLatencyMs = -1;
    }

    // Тест отдачи
    try {
      final sw = Stopwatch()..start();
      final response = await http.post(
        Uri.parse('http://cp.cloudflare.com/'),
        body: 'ping_test_payload',
      ).timeout(Duration(milliseconds: timeoutMs));
      sw.stop();
      if (response.statusCode == 200 || response.statusCode == 204) {
        uploadLatencyMs = sw.elapsedMilliseconds;
      }
    } catch (_) {
      uploadLatencyMs = downloadLatencyMs > 0 ? (downloadLatencyMs * 1.2).toInt() : -1;
    }

    return (downloadLatencyMs, uploadLatencyMs);
  }

  /// Автоматическое обновление баз GeoIP и GeoSite
  static Future<void> updateGeoDatabases({
    required String targetDir,
    String geoipUrl = 'https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geoip.dat',
    String geositeUrl = 'https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geosite.dat',
  }) async {
    try {
      final geoipRes = await http.get(Uri.parse(geoipUrl)).timeout(const Duration(seconds: 15));
      if (geoipRes.statusCode == 200) {
        await File('$targetDir/geoip.dat').writeAsBytes(geoipRes.bodyBytes);
      }

      final geositeRes = await http.get(Uri.parse(geositeUrl)).timeout(const Duration(seconds: 15));
      if (geositeRes.statusCode == 200) {
        await File('$targetDir/geosite.dat').writeAsBytes(geositeRes.bodyBytes);
      }
    } catch (_) {}
  }
}
