import json
import re
from .models import VlessNode, AppSettings

RUSSIAN_DOMAINS = [
    ".ru", ".xn--p1ai", ".su", ".by",
    "vk.com", "vk.me", "userapi.com",
    "yandex.ru", "yandex.net", "yandex.com", "ya.ru", "dzen.ru",
    "mail.ru", "ok.ru", "sberbank.ru", "sber.ru",
    "tinkoff.ru", "tbank.ru", "t-bank.ru", "gosuslugi.ru",
    "avito.ru", "ozon.ru", "wildberries.ru", "wb.ru",
    "kinopoisk.ru", "rutube.ru", "2gis.ru", "mos.ru",
    "hh.ru", "mts.ru", "megafon.ru", "beeline.ru", "tele2.ru", "auto.ru"
]

TELEGRAM_DOMAINS = [
    "telegram.org", "t.me", "telegra.ph", "tdesktop.com",
    "telesco.pe", "tx.me", "stel.com"
]

TELEGRAM_IPS = [
    "91.108.4.0/22", "91.108.8.0/22", "91.108.12.0/22",
    "91.108.16.0/22", "91.108.20.0/22", "91.108.56.0/22",
    "149.154.160.0/20"
]

def generate_config(node: VlessNode, settings: AppSettings) -> dict:
    outbound = _build_outbound(node)

    route_rules = [
        {"inbound": ["tun-in"], "port": 53, "action": "hijack-dns"},
        {"inbound": ["tun-in"], "protocol": "dns", "action": "hijack-dns"},
        {"ip_cidr": ["77.88.8.8/32", "77.88.8.1/32"], "outbound": "direct"},
        {"ip_cidr": TELEGRAM_IPS, "outbound": "proxy"},
        {"domain_suffix": TELEGRAM_DOMAINS, "outbound": "proxy"},
        {"action": "sniff", "timeout": "300ms"}
    ]

    if settings.routing_preset == "russia":
        route_rules.append({
            "domain_suffix": RUSSIAN_DOMAINS,
            "outbound": "direct"
        })

    if settings.bypass_lan_enabled:
        route_rules.append({
            "ip_is_private": True,
            "outbound": "direct"
        })

    dns_servers = []
    if settings.secure_dns_enabled:
        dns_servers.extend([
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
            }
        ])

    dns_servers.append({
        "tag": "local-dns",
        "type": "udp",
        "server": "77.88.8.8"
    })

    dns_rules = []
    # Prevent circular dependency: proxy host itself is resolved locally
    if not re.match(r'^\d+\.\d+\.\d+\.\d+$', node.address):
        dns_rules.append({
            "domain": [node.address],
            "server": "local-dns"
        })

    if settings.routing_preset == "russia":
        dns_rules.append({
            "domain_suffix": RUSSIAN_DOMAINS,
            "server": "local-dns"
        })

    if settings.secure_dns_enabled:
        dns_rules.append({
            "domain_suffix": TELEGRAM_DOMAINS,
            "server": "remote-dns"
        })

    config = {
        "log": {"level": "warn"},
        "dns": {
            "servers": dns_servers,
            "rules": dns_rules,
            "final": "remote-dns" if settings.secure_dns_enabled else "local-dns",
            "strategy": "ipv4_only"
        },
        "inbounds": [
            {
                "type": "tun",
                "tag": "tun-in",
                "interface_name": "material-tun",
                "address": ["172.19.0.1/30"],
                "mtu": 1400,
                "auto_route": True,
                "strict_route": False,
                "stack": "system",
                "endpoint_independent_nat": True
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
            {"type": "direct", "tag": "direct"},
            {"type": "block", "tag": "block"}
        ],
        "route": {
            "default_domain_resolver": "local-dns",
            "rules": route_rules,
            "auto_detect_interface": True
        }
    }
    return config

def _build_outbound(node: VlessNode) -> dict:
    proto = node.protocol.lower()

    if proto in ("hysteria", "hysteria2", "hy2"):
        return {
            "type": "hysteria2",
            "tag": "proxy",
            "server": node.address,
            "server_port": node.port,
            "password": node.uuid,
            "domain_resolver": "local-dns",
            "tls": {
                "enabled": True,
                "server_name": node.sni if node.sni else node.address,
                "insecure": True
            }
        }

    if proto == "shadowsocks":
        return {
            "type": "shadowsocks",
            "tag": "proxy",
            "server": node.address,
            "server_port": node.port,
            "method": node.encryption if node.encryption else "aes-128-gcm",
            "password": node.uuid,
            "domain_resolver": "local-dns"
        }

    if proto == "trojan":
        out = {
            "type": "trojan",
            "tag": "proxy",
            "server": node.address,
            "server_port": node.port,
            "password": node.uuid,
            "domain_resolver": "local-dns",
            "tls": {
                "enabled": True,
                "server_name": node.sni if node.sni else node.address
            }
        }
        if node.stream_type == "ws":
            out["transport"] = {
                "type": "ws",
                "path": node.path if node.path else "/",
                "headers": {"Host": node.host} if node.host else {}
            }
        elif node.stream_type == "grpc":
            out["transport"] = {
                "type": "grpc",
                "service_name": node.service_name if node.service_name else "grpc"
            }
        return out

    # Default VLESS
    vless = {
        "type": "vless",
        "tag": "proxy",
        "server": node.address,
        "server_port": node.port,
        "uuid": node.uuid,
        "packet_encoding": "xudp",
        "domain_resolver": "local-dns"
    }

    if node.flow:
        vless["flow"] = node.flow

    if node.security == "reality":
        vless["tls"] = {
            "enabled": True,
            "server_name": node.sni if node.sni else node.address,
            "utls": {
                "enabled": True,
                "fingerprint": node.fingerprint if node.fingerprint else "chrome"
            },
            "reality": {
                "enabled": True,
                "public_key": node.public_key,
                "short_id": node.short_id
            }
        }
    elif node.security == "tls":
        vless["tls"] = {
            "enabled": True,
            "server_name": node.sni if node.sni else node.address,
            "utls": {
                "enabled": True,
                "fingerprint": node.fingerprint if node.fingerprint else "chrome"
            } if node.fingerprint else {"enabled": False}
        }

    if node.stream_type == "ws":
        vless["transport"] = {
            "type": "ws",
            "path": node.path if node.path else "/",
            "headers": {"Host": node.host} if node.host else {}
        }
    elif node.stream_type == "grpc":
        vless["transport"] = {
            "type": "grpc",
            "service_name": node.service_name if node.service_name else "grpc"
        }

    return vless
