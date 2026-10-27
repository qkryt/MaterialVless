import 'dart:convert';

enum ProxyProtocol { vless, vmess, trojan, shadowsocks, hysteria, hysteria2, unknown }

class VlessNode {
  final String id;
  final ProxyProtocol protocol;
  final String address;
  final int port;
  final String uuid; // or password for trojan/ss/hy2
  final String flow;
  final String encryption;
  final String streamType; // tcp, grpc, ws, xhttp, splithttp, udp
  final String security;   // reality, tls, none
  final String sni;
  final String fingerprint; // chrome, android, safari, etc.
  final String alpn;
  final String host;
  final String publicKey;  // Reality pbk
  final String shortId;    // Reality sid
  final String spiderX;
  final String serviceName; // gRPC
  final String path;        // WebSocket / xhttp path
  final String remark;
  final String subscriptionId;
  int? pingMs;
  int? downloadSpeedMs;
  int? uploadSpeedMs;

  VlessNode({
    required this.id,
    this.protocol = ProxyProtocol.vless,
    required this.address,
    required this.port,
    required this.uuid,
    this.flow = '',
    this.encryption = 'none',
    this.streamType = 'tcp',
    this.security = 'none',
    this.sni = '',
    this.fingerprint = 'chrome',
    this.alpn = '',
    this.host = '',
    this.publicKey = '',
    this.shortId = '',
    this.spiderX = '',
    this.serviceName = '',
    this.path = '',
    required this.remark,
    this.subscriptionId = 'manual',
    this.pingMs,
    this.downloadSpeedMs,
    this.uploadSpeedMs,
  });

  /// Универсальный парсер ссылок (vless, vmess, trojan, ss, hysteria, hysteria2)
  factory VlessNode.fromUri(String rawUri, {String subscriptionId = 'manual'}) {
    final clean = rawUri.trim();

    if (clean.startsWith('vless://')) {
      return _parseVless(clean, subscriptionId);
    } else if (clean.startsWith('vmess://')) {
      return _parseVmess(clean, subscriptionId);
    } else if (clean.startsWith('trojan://')) {
      return _parseTrojan(clean, subscriptionId);
    } else if (clean.startsWith('ss://')) {
      return _parseShadowsocks(clean, subscriptionId);
    } else if (clean.startsWith('hysteria://') || clean.startsWith('hysteria2://') || clean.startsWith('hy2://')) {
      return _parseHysteria(clean, subscriptionId);
    }

    throw FormatException('Неизвестный протокол ссылки: $clean');
  }

  static VlessNode _parseVless(String rawUri, String subId) {
    final uri = Uri.parse(rawUri);
    final q = uri.queryParameters;
    final remark = Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : '${uri.host}:${uri.port}');

    return VlessNode(
      id: '${uri.host}:${uri.port}_${uri.userInfo}_${DateTime.now().microsecondsSinceEpoch}',
      protocol: ProxyProtocol.vless,
      address: uri.host,
      port: uri.port,
      uuid: uri.userInfo,
      flow: q['flow'] ?? '',
      encryption: q['encryption'] ?? 'none',
      streamType: q['type'] ?? 'tcp',
      security: q['security'] ?? 'none',
      sni: q['sni'] ?? '',
      fingerprint: q['fp'] ?? 'chrome',
      alpn: q['alpn'] ?? '',
      host: q['host'] ?? '',
      publicKey: q['pbk'] ?? '',
      shortId: q['sid'] ?? '',
      spiderX: q['spx'] ?? '',
      serviceName: q['serviceName'] ?? '',
      path: q['path'] ?? '',
      remark: remark,
      subscriptionId: subId,
    );
  }

  static VlessNode _parseVmess(String rawUri, String subId) {
    final b64Part = rawUri.substring('vmess://'.length);
    final decoded = utf8.decode(base64.decode(base64.normalize(b64Part)));
    final json = jsonDecode(decoded) as Map<String, dynamic>;

    return VlessNode(
      id: '${json['add']}:${json['port']}_${json['id']}',
      protocol: ProxyProtocol.vmess,
      address: json['add']?.toString() ?? '',
      port: int.tryParse(json['port']?.toString() ?? '443') ?? 443,
      uuid: json['id']?.toString() ?? '',
      encryption: json['scy']?.toString() ?? 'auto',
      streamType: json['net']?.toString() ?? 'tcp',
      security: json['tls']?.toString() == 'tls' ? 'tls' : 'none',
      sni: json['sni']?.toString() ?? json['host']?.toString() ?? '',
      host: json['host']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      remark: json['ps']?.toString() ?? 'VMess Server',
      subscriptionId: subId,
    );
  }

  static VlessNode _parseTrojan(String rawUri, String subId) {
    final uri = Uri.parse(rawUri);
    final q = uri.queryParameters;
    final remark = Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : 'Trojan Server');

    return VlessNode(
      id: '${uri.host}:${uri.port}_${uri.userInfo}',
      protocol: ProxyProtocol.trojan,
      address: uri.host,
      port: uri.port,
      uuid: uri.userInfo, // trojan password
      streamType: q['type'] ?? 'tcp',
      security: q['security'] ?? 'tls',
      sni: q['sni'] ?? uri.host,
      alpn: q['alpn'] ?? '',
      remark: remark,
      subscriptionId: subId,
    );
  }

  static VlessNode _parseShadowsocks(String rawUri, String subId) {
    final uri = Uri.parse(rawUri);
    final remark = Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : 'Shadowsocks');
    String userInfo = uri.userInfo;
    if (!userInfo.contains(':')) {
      try {
        userInfo = utf8.decode(base64.decode(base64.normalize(userInfo)));
      } catch (_) {}
    }
    final parts = userInfo.split(':');
    final method = parts.isNotEmpty ? parts[0] : 'aes-256-gcm';
    final password = parts.length > 1 ? parts[1] : '';

    return VlessNode(
      id: '${uri.host}:${uri.port}_ss',
      protocol: ProxyProtocol.shadowsocks,
      address: uri.host,
      port: uri.port,
      uuid: password,
      encryption: method,
      remark: remark,
      subscriptionId: subId,
    );
  }

  static VlessNode _parseHysteria(String rawUri, String subId) {
    final uri = Uri.parse(rawUri);
    final isHy2 = rawUri.startsWith('hysteria2://') || rawUri.startsWith('hy2://');
    final q = uri.queryParameters;
    final remark = Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : 'Hysteria');

    return VlessNode(
      id: '${uri.host}:${uri.port}_hy',
      protocol: isHy2 ? ProxyProtocol.hysteria2 : ProxyProtocol.hysteria,
      address: uri.host,
      port: uri.port,
      uuid: uri.userInfo.isNotEmpty ? uri.userInfo : (q['auth'] ?? ''),
      streamType: 'udp',
      security: 'tls',
      sni: q['sni'] ?? uri.host,
      alpn: q['alpn'] ?? '',
      remark: remark,
      subscriptionId: subId,
    );
  }

  VlessNode copyWith({
    int? pingMs,
    int? downloadSpeedMs,
    int? uploadSpeedMs,
    String? remark,
  }) {
    return VlessNode(
      id: id,
      protocol: protocol,
      address: address,
      port: port,
      uuid: uuid,
      flow: flow,
      encryption: encryption,
      streamType: streamType,
      security: security,
      sni: sni,
      fingerprint: fingerprint,
      alpn: alpn,
      host: host,
      publicKey: publicKey,
      shortId: shortId,
      spiderX: spiderX,
      serviceName: serviceName,
      path: path,
      remark: remark ?? this.remark,
      subscriptionId: subscriptionId,
      pingMs: pingMs ?? this.pingMs,
      downloadSpeedMs: downloadSpeedMs ?? this.downloadSpeedMs,
      uploadSpeedMs: uploadSpeedMs ?? this.uploadSpeedMs,
    );
  }
}
