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
}
