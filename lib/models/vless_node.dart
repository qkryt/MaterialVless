class VlessNode {
  final String id;
  final String address;
  final int port;
  final String uuid;
  final String flow;
  final String encryption;
  final String streamType;
  final String security;
  final String sni;
  final String fingerprint;
  final String publicKey;
  final String shortId;
  final String spiderX;
  final String serviceName;
  final String path;
  final String remark;
  final int? pingMs;

  VlessNode({
    required this.id,
    required this.address,
    required this.port,
    required this.uuid,
    this.flow = '',
    this.encryption = 'none',
    this.streamType = 'tcp',
    this.security = 'none',
    this.sni = '',
    this.fingerprint = 'chrome',
    this.publicKey = '',
    this.shortId = '',
    this.spiderX = '',
    this.serviceName = '',
    this.path = '',
    required this.remark,
    this.pingMs,
  });

  factory VlessNode.fromUri(String rawUri) {
    final uri = Uri.parse(rawUri);
    if (uri.scheme != 'vless') {
      throw FormatException('Неподдерживаемый протокол: ${uri.scheme}');
    }

    final query = uri.queryParameters;
    return VlessNode(
      id: '${uri.host}:${uri.port}_${uri.userInfo}',
      address: uri.host,
      port: uri.port,
      uuid: uri.userInfo,
      flow: query['flow'] ?? '',
      encryption: query['encryption'] ?? 'none',
      streamType: query['type'] ?? 'tcp',
      security: query['security'] ?? 'none',
      sni: query['sni'] ?? '',
      fingerprint: query['fp'] ?? 'chrome',
      publicKey: query['pbk'] ?? '',
      shortId: query['sid'] ?? '',
      spiderX: query['spx'] ?? '',
      serviceName: query['serviceName'] ?? '',
      path: query['path'] ?? '',
      remark: Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : uri.host),
    );
  }

  VlessNode copyWith({int? pingMs}) {
    return VlessNode(
      id: id,
      address: address,
      port: port,
      uuid: uuid,
      flow: flow,
      encryption: encryption,
      streamType: streamType,
      security: security,
      sni: sni,
      fingerprint: fingerprint,
      publicKey: publicKey,
      shortId: shortId,
      spiderX: spiderX,
      serviceName: serviceName,
      path: path,
      remark: remark,
      pingMs: pingMs ?? this.pingMs,
    );
  }
}