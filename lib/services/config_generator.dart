import 'dart:convert';
import '../models/vless_node.dart';

class ConfigGenerator {
  static String generate(VlessNode node) {
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
          {
            "address": "1.1.1.1",
            "domains": ["geosite:geolocation-!ru"],
            "expectIPs": ["geoip:!ru"]
          },
          {
            "address": "77.88.8.8",
            "domains": ["geosite:ru"],
            "expectIPs": ["geoip:ru"]
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
        {
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
                    "encryption": node.encryption,
                    "flow": node.flow
                  }
                ]
              }
            ]
          },
          "streamSettings": {
            "network": node.streamType,
            "security": node.security,
            if (node.security == 'reality')
              "realitySettings": {
                "show": false,
                "fingerprint": node.fingerprint,
                "serverName": node.sni,
                "publicKey": node.publicKey,
                "shortId": node.shortId,
                "spiderX": node.spiderX
              },
            if (node.streamType == 'grpc')
              "grpcSettings": {
                "serviceName": node.serviceName,
                "multiMode": true
              },
            if (node.streamType == 'ws')
              "wsSettings": {
                "path": node.path,
                "headers": {"Host": node.sni}
              }
          }
        },
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
        "rules": [
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
            "ip": ["geoip:private", "geoip:ru"],
            "outboundTag": "direct"
          },
          {
            "type": "field",
            "domain": ["geosite:ru"],
            "outboundTag": "direct"
          },
          {
            "type": "field",
            "network": "tcp,udp",
            "outboundTag": "proxy"
          }
        ]
      }
    };

    return const JsonEncoder.withIndent('  ').convert(config);
  }
}