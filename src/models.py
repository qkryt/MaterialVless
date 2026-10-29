import json
from dataclasses import dataclass, field, asdict
from typing import List, Optional
from datetime import datetime

@dataclass
class VlessNode:
    id: str
    protocol: str = "vless"
    address: str = ""
    port: int = 443
    uuid: str = ""
    flow: str = ""
    encryption: str = "none"
    stream_type: str = "tcp" # tcp, ws, grpc
    security: str = "reality" # none, tls, reality
    sni: str = ""
    fingerprint: str = "chrome"
    alpn: str = ""
    host: str = ""
    public_key: str = ""
    short_id: str = ""
    service_name: str = ""
    path: str = ""
    remark: str = ""
    subscription_id: str = ""
    ping_ms: Optional[int] = None

    def to_dict(self):
        return {
            "id": self.id,
            "protocol": self.protocol,
            "address": self.address,
            "port": self.port,
            "uuid": self.uuid,
            "flow": self.flow,
            "encryption": self.encryption,
            "streamType": self.stream_type,
            "security": self.security,
            "sni": self.sni,
            "fingerprint": self.fingerprint,
            "alpn": self.alpn,
            "host": self.host,
            "publicKey": self.public_key,
            "shortId": self.short_id,
            "serviceName": self.service_name,
            "path": self.path,
            "remark": self.remark,
            "subscriptionId": self.subscription_id,
            "pingMs": self.ping_ms
        }

    @classmethod
    def from_dict(cls, d: dict):
        return cls(
            id=d.get("id", ""),
            protocol=d.get("protocol", "vless"),
            address=d.get("address", ""),
            port=int(d.get("port", 443)),
            uuid=d.get("uuid", ""),
            flow=d.get("flow", ""),
            encryption=d.get("encryption", "none"),
            stream_type=d.get("streamType", "tcp"),
            security=d.get("security", "reality"),
            sni=d.get("sni", ""),
            fingerprint=d.get("fingerprint", "chrome"),
            alpn=d.get("alpn", ""),
            host=d.get("host", ""),
            public_key=d.get("publicKey", ""),
            short_id=d.get("shortId", ""),
            service_name=d.get("serviceName", ""),
            path=d.get("path", ""),
            remark=d.get("remark", ""),
            subscription_id=d.get("subscriptionId", ""),
            ping_ms=d.get("pingMs")
        )

@dataclass
class SubscriptionModel:
    id: str
    name: str
    url: str
    last_updated: datetime = field(default_factory=datetime.now)
    upload_bytes: int = 0
    download_bytes: int = 0
    total_bytes: int = 0
    expire_date: Optional[datetime] = None
    auto_update: bool = True
    auto_update_interval_hours: int = 2
    is_expanded: bool = True
    is_pinned: bool = False
    nodes: List[VlessNode] = field(default_factory=list)

    @property
    def used_bytes(self) -> int:
        return self.upload_bytes + self.download_bytes

    @property
    def used_percentage(self) -> float:
        if self.total_bytes > 0:
            return min(1.0, max(0.0, self.used_bytes / self.total_bytes))
        return 0.0

    @staticmethod
    def format_bytes(b: int) -> str:
        if b <= 0:
            return "0 B"
        suffixes = ["B", "KB", "MB", "GB", "TB"]
        i = 0
        val = float(b)
        while val >= 1024.0 and i < len(suffixes) - 1:
            val /= 1024.0
            i += 1
        return f"{val:.1f} {suffixes[i]}"

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "url": self.url,
            "lastUpdated": self.last_updated.isoformat(),
            "uploadBytes": self.upload_bytes,
            "downloadBytes": self.download_bytes,
            "totalBytes": self.total_bytes,
            "expireDate": self.expire_date.isoformat() if self.expire_date else None,
            "autoUpdate": self.auto_update,
            "autoUpdateIntervalHours": self.auto_update_interval_hours,
            "isExpanded": self.is_expanded,
            "isPinned": self.is_pinned,
            "nodes": [n.to_dict() for n in self.nodes]
        }

    @classmethod
    def from_dict(cls, d: dict):
        lu = datetime.fromisoformat(d["lastUpdated"]) if "lastUpdated" in d and d["lastUpdated"] else datetime.now()
        ed = datetime.fromisoformat(d["expireDate"]) if d.get("expireDate") else None
        nodes = [VlessNode.from_dict(n) for n in d.get("nodes", [])]
        return cls(
            id=str(d.get("id", "")),
            name=d.get("name", "Подписка"),
            url=d.get("url", ""),
            last_updated=lu,
            upload_bytes=d.get("uploadBytes", 0),
            download_bytes=d.get("downloadBytes", 0),
            total_bytes=d.get("totalBytes", 0),
            expire_date=ed,
            auto_update=d.get("autoUpdate", True),
            auto_update_interval_hours=d.get("autoUpdateIntervalHours", 2),
            is_expanded=d.get("isExpanded", True),
            is_pinned=d.get("isPinned", False),
            nodes=nodes
        )

@dataclass
class AppSettings:
    routing_preset: str = "russia" # 'russia' or 'none'
    secure_dns_enabled: bool = True
    bypass_lan_enabled: bool = True
    ping_url: str = "http://cp.cloudflare.com/"
    ping_timeout_ms: int = 2000 # 1000 to 5000 ms
    speedtest_url: str = "http://cachefly.cachefly.net/1mb.test"
    auto_update_rules_on_start: bool = True
    user_agent: str = "v2rayN/6.42"
    send_hwid: bool = True
    theme_mode: str = "dark" # 'dark', 'light', 'amoled'
    font_family: str = "Segoe UI"
    custom_font_path: Optional[str] = None

    def to_dict(self):
        return {
            "routingPreset": self.routing_preset,
            "secureDnsEnabled": self.secure_dns_enabled,
            "bypassLanEnabled": self.bypass_lan_enabled,
            "pingUrl": self.ping_url,
            "pingTimeoutMs": self.ping_timeout_ms,
            "speedtestUrl": self.speedtest_url,
            "autoUpdateRulesOnStart": self.auto_update_rules_on_start,
            "userAgent": self.user_agent,
            "sendHwid": self.send_hwid,
            "themeMode": self.theme_mode,
            "fontFamily": self.font_family,
            "customFontPath": self.custom_font_path
        }

    @classmethod
    def from_dict(cls, d: dict):
        return cls(
            routing_preset=d.get("routingPreset", "russia"),
            secure_dns_enabled=d.get("secureDnsEnabled", True),
            bypass_lan_enabled=d.get("bypassLanEnabled", True),
            ping_url=d.get("pingUrl", "http://cp.cloudflare.com/"),
            ping_timeout_ms=int(d.get("pingTimeoutMs", 2000)),
            speedtest_url=d.get("speedtestUrl", "http://cachefly.cachefly.net/1mb.test"),
            auto_update_rules_on_start=d.get("autoUpdateRulesOnStart", True),
            user_agent=d.get("userAgent", "v2rayN/6.42"),
            send_hwid=d.get("sendHwid", True),
            theme_mode=d.get("themeMode", "dark"),
            font_family=d.get("fontFamily", "Segoe UI"),
            custom_font_path=d.get("customFontPath")
        )
