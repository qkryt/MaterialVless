import 'dart:convert';
import 'dart:io';
import '../models/vless_node.dart';
import '../models/app_settings.dart';

class ConfigGenerator {
  /// Универсальный генератор конфигурации (полный переход на Xray-core)
  static String generate(VlessNode node, AppSettings settings, {String? rulesDir}) {
    return generateXrayConfig(node, settings);
  }

  // ===========================================================================
  // 1. XRAY-CORE CONFIG GENERATOR (VLESS Reality / gRPC / XTLS Vision / VMess / Trojan)
  // ===========================================================================

  static String generateXrayConfig(VlessNode node, AppSettings settings) {
    final Map<String, dynamic> outbound = _buildXrayOutbound(node);

    final List<Map<String, dynamic>> routingRules = [
      // Прямой доступ к локальным частным сетям
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "direct"
      },
    ];

    // Маршрутизация в обход РФ ресурсов
    if (settings.routingPreset == 'russia') {
      routingRules.add({
        "type": "field",
        "ip": ["geoip:ru"],
        "outboundTag": "direct"
      });
      routingRules.add({
        "type": "field",
        "domain": [
          "geosite:category-ru",
          "domain:ru",
          "domain:su",
          "domain:xn--p1ai"
        ],
        "outboundTag": "direct"
      });
    }

    if (settings.bypassLanEnabled) {
      routingRules.add({
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "direct"
      });
    }

    if (settings.customRoutingRules.isNotEmpty) {
      routingRules.add({
        "type": "field",
        "domain": settings.customRoutingRules.map((e) => "domain:$e").toList(),
        "outboundTag": "direct"
      });
    }

    // Весь остальной трафик системы — через туннель прокси
    routingRules.add({
      "type": "field",
      "network": "tcp,udp",
      "outboundTag": "proxy"
    });

    final String queryStrategy;
    switch (settings.ipStrategy) {
      case 'ipv4':
        queryStrategy = "UseIPv4";
        break;
      case 'ipv6':
        queryStrategy = "UseIPv6";
        break;
      default:
        queryStrategy = "UseIP";
        break;
    }

    final Map<String, dynamic> config = {
      "log": {
        "loglevel": "warning"
      },
      "inbounds": [
        {
          "tag": "socks-in",
          "port": 10808,
          "listen": "127.0.0.1",
          "protocol": "socks",
          "settings": {
            "udp": true,
            "auth": "noauth"
          },
          "sniffing": {
            "enabled": true,
            "destOverride": ["http", "tls", "quic"],
            "routeOnly": false
          }
        },
        {
          "tag": "http-in",
          "port": 10809,
          "listen": "127.0.0.1",
          "protocol": "http",
          "sniffing": {
            "enabled": true,
            "destOverride": ["http", "tls", "quic"],
            "routeOnly": false
          }
        }
      ],
      "outbounds": [
        outbound,
        {
          "tag": "direct",
          "protocol": "freedom",
          "settings": {
            "domainStrategy": "UseIP"
          }
        },
        {
          "tag": "block",
          "protocol": "blackhole",
          "settings": {
            "response": {"type": "http"}
          }
        }
      ],
      "dns": {
        "servers": [
          if (settings.secureDnsEnabled) ...[
            "1.1.1.1",
            "8.8.8.8"
          ],
          "77.88.8.8",
          "localhost"
        ],
        "queryStrategy": queryStrategy
      },
      "routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": routingRules
      }
    };

    return const JsonEncoder.withIndent('  ').convert(config);
  }

  static Map<String, dynamic> _buildXrayOutbound(VlessNode node) {
    if (node.protocol == ProxyProtocol.vmess) {
      return {
        "tag": "proxy",
        "protocol": "vmess",
        "settings": {
          "vnext": [
            {
              "address": node.address,
              "port": node.port,
              "users": [
                {
                  "id": node.uuid,
                  "alterId": 0,
                  "security": node.encryption.isNotEmpty ? node.encryption : "auto"
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": node.streamType.isNotEmpty ? node.streamType : "tcp",
          "security": node.security,
          if (node.security == 'tls')
            "tlsSettings": {
              "serverName": node.sni.isNotEmpty ? node.sni : node.address,
              "allowInsecure": false
            }
        }
      };
    } else if (node.protocol == ProxyProtocol.trojan) {
      return {
        "tag": "proxy",
        "protocol": "trojan",
        "settings": {
          "servers": [
            {
              "address": node.address,
              "port": node.port,
              "password": node.uuid
            }
          ]
        },
        "streamSettings": {
          "network": node.streamType.isNotEmpty ? node.streamType : "tcp",
          "security": "tls",
          "tlsSettings": {
            "serverName": node.sni.isNotEmpty ? node.sni : node.address
          }
        }
      };
    } else if (node.protocol == ProxyProtocol.shadowsocks) {
      return {
        "tag": "proxy",
        "protocol": "shadowsocks",
        "settings": {
          "servers": [
            {
              "address": node.address,
              "port": node.port,
              "method": node.encryption.isNotEmpty ? node.encryption : "chacha20-ietf-poly1305",
              "password": node.uuid
            }
          ]
        }
      };
    }

    // Default VLESS (Reality, XTLS, gRPC, WS, xhttp, splithttp)
    final streamSettings = <String, dynamic>{
      "network": (node.streamType == 'xhttp' || node.streamType == 'splithttp')
          ? 'splithttp'
          : (node.streamType.isNotEmpty ? node.streamType : 'tcp'),
      "security": node.security.isNotEmpty ? node.security : "none",
    };

    if (node.security == 'reality') {
      streamSettings["realitySettings"] = {
        "show": false,
        "fingerprint": node.fingerprint.isNotEmpty ? node.fingerprint : "chrome",
        "serverName": node.sni.isNotEmpty ? node.sni : node.address,
        "publicKey": node.publicKey,
        "shortId": node.shortId,
        "spiderX": node.spiderX.isNotEmpty ? node.spiderX : "/"
      };
    } else if (node.security == 'tls') {
      streamSettings["tlsSettings"] = {
        "serverName": node.sni.isNotEmpty ? node.sni : node.address,
        if (node.alpn.isNotEmpty)
          "alpn": node.alpn.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        if (node.fingerprint.isNotEmpty) "fingerprint": node.fingerprint,
        "allowInsecure": false
      };
    }

    if (node.streamType == 'grpc') {
      streamSettings["grpcSettings"] = {
        "serviceName": node.serviceName.isNotEmpty ? node.serviceName : "grpc",
        "multiMode": true
      };
    } else if (node.streamType == 'ws') {
      streamSettings["wsSettings"] = {
        "path": node.path.isNotEmpty ? node.path : "/",
        "headers": {
          "Host": node.host.isNotEmpty ? node.host : (node.sni.isNotEmpty ? node.sni : node.address)
        }
      };
    } else if (node.streamType == 'xhttp' || node.streamType == 'splithttp') {
      streamSettings["splithttpSettings"] = {
        "path": node.path.isNotEmpty ? node.path : "/",
        "host": node.host.isNotEmpty ? node.host : (node.sni.isNotEmpty ? node.sni : node.address)
      };
    }

    return {
      "tag": "proxy",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": node.address,
            "port": node.port,
            "users": [
              {
                "id": node.uuid,
                "encryption": node.encryption.isNotEmpty ? node.encryption : "none",
                if (node.flow.isNotEmpty &&
                    (node.streamType.isEmpty || node.streamType == "tcp") &&
                    (node.security == "reality" || node.security == "tls"))
                  "flow": node.flow
              }
            ]
          }
        ]
      },
      "streamSettings": streamSettings
    };
  }

  // ===========================================================================
  // 2. SING-BOX CONFIG GENERATOR (TUN Adapter material-tun / Wintun / Hysteria 2)
  // ===========================================================================

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

  static String generateSingBoxConfig(VlessNode node, AppSettings settings, {String? rulesDir}) {
    final Map<String, dynamic> outbound = _buildSingBoxOutbound(node);
    final (ruleSets, ruGeositeTags, ruGeoipTags) = _buildRouteRuleSets(rulesDir);

    final List<Map<String, dynamic>> routeRules = [
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
      {
        "ip_cidr": ["77.88.8.8/32", "77.88.8.1/32"],
        "outbound": "direct"
      },
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
      {
        "ip_cidr": ["127.0.0.0/8", "::1/128"],
        "outbound": "direct"
      },
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
      if (!RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(node.address))
        {
          "domain": [node.address],
          "domain_suffix": [node.address],
          "server": "local-dns"
        },
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

  static Map<String, dynamic> _buildSingBoxOutbound(VlessNode node) {
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

    if (node.protocol == ProxyProtocol.shadowsocks) {
      return {
        "type": "shadowsocks",
        "tag": "proxy",
        "server": node.address,
        "server_port": node.port,
        "method": node.encryption.isNotEmpty ? node.encryption : "chacha20-ietf-poly1305",
        "password": node.uuid,
        "domain_resolver": "local-dns"
      };
    }

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

    // VLESS (Standard, Reality, Vision, gRPC, WebSocket)
    final Map<String, dynamic> vless = {
      "type": "vless",
      "tag": "proxy",
      "server": node.address,
      "server_port": node.port,
      "uuid": node.uuid,
      "packet_encoding": "xudp",
      "domain_resolver": "local-dns"
    };

    if (node.flow.isNotEmpty &&
        (node.streamType.isEmpty || node.streamType == "tcp") &&
        (node.security == "reality" || node.security == "tls")) {
      vless["flow"] = node.flow;
    }

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
