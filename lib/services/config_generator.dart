import 'dart:convert';
import '../models/vless_node.dart';
import '../models/app_settings.dart';

class ConfigGenerator {
  static String generate(VlessNode node, AppSettings settings) {
    final Map<String, dynamic> outbound = _buildOutbound(node);

    final List<Map<String, dynamic>> routeRules = [
      {
        "action": "sniff"
      },
      {
        "protocol": "dns",
        "action": "hijack-dns"
      },
    ];

    if (settings.routingPreset == 'russia') {
      routeRules.add({
        "domain_suffix": [".ru", ".рф", ".su", ".by"],
        "outbound": "direct"
      });
    }

    routeRules.add({
      "ip_is_private": true,
      "outbound": "direct"
    });

    final Map<String, dynamic> config = {
      "log": {
        "level": "warn"
      },
      "dns": {
        "servers": [
          {
            "tag": "remote-dns",
            "type": "udp",
            "server": "1.1.1.1",
            "detour": "proxy"
          },
          {
            "tag": "local-dns",
            "type": "local",
            "detour": "direct"
          }
        ],
        "rules": [
          if (settings.routingPreset == 'russia')
            {
              "domain_suffix": [".ru", ".рф", ".su", ".by"],
              "server": "local-dns"
            }
        ],
        "strategy": "ipv4_only"
      },
      "inbounds": [
        {
          "type": "tun",
          "tag": "tun-in",
          "interface_name": "material-tun",
          "address": ["172.19.0.1/30"],
          "auto_route": true,
          "strict_route": true,
          "stack": "mixed"
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
          "tag": "direct"
        },
        {
          "type": "block",
          "tag": "block"
        }
      ],
      "route": {
        "default_domain_resolver": "local-dns",
        "rules": routeRules,
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
        "tls": {
          "enabled": true,
          "server_name": node.sni.isNotEmpty ? node.sni : node.address,
          "insecure": true
        }
      };
    }

    // 2. VMess
    if (node.protocol == ProxyProtocol.vmess) {
      return {
        "type": "vmess",
        "tag": "proxy",
        "server": node.address,
        "server_port": node.port,
        "uuid": node.uuid,
        "security": "auto"
      };
    }

    // 3. Trojan
    if (node.protocol == ProxyProtocol.trojan) {
      return {
        "type": "trojan",
        "tag": "proxy",
        "server": node.address,
        "server_port": node.port,
        "password": node.uuid,
        "tls": {
          "enabled": true,
          "server_name": node.sni.isNotEmpty ? node.sni : node.address
        }
      };
    }

    // 4. Shadowsocks
    if (node.protocol == ProxyProtocol.shadowsocks) {
      return {
        "type": "shadowsocks",
        "tag": "proxy",
        "server": node.address,
        "server_port": node.port,
        "method": node.encryption,
        "password": node.uuid
      };
    }

    // 5. VLESS (Reality, XTLS, gRPC, WebSocket, TCP)
    final Map<String, dynamic> tls = {
      "enabled": node.security == 'reality' || node.security == 'tls',
      "server_name": node.sni.isNotEmpty ? node.sni : node.address,
    };

    if (node.security == 'reality') {
      tls["utls"] = {
        "enabled": true,
        "fingerprint": node.fingerprint.isNotEmpty ? node.fingerprint : "chrome"
      };
      tls["reality"] = {
        "enabled": true,
        "public_key": node.publicKey,
        "short_id": node.shortId
      };
    }

    if (node.security == 'tls' && node.alpn.isNotEmpty) {
      tls["alpn"] = node.alpn.split(',');
    }

    final Map<String, dynamic> outbound = {
      "type": "vless",
      "tag": "proxy",
      "server": node.address,
      "server_port": node.port,
      "uuid": node.uuid,
      if (node.flow.isNotEmpty) "flow": node.flow,
      "tls": tls,
    };

    if (node.streamType == 'grpc') {
      outbound["transport"] = {
        "type": "grpc",
        "service_name": node.serviceName
      };
    } else if (node.streamType == 'ws') {
      outbound["transport"] = {
        "type": "ws",
        "path": node.path.isNotEmpty ? node.path : "/",
        if (node.host.isNotEmpty) "headers": {"Host": node.host}
      };
    }

    return outbound;
  }
}
