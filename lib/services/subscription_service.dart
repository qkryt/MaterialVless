import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/vless_node.dart';
import '../models/subscription_info.dart';
import 'hwid_service.dart';

class SubscriptionService {
  static Future<(List<VlessNode>, SubscriptionInfo?)> fetchSubscription(String url) async {
    final hwid = await HwidService.getHWID();

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'MaterialVless-Client/1.0.0 (${Platform.operatingSystem}; HWID: $hwid)',
        'X-HWID': hwid,
        'X-Client-Name': 'MaterialVless',
        'Accept': 'application/json, text/plain, */*',
      },
    );

    if (response.statusCode != 200) {
      throw HttpException('Ошибка обновления подписки: HTTP ${response.statusCode}');
    }

    SubscriptionInfo? info;
    final userInfoHeader = response.headers['subscription-userinfo'];
    if (userInfoHeader != null) {
      info = _parseUserInfo(userInfoHeader);
    }

    String body = response.body.trim();
    try {
      body = utf8.decode(base64.decode(base64.normalize(body)));
    } catch (_) {
      // Контент уже содержит открытый текст
    }

    final nodes = <VlessNode>[];
    for (final line in const LineSplitter().convert(body)) {
      final trimmed = line.trim();
      if (trimmed.startsWith('vless://')) {
        try {
          nodes.add(VlessNode.fromUri(trimmed));
        } catch (_) {}
      }
    }

    return (nodes, info);
  }

  static SubscriptionInfo _parseUserInfo(String header) {
    int upload = 0, download = 0, total = 0, expire = 0;
    for (final part in header.split(';')) {
      final keyValue = part.split('=');
      if (keyValue.length == 2) {
        final key = keyValue[0].trim();
        final value = int.tryParse(keyValue[1].trim()) ?? 0;
        if (key == 'upload') upload = value;
        if (key == 'download') download = value;
        if (key == 'total') total = value;
        if (key == 'expire') expire = value;
      }
    }
    return SubscriptionInfo(
      uploadBytes: upload,
      downloadBytes: download,
      totalBytes: total,
      expireDate: DateTime.fromMillisecondsSinceEpoch(expire * 1000),
    );
  }

  static Future<int> pingNode(VlessNode node) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        node.address,
        node.port,
        timeout: const Duration(milliseconds: 2500),
      );
      stopwatch.stop();
      await socket.close();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return -1;
    }
  }
}