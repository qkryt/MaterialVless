import 'dart:convert';

import '../models/vless_node.dart';

import '../models/app_settings.dart';



class ConfigGenerator {

  static const List<String> _russianDomains = [

    ".ru",

    ".xn--p1ai",

    ".su",

    ".by",

    "vk.com",

    "vk.me",

    "userapi.com",

    "yandex.ru",

    "yandex.net",

    "yandex.com",

    "ya.ru",

    "dzen.ru",

    "mail.ru",

    "ok.ru",

    "sberbank.ru",

    "sber.ru",

    "tinkoff.ru",

    "tbank.ru",

    "t-bank.ru",

    "gosuslugi.ru",

    "avito.ru",

    "ozon.ru",

    "wildberries.ru",

    "wb.ru",

    "kinopoisk.ru",

    "rutube.ru",

    "2gis.ru",

    "mos.ru",

    "hh.ru",

    "mts.ru",

    "megafon.ru",

    "beeline.ru",

    "tele2.ru",

    "auto.ru"

  ];



  static const List<String> _telegramDomains = [

    "telegram.org",

    "t.me",

    "telegra.ph",

    "tdesktop.com",

    "telesco.pe",

    "tx.me",

    "stel.com"

  ];



  static const List<String> _telegramIps = [

    "91.108.4.0/22",

    "91.108.8.0/22",

    "91.108.12.0/22",

    "91.108.16.0/22",

    "91.108.20.0/22",

    "91.108.56.0/22",

    "149.154.160.0/20"

  ];



  static String generate(VlessNode node, AppSettings settings) {

    final Map<String, dynamic> outbound = _buildOutbound(node);



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

      // Telegram: прямое направление в туннель без задержек сниффинга (MTProto не является TLS)

      {

        "ip_cidr": _telegramIps,

        "outbound": "proxy"

      },

      {

        "domain_suffix": _telegramDomains,

        "outbound": "proxy"

      },

      {

        "action": "sniff",

        "timeout": "500ms"

      },

    ];



    if (settings.routingPreset == 'russia') {

      routeRules.add({

        "domain_suffix": _russianDomains,

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



    final dnsServers = <Map<String, dynamic>>[];

    if (settings.secureDnsEnabled) {

      dnsServers.addAll([

        {

          "tag": "remote-dns",

          "type": "https",

          "server": "1.1.1.1",

          "path": "/dns-query",

          "detour": "proxy"

        },

        {

          "tag": "remote-google",

          "type": "https",

          "server": "8.8.8.8",

          "path": "/dns-query",

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

          "server": "local-dns"

        },

      if (settings.routingPreset == 'russia')

        {

          "domain_suffix": _russianDomains,

          "server": "local-dns"

        },

      if (settings.secureDnsEnabled)

        {

          "domain_suffix": _telegramDomains,

          "server": "remote-dns"

        },

      if (settings.customRoutingRules.isNotEmpty)

        {

          "domain_suffix": settings.customRoutingRules,

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

      case 'auto':

      default:

        dnsStrategy = "prefer_ipv4";

        break;

    }



    final Map<String, dynamic> config = {

      "log": {

        "level": "warn"

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



    if (node.flow.isNotEmpty) {

      vless["flow"] = node.flow;

    }



    // TLS / Reality

    if (node.security == "reality") {

      final realityMap = <String, dynamic>{

        "enabled": true,

        "public_key": node.publicKey,

        "short_id": node.shortId,

      };

      if (node.spiderX.isNotEmpty) {

        realityMap["spider_x"] = node.spiderX;

      }

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

