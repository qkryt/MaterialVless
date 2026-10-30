import 'dart:convert';
import 'dart:io';
import '../models/vless_node.dart';
import '../models/app_settings.dart';

class ConfigGenerator {
  /// Формирование наборов правил sing-box rule_set для маршрутизации
  static (List<Map<String, dynamic>>, List<String>, List<String>) _buildRouteRuleSets(String? rulesDir) {
    final List<Map<String, dynamic>> ruleSets = [];
    final List<String> ruGeositeTags = [];
    final List<String> ruGeoipTags = [];

    void addRuleSet({
      required String tag,
      required String filename,
      required String remoteUrl,
      required bool isIp,
    }) {
      String? localPath;
      if (rulesDir != null && rulesDir.isNotEmpty) {
        final f = File('$rulesDir/$filename');
        if (f.existsSync() && f.lengthSync() > 0) {
          localPath = f.path.replaceAll('\\', '/');
        }
      }
      if (localPath == null) {
        final exeDir = File(Platform.resolvedExecutable).parent.path.replaceAll('\\', '/');
        final candidate = '$exeDir/rules/$filename';
        if (File(candidate).existsSync() && File(candidate).lengthSync() > 0) {
          localPath = candidate;
        }
      }
      if (localPath == null) {
        final localAssetsCandidate = 'assets/rules/$filename';
        if (File(localAssetsCandidate).existsSync() && File(localAssetsCandidate).lengthSync() > 0) {
          localPath = File(localAssetsCandidate).absolute.path.replaceAll('\\', '/');
        }
      }

      if (localPath != null) {
        ruleSets.add({
          "tag": tag,
          "type": "local",
          "format": "binary",
          "path": localPath,
        });
      } else {
        ruleSets.add({
          "tag": tag,
          "type": "remote",
          "format": "binary",
          "url": remoteUrl,
          "download_detour": "direct",
        });
      }

      if (isIp) {
        ruGeoipTags.add(tag);
      } else {
        ruGeositeTags.add(tag);
      }
    }

    addRuleSet(
      tag: "geosite-category-ru",
      filename: "geosite-category-ru.srs",
      remoteUrl: "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ru.srs",
      isIp: false,
    );
    addRuleSet(
      tag: "geosite-tld-ru",
      filename: "geosite-tld-ru.srs",
      remoteUrl: "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-tld-ru.srs",
      isIp: false,
    );
    addRuleSet(
      tag: "geoip-ru",
      filename: "geoip-ru.srs",
      remoteUrl: "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-ru.srs",
      isIp: true,
    );

    return (ruleSets, ruGeositeTags, ruGeoipTags);
  }

  static String generate(VlessNode node, AppSettings settings, {String? rulesDir}) {
    final Map<String, dynamic> outbound = _buildOutbound(node);
    final (ruleSets, ruGeositeTags, ruGeoipTags) = _buildRouteRuleSets(rulesDir);

    final List<Map<String, dynamic>> routeRules = [
      // Перехват входящих DNS запросов только от виртуального адаптера tun-in (избегает циклов)
      {
        "inbound": ["tun-in"],
        "port": 53,
        "action": "hijack-dns"
      },
      {
        "inbound": ["tun-in"],
        "protocol": "dns",
        "action": "hijack-dns"
      },
      // Прямой доступ к локальным DNS серверам
      {
        "ip_cidr": ["77.88.8.8/32", "77.88.8.1/32"],
        "outbound": "direct"
      },
      // Прямой доступ к самому серверу прокси (предотвращает петлю маршрутизации в TUN)
      if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(node.address))
        {
          "ip_cidr": ["${node.address}/32"],
          "outbound": "direct"
        }
      else if (node.address.isNotEmpty)
        {
          "domain": [node.address],
          "domain_suffix": [node.address],
          "outbound": "direct"
        },
      // Прямой доступ к локальной петле
      {
        "ip_cidr": ["127.0.0.0/8", "::1/128"],
        "outbound": "direct"
      },
      // Анализ протокола (TLS SNI, HTTP Host) для точного сопоставления правил
      {
        "action": "sniff"
      },
    ];

    if (settings.routingPreset == 'russia') {
      final combinedRu = [...ruGeositeTags, ...ruGeoipTags];
      if (combinedRu.isNotEmpty) {
        routeRules.add({
          "rule_set": combinedRu,
          "outbound": "direct"
        });
      }
      routeRules.add({
        "ip_is_private": true,
        "outbound": "direct"
      });
    }

    if (settings.bypassLanEnabled) {
      routeRules.add({
        "ip_is_private": true,
        "outbound": "direct"
      });
    }

    if (settings.customRoutingRules.isNotEmpty) {
      routeRules.add({
        "domain_suffix": settings.customRoutingRules,
        "outbound": "direct"
      });
    }

    // ФИНАЛЬНОЕ ПРАВИЛО: ВЕСЬ трафик системы без ограничений направляется в туннель прокси
    routeRules.add({
      "outbound": "proxy"
    });

    final dnsServers = <Map<String, dynamic>>[];
    if (settings.secureDnsEnabled) {
      dnsServers.addAll([
        {
          "tag": "remote-dns",
          "type": "udp",
          "server": "1.1.1.1",
          "detour": "proxy"
        },
        {
          "tag": "remote-google",
          "type": "udp",
          "server": "8.8.8.8",
          "detour": "proxy"
        },
      ]);
    }
    dnsServers.add({
      "tag": "local-dns",
      "type": "udp",
      "server": "77.88.8.8"
    });

    final dnsRules = <Map<String, dynamic>>[
      // Предотвращение круговой зависимости: адрес самого прокси-сервера всегда резолвится локально
      if (!RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(node.address))
        {
          "domain": [node.address],
          "domain_suffix": [node.address],
          "server": "local-dns"
        },
      // При обходе РФ ресурсов запросы к российским доменам из геобазы резолвятся локально
      if (settings.routingPreset == 'russia' && ruGeositeTags.isNotEmpty)
        {
          "rule_set": ruGeositeTags,
          "server": "local-dns"
        },
      {
        "clash_mode": "Direct",
        "server": "local-dns"
      }
    ];

    String dnsStrategy;
    switch (settings.ipStrategy) {
      case 'ipv4':
        dnsStrategy = "ipv4_only";
        break;
      case 'ipv6':
        dnsStrategy = "prefer_ipv6";
        break;
      case 'dual':
      default:
        dnsStrategy = "prefer_ipv4";
        break;
    }

    final Map<String, dynamic> config = {
      "log": {
        "level": "info",
        "timestamp": true
      },
      "dns": {
        "servers": dnsServers,
        "rules": dnsRules,
        "final": settings.secureDnsEnabled ? "remote-dns" : "local-dns",
        "strategy": dnsStrategy
      },
      "inbounds": [
        {
          "type": "tun",
          "tag": "tun-in",
          "interface_name": "material-tun",
          "address": ["172.19.0.1/30"],
          "mtu": 1400,
          "auto_route": true,
          "strict_route": false,
          "stack": "mixed",
          "endpoint_independent_nat": true
        },
        {
          "type": "mixed",
          "tag": "mixed-in",
          "listen": "127.0.0.1",
          "listen_port": 10808
        }
      ],
      "outbounds": [
        outbound,
        {
          "type": "direct",
          "tag": "direct",
          "domain_resolver": "local-dns"
        },
        {
          "type": "block",
          "tag": "block"
        }
      ],
      "route": {
        "default_domain_resolver": "local-dns",
        if (ruleSets.isNotEmpty) "rule_set": ruleSets,
        "rules": routeRules,
        "final": "proxy",
        "auto_detect_interface": true
      }
    };

    return const JsonEncoder.withIndent('  ').convert(config);
  }

  static Map<String, dynamic> _buildOutbound(VlessNode node) {
    // 1. Hysteria 2
    if (node.protocol == ProxyProtocol.hysteria || node.protocol == ProxyProtocol.hysteria2) {
      return {
        "type": "hysteria2",
        "tag": "proxy",
        "server": node.address,
        "server_port": node.port,
        "password": node.uuid,
        "domain_resolver": "local-dns",
        "tls": {
          "enabled": true,
          "server_name": node.sni.isNotEmpty ? node.sni : node.address,
          "insecure": true
        }
      };
    }

    // 2. Shadowsocks
    if (node.protocol == ProxyProtocol.shadowsocks) {
      return {
        "type": "shadowsocks",
        "tag": "proxy",
        "server": node.address,
        "server_port": node.port,
        "method": node.encryption.isNotEmpty ? node.encryption : "aes-128-gcm",
        "password": node.uuid,
        "domain_resolver": "local-dns"
      };
    }

    // 3. Trojan
    if (node.protocol == ProxyProtocol.trojan) {
      final Map<String, dynamic> trojan = {
        "type": "trojan",
        "tag": "proxy",
        "server": node.address,
        "server_port": node.port,
        "password": node.uuid,
        "domain_resolver": "local-dns",
        "tls": {
          "enabled": true,
          "server_name": node.sni.isNotEmpty ? node.sni : node.address,
        }
      };
      if (node.streamType == "ws") {
        trojan["transport"] = {
          "type": "ws",
          "path": node.path.isNotEmpty ? node.path : "/",
          if (node.host.isNotEmpty) "headers": {"Host": node.host}
        };
      } else if (node.streamType == "grpc") {
        trojan["transport"] = {
          "type": "grpc",
          "service_name": node.serviceName.isNotEmpty ? node.serviceName : "grpc"
        };
      }
      return trojan;
    }

    // 4. VMess
    if (node.protocol == ProxyProtocol.vmess) {
      final Map<String, dynamic> vmess = {
        "type": "vmess",
        "tag": "proxy",
        "server": node.address,
        "server_port": node.port,
        "uuid": node.uuid,
        "security": "auto",
        "domain_resolver": "local-dns"
      };
      if (node.security == "tls") {
        vmess["tls"] = {
          "enabled": true,
          "server_name": node.sni.isNotEmpty ? node.sni : node.address,
        };
      }
      if (node.streamType == "ws") {
        vmess["transport"] = {
          "type": "ws",
          "path": node.path.isNotEmpty ? node.path : "/",
          if (node.host.isNotEmpty) "headers": {"Host": node.host}
        };
      } else if (node.streamType == "grpc") {
        vmess["transport"] = {
          "type": "grpc",
          "service_name": node.serviceName.isNotEmpty ? node.serviceName : "grpc"
        };
      }
      return vmess;
    }

    // 5. VLESS (Standard, Reality, Vision, gRPC, WebSocket)
    final Map<String, dynamic> vless = {
      "type": "vless",
      "tag": "proxy",
      "server": node.address,
      "server_port": node.port,
      "uuid": node.uuid,
      "packet_encoding": "xudp",
      "domain_resolver": "local-dns"
    };

    // flow (xtls-rprx-vision) применяется ТОЛЬКО для TCP с TLS или Reality. Запрещено на WS/gRPC.
    if (node.flow.isNotEmpty &&
        (node.streamType.isEmpty || node.streamType == "tcp") &&
        (node.security == "reality" || node.security == "tls")) {
      vless["flow"] = node.flow;
    }

    // TLS / Reality
    if (node.security == "reality") {
      final realityMap = <String, dynamic>{
        "enabled": true,
        "public_key": node.publicKey,
        "short_id": node.shortId,
      };
      final tlsMap = <String, dynamic>{
        "enabled": true,
        "server_name": node.sni.isNotEmpty ? node.sni : node.address,
        "utls": {
          "enabled": true,
          "fingerprint": node.fingerprint.isNotEmpty ? node.fingerprint : "chrome"
        },
        "reality": realityMap,
      };
      if (node.alpn.isNotEmpty) {
        tlsMap["alpn"] = node.alpn.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
      vless["tls"] = tlsMap;
    } else if (node.security == "tls") {
      final tlsMap = <String, dynamic>{
        "enabled": true,
        "server_name": node.sni.isNotEmpty ? node.sni : node.address,
        if (node.fingerprint.isNotEmpty)
          "utls": {
            "enabled": true,
            "fingerprint": node.fingerprint
          }
      };
      if (node.alpn.isNotEmpty) {
        tlsMap["alpn"] = node.alpn.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
      vless["tls"] = tlsMap;
    }

    // Transport (ws, grpc)
    if (node.streamType == "ws") {
      vless["transport"] = {
        "type": "ws",
        "path": node.path.isNotEmpty ? node.path : "/",
        if (node.host.isNotEmpty) "headers": {"Host": node.host}
      };
    } else if (node.streamType == "grpc") {
      vless["transport"] = {
        "type": "grpc",
        "service_name": node.serviceName.isNotEmpty ? node.serviceName : "grpc"
      };
    }

    return vless;
  }
}
