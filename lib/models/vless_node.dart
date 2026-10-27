import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../utils/country_flag_helper.dart';

enum ProxyProtocol { vless, vmess, trojan, shadowsocks, hysteria, hysteria2, unknown }

class VlessNode {
  final String id;
  final ProxyProtocol protocol;
  final String address;
  final int port;
  final String uuid;
  final String flow;
  final String encryption;
  final String streamType;
  final String security;
  final String sni;
  final String fingerprint;
  final String alpn;
  final String host;
  final String publicKey;
  final String shortId;
  final String spiderX;
  final String serviceName;
  final String path;
  final String remark;
  final String subscriptionId;
  final String rawUri;
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
    this.rawUri = '',
    this.pingMs,
    this.downloadSpeedMs,
    this.uploadSpeedMs,
  });

  /// Гарантированная уникальность ID для каждого сервера
  static String generateUniqueId(String uri, String subId, int index) {
    final hash = sha256.convert(utf8.encode('$subId:$index:$uri')).toString().substring(0, 16);
    return '${subId}_${index}_$hash';
  }

  factory VlessNode.fromUri(String rawUri, {String subscriptionId = 'manual', int index = 0}) {
    final clean = rawUri.trim();
    final uniqueId = generateUniqueId(clean, subscriptionId, index);

    if (clean.startsWith('vless://')) {
      return _parseVless(clean, subscriptionId, uniqueId);
    } else if (clean.startsWith('vmess://')) {
      return _parseVmess(clean, subscriptionId, uniqueId);
    } else if (clean.startsWith('trojan://')) {
      return _parseTrojan(clean, subscriptionId, uniqueId);
    } else if (clean.startsWith('ss://')) {
      return _parseShadowsocks(clean, subscriptionId, uniqueId);
    } else if (clean.startsWith('hysteria://') || clean.startsWith('hysteria2://') || clean.startsWith('hy2://')) {
      return _parseHysteria(clean, subscriptionId, uniqueId);
    }

    throw FormatException('Неизвестный протокол ссылки: $clean');
  }

  static VlessNode _parseVless(String rawUri, String subId, String uniqueId) {
    final uri = Uri.parse(rawUri);
    final q = uri.queryParameters;
    final rawRemark = Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : '${uri.host}:${uri.port}');
    final cleanRemark = CountryFlagHelper.cleanRemark(rawRemark);

    return VlessNode(
      id: uniqueId,
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
      remark: cleanRemark,
      subscriptionId: subId,
      rawUri: rawUri,
    );
  }

  static VlessNode _parseVmess(String rawUri, String subId, String uniqueId) {
    final b64Part = rawUri.substring('vmess://'.length);
    final decoded = utf8.decode(base64.decode(base64.normalize(b64Part)));
    final json = jsonDecode(decoded) as Map<String, dynamic>;
    final cleanRemark = CountryFlagHelper.cleanRemark(json['ps']?.toString() ?? 'VMess Server');

    return VlessNode(
      id: uniqueId,
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
      remark: cleanRemark,
      subscriptionId: subId,
      rawUri: rawUri,
    );
  }

  static VlessNode _parseTrojan(String rawUri, String subId, String uniqueId) {
    final uri = Uri.parse(rawUri);
    final q = uri.queryParameters;
    final rawRemark = Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : 'Trojan Server');
    final cleanRemark = CountryFlagHelper.cleanRemark(rawRemark);

    return VlessNode(
      id: uniqueId,
      protocol: ProxyProtocol.trojan,
      address: uri.host,
      port: uri.port,
      uuid: uri.userInfo,
      streamType: q['type'] ?? 'tcp',
      security: q['security'] ?? 'tls',
      sni: q['sni'] ?? uri.host,
      alpn: q['alpn'] ?? '',
      remark: cleanRemark,
      subscriptionId: subId,
      rawUri: rawUri,
    );
  }

  static VlessNode _parseShadowsocks(String rawUri, String subId, String uniqueId) {
    final uri = Uri.parse(rawUri);
    final rawRemark = Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : 'Shadowsocks');
    final cleanRemark = CountryFlagHelper.cleanRemark(rawRemark);
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
      id: uniqueId,
      protocol: ProxyProtocol.shadowsocks,
      address: uri.host,
      port: uri.port,
      uuid: password,
      encryption: method,
      remark: cleanRemark,
      subscriptionId: subId,
      rawUri: rawUri,
    );
  }

  static VlessNode _parseHysteria(String rawUri, String subId, String uniqueId) {
    final uri = Uri.parse(rawUri);
    final isHy2 = rawUri.startsWith('hysteria2://') || rawUri.startsWith('hy2://');
    final q = uri.queryParameters;
    final rawRemark = Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : 'Hysteria');
    final cleanRemark = CountryFlagHelper.cleanRemark(rawRemark);

    return VlessNode(
      id: uniqueId,
      protocol: isHy2 ? ProxyProtocol.hysteria2 : ProxyProtocol.hysteria,
      address: uri.host,
      port: uri.port,
      uuid: uri.userInfo.isNotEmpty ? uri.userInfo : (q['auth'] ?? ''),
      streamType: 'udp',
      security: 'tls',
      sni: q['sni'] ?? uri.host,
      alpn: q['alpn'] ?? '',
      remark: cleanRemark,
      subscriptionId: subId,
      rawUri: rawUri,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'protocol': protocol.name,
        'address': address,
        'port': port,
        'uuid': uuid,
        'flow': flow,
        'encryption': encryption,
        'streamType': streamType,
        'security': security,
        'sni': sni,
        'fingerprint': fingerprint,
        'alpn': alpn,
        'host': host,
        'publicKey': publicKey,
        'shortId': shortId,
        'spiderX': spiderX,
        'serviceName': serviceName,
        'path': path,
        'remark': remark,
        'subscriptionId': subscriptionId,
        'rawUri': rawUri,
        'pingMs': pingMs,
        'downloadSpeedMs': downloadSpeedMs,
        'uploadSpeedMs': uploadSpeedMs,
      };

  factory VlessNode.fromJson(Map<String, dynamic> json) => VlessNode(
        id: json['id'] ?? '',
        protocol: ProxyProtocol.values.firstWhere(
          (e) => e.name == json['protocol'],
          orElse: () => ProxyProtocol.vless,
        ),
        address: json['address'] ?? '',
        port: json['port'] ?? 443,
        uuid: json['uuid'] ?? '',
        flow: json['flow'] ?? '',
        encryption: json['encryption'] ?? 'none',
        streamType: json['streamType'] ?? 'tcp',
        security: json['security'] ?? 'none',
        sni: json['sni'] ?? '',
        fingerprint: json['fingerprint'] ?? 'chrome',
        alpn: json['alpn'] ?? '',
        host: json['host'] ?? '',
        publicKey: json['publicKey'] ?? '',
        shortId: json['shortId'] ?? '',
        spiderX: json['spiderX'] ?? '',
        serviceName: json['serviceName'] ?? '',
        path: json['path'] ?? '',
        remark: json['remark'] ?? '',
        subscriptionId: json['subscriptionId'] ?? 'manual',
        rawUri: json['rawUri'] ?? '',
        pingMs: json['pingMs'],
        downloadSpeedMs: json['downloadSpeedMs'],
        uploadSpeedMs: json['uploadSpeedMs'],
      );

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
      rawUri: rawUri,
      pingMs: pingMs ?? this.pingMs,
      downloadSpeedMs: downloadSpeedMs ?? this.downloadSpeedMs,
      uploadSpeedMs: uploadSpeedMs ?? this.uploadSpeedMs,
    );
  }
}
