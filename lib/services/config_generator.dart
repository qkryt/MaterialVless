import 'dart:convert';
import '../models/vless_node.dart';
import '../models/app_settings.dart';

class ConfigGenerator {
  static String generate(VlessNode node, AppSettings settings) {
    final Map<String, dynamic> outbound = _buildOutbound(node);

    final List<Map<String, dynamic>> routingRules = [
      {
        "type": "field",
        "inboundTag": ["api"],
        "outboundTag": "api"
      },
      {
        "type": "field",
        "domain": ["geosite:category-ads-all"],
        "outboundTag": "block"
      },
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "direct"
      },
    ];

    if (settings.routingPreset == 'russia') {
      routingRules.add({
        "type": "field",
        "ip": ["geoip:ru"],
        "outboundTag": "direct"
      });
      routingRules.add({
        "type": "field",
        "domain": ["geosite:ru"],
        "outboundTag": "direct"
      });
    }

    routingRules.add({
      "type": "field",
      "network": "tcp,udp",
      "outboundTag": "proxy"
    });

    final Map<String, dynamic> config = {
      "log": {"loglevel": "warning"},
      "api": {
        "tag": "api",
        "services": ["StatsService"]
      },
      "stats": {},
      "policy": {
        "levels": {
          "0": {
            "statsUserUplink": true,
            "statsUserDownlink": true
          }
        },
        "system": {
          "statsInboundUplink": true,
          "statsInboundDownlink": true,
          "statsOutboundUplink": true,
          "statsOutboundDownlink": true
        }
      },
      "dns": {
        "hosts": {
          "geosite:category-ads-all": "127.0.0.1"
        },
        "servers": [
          if (settings.routingPreset == 'russia') ...[
            {
              "address": "77.88.8.8",
              "domains": ["geosite:ru"],
              "expectIPs": ["geoip:ru"]
            },
          ],
          {
            "address": "1.1.1.1",
            "domains": ["geosite:geolocation-!ru"],
            "expectIPs": ["geoip:!ru"]
          },
          "https://1.1.1.1/dns-query",
          "localhost"
        ],
        "queryStrategy": "UseIPv4"
      },
      "inbounds": [
        {
          "tag": "socks-in",
          "port": 10808,
          "listen": "127.0.0.1",
          "protocol": "socks",
          "settings": {"udp": true, "auth": "noauth"},
          "sniffing": {
            "enabled": true,
            "destOverride": ["http", "tls", "quic"],
            "routeOnly": true
          }
        },
        {
          "tag": "http-in",
          "port": 10809,
          "listen": "127.0.0.1",
          "protocol": "http"
        },
        {
          "tag": "tun-dokodemo",
          "port": 10853,
          "listen": "127.0.0.1",
          "protocol": "dokodemo-door",
          "settings": {"network": "tcp,udp", "followRedirect": true},
          "sniffing": {
            "enabled": true,
            "destOverride": ["http", "tls", "quic"]
          }
        }
      ],
      "outbounds": [
        outbound,
        {
          "tag": "direct",
          "protocol": "freedom",
          "settings": {"domainStrategy": "UseIP"}
        },
        {
          "tag": "block",
          "protocol": "blackhole",
          "settings": {
            "response": {"type": "http"}
          }
        }
      ],
      "routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": routingRules
      }
    };

    return const JsonEncoder.withIndent('  ').convert(config);
  }

  static Map<String, dynamic> _buildOutbound(VlessNode node) {
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
                  "security": node.encryption
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": node.streamType,
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
          "network": node.streamType,
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
              "method": node.encryption,
              "password": node.uuid
            }
          ]
        }
      };
    }

    // Default VLESS (Reality, XTLS, gRPC, WS, xhttp)
    final streamSettings = <String, dynamic>{
      "network": node.streamType == 'xhttp' ? 'splithttp' : node.streamType,
      "security": node.security,
    };

    if (node.security == 'reality') {
      streamSettings["realitySettings"] = {
        "show": false,
        "fingerprint": node.fingerprint.isNotEmpty ? node.fingerprint : "chrome",
        "serverName": node.sni,
        "publicKey": node.publicKey,
        "shortId": node.shortId,
        "spiderX": node.spiderX.isNotEmpty ? node.spiderX : "/"
      };
    } else if (node.security == 'tls') {
      streamSettings["tlsSettings"] = {
        "serverName": node.sni.isNotEmpty ? node.sni : node.address,
        if (node.alpn.isNotEmpty) "alpn": node.alpn.split(','),
        if (node.fingerprint.isNotEmpty) "fingerprint": node.fingerprint,
      };
    }

    if (node.streamType == 'grpc') {
      streamSettings["grpcSettings"] = {
        "serviceName": node.serviceName,
        "multiMode": true
      };
    } else if (node.streamType == 'ws') {
      streamSettings["wsSettings"] = {
        "path": node.path.isNotEmpty ? node.path : "/",
        "headers": {"Host": node.host.isNotEmpty ? node.host : node.sni}
      };
    } else if (node.streamType == 'xhttp' || node.streamType == 'splithttp') {
      streamSettings["splithttpSettings"] = {
        "path": node.path.isNotEmpty ? node.path : "/",
        "host": node.host.isNotEmpty ? node.host : node.sni
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
                "flow": node.flow
              }
            ]
          }
        ]
      },
      "streamSettings": streamSettings
    };
  }
}
