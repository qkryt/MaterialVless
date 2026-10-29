import base64
import urllib.parse
import re
import socket
import time
import requests
from typing import List, Tuple, Dict, Any, Optional
from .models import VlessNode, AppSettings

class SubscriptionService:
    @staticmethod
    def get_hwid() -> str:
        try:
            import subprocess
            out = subprocess.check_output("wmic csproduct get uuid", shell=True).decode()
            lines = [l.strip() for l in out.splitlines() if l.strip()]
            if len(lines) >= 2:
                return lines[1]
        except Exception:
            pass
        return "MV-WIN-DEFAULT-HWID"

    @classmethod
    def load_subscription(cls, source: str, settings: AppSettings, custom_name: Optional[str] = None) -> Tuple[List[VlessNode], Dict[str, Any]]:
        meta = {"upload": 0, "download": 0, "total": 0, "expire": None}
        content = ""

        if source.startswith("http://") or source.startswith("https://"):
            headers = {
                "User-Agent": settings.user_agent if settings.user_agent else "v2rayN/6.42"
            }
            if settings.send_hwid:
                headers["X-HWID"] = cls.get_hwid()
                headers["HWID"] = cls.get_hwid()

            resp = requests.get(source, headers=headers, timeout=10)
            content = resp.text

            # Parse Subscription-Userinfo header
            user_info = resp.headers.get("Subscription-Userinfo") or resp.headers.get("subscription-userinfo")
            if user_info:
                for part in user_info.split(";"):
                    if "=" in part:
                        k, v = part.strip().split("=", 1)
                        if k == "upload": meta["upload"] = int(v) if v.isdigit() else 0
                        elif k == "download": meta["download"] = int(v) if v.isdigit() else 0
                        elif k == "total": meta["total"] = int(v) if v.isdigit() else 0
                        elif k == "expire": meta["expire"] = int(v) if v.isdigit() else None
        else:
            content = source

        # Check if base64 encoded
        cleaned = re.sub(r'\s+', '', content)
        try:
            missing_padding = len(cleaned) % 4
            if missing_padding:
                cleaned += '=' * (4 - missing_padding)
            decoded = base64.b64decode(cleaned).decode('utf-8', errors='ignore')
            if "vless://" in decoded or "hysteria2://" in decoded or "hy2://" in decoded or "vmess://" in decoded:
                content = decoded
        except Exception:
            pass

        nodes = []
        for line in content.splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            node = cls.parse_uri(line)
            if node:
                nodes.append(node)

        return nodes, meta

    @staticmethod
    def parse_uri(uri: str) -> Optional[VlessNode]:
        try:
            if uri.startswith("vless://"):
                parsed = urllib.parse.urlparse(uri)
                uuid = parsed.username or ""
                addr = parsed.hostname or ""
                port = parsed.port or 443
                params = urllib.parse.parse_qs(parsed.query)

                remark = urllib.parse.unquote(parsed.fragment) if parsed.fragment else f"{addr}:{port}"

                return VlessNode(
                    id=f"{addr}_{port}_{uuid[:8]}",
                    protocol="vless",
                    address=addr,
                    port=port,
                    uuid=uuid,
                    flow=params.get("flow", [""])[0],
                    encryption=params.get("encryption", ["none"])[0],
                    stream_type=params.get("type", ["tcp"])[0],
                    security=params.get("security", ["none"])[0],
                    sni=params.get("sni", [""])[0],
                    fingerprint=params.get("fp", ["chrome"])[0],
                    alpn=params.get("alpn", [""])[0],
                    host=params.get("host", [""])[0],
                    public_key=params.get("pbk", [""])[0],
                    short_id=params.get("sid", [""])[0],
                    service_name=params.get("serviceName", [""])[0],
                    path=params.get("path", [""])[0],
                    remark=remark
                )

            elif uri.startswith("hysteria2://") or uri.startswith("hy2://"):
                clean = uri.replace("hysteria2://", "http://").replace("hy2://", "http://")
                parsed = urllib.parse.urlparse(clean)
                auth = parsed.username or ""
                addr = parsed.hostname or ""
                port = parsed.port or 443
                params = urllib.parse.parse_qs(parsed.query)
                remark = urllib.parse.unquote(parsed.fragment) if parsed.fragment else f"Hysteria2 - {addr}:{port}"

                return VlessNode(
                    id=f"{addr}_{port}_{auth[:8]}",
                    protocol="hysteria2",
                    address=addr,
                    port=port,
                    uuid=auth,
                    sni=params.get("sni", [""])[0],
                    remark=remark
                )

            elif uri.startswith("trojan://"):
                parsed = urllib.parse.urlparse(uri)
                password = parsed.username or ""
                addr = parsed.hostname or ""
                port = parsed.port or 443
                params = urllib.parse.parse_qs(parsed.query)
                remark = urllib.parse.unquote(parsed.fragment) if parsed.fragment else f"Trojan - {addr}:{port}"

                return VlessNode(
                    id=f"{addr}_{port}_{password[:8]}",
                    protocol="trojan",
                    address=addr,
                    port=port,
                    uuid=password,
                    sni=params.get("sni", [""])[0],
                    stream_type=params.get("type", ["tcp"])[0],
                    remark=remark
                )
        except Exception:
            pass
        return None

    @staticmethod
    def ping_node(node: VlessNode, timeout_ms: int = 2000) -> Optional[int]:
        timeout_sec = max(0.5, timeout_ms / 1000.0)
        try:
            start = time.perf_counter()
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(timeout_sec)
            sock.connect((node.address, node.port))
            sock.close()
            elapsed_ms = int((time.perf_counter() - start) * 1000)
            return max(1, elapsed_ms)
        except Exception:
            return None
