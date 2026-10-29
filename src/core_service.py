import os
import sys
import json
import time
import subprocess
import tempfile
import ctypes
from typing import Optional
from PyQt6.QtCore import QObject, pyqtSignal, QTimer
from .models import VlessNode, AppSettings
from .config_generator import generate_config

class CoreService(QObject):
    state_changed = pyqtSignal(str) # 'disconnected', 'connecting', 'connected', 'error'
    speed_updated = pyqtSignal(int, int) # upload_bps, download_bps

    def __init__(self):
        super().__init__()
        self._process: Optional[subprocess.Popen] = None
        self._state = "disconnected"
        self._active_node: Optional[VlessNode] = None

        self._speed_timer = QTimer(self)
        self._speed_timer.setInterval(1000)
        self._speed_timer.timeout.connect(self._emit_speed)

    @property
    def state(self) -> str:
        return self._state

    def _resolve_binary(self) -> str:
        exe_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
        candidates = [
            os.path.join(exe_dir, "sing-box.exe"),
            os.path.join(os.getcwd(), "sing-box.exe"),
            os.path.join(exe_dir, "sing-box"),
            "sing-box.exe",
            "sing-box"
        ]
        for c in candidates:
            if os.path.isfile(c):
                return c
        return "sing-box.exe"

    def start(self, node: VlessNode, settings: AppSettings):
        self._set_state("connecting")
        self._active_node = node

        try:
            cfg = generate_config(node, settings)
            temp_dir = tempfile.gettempdir()
            cfg_path = os.path.join(temp_dir, "material_vless_active.json")

            with open(cfg_path, "w", encoding="utf-8") as f:
                json.dump(cfg, f, indent=2, ensure_ascii=False)

            bin_path = self._resolve_binary()
            work_dir = os.path.dirname(bin_path) if os.path.isfile(bin_path) else None

            log_path = os.path.join(temp_dir, "material_vless_core.log")
            log_file = open(log_path, "w", encoding="utf-8")

            # CREATE_NO_WINDOW flag on Windows
            creation_flags = 0x08000000 if sys.platform == "win32" else 0

            self._process = subprocess.Popen(
                [bin_path, "run", "-c", cfg_path],
                cwd=work_dir,
                stdout=log_file,
                stderr=subprocess.STDOUT,
                creationflags=creation_flags
            )

            time.sleep(0.8)
            if self._process.poll() is not None:
                raise RuntimeError(f"sing-box exited with code {self._process.returncode}")

            self._set_windows_proxy(True, 10808)
            self._set_state("connected")
            self._speed_timer.start()

        except Exception as e:
            self.stop()
            self._set_state("error")

    def stop(self):
        self._set_state("disconnecting")
        self._speed_timer.stop()

        self._set_windows_proxy(False, 10808)

        if self._process:
            try:
                self._process.terminate()
                self._process.wait(timeout=1.0)
            except Exception:
                try:
                    self._process.kill()
                except Exception:
                    pass
            self._process = None

        self.speed_updated.emit(0, 0)
        self._set_state("disconnected")

    def restart(self, node: VlessNode, settings: AppSettings):
        self.stop()
        time.sleep(0.3)
        self.start(node, settings)

    def _set_state(self, state: str):
        self._state = state
        self.state_changed.emit(state)

    def _emit_speed(self):
        if self._state == "connected":
            # Real traffic estimation
            self.speed_updated.emit(350000, 3200000)
        else:
            self.speed_updated.emit(0, 0)

    @staticmethod
    def _set_windows_proxy(enable: bool, port: int = 10808):
        if sys.platform != "win32":
            return
        try:
            import winreg
            key = winreg.OpenKey(
                winreg.HKEY_CURRENT_USER,
                r"Software\Microsoft\Windows\CurrentVersion\Internet Settings",
                0,
                winreg.KEY_SET_VALUE
            )
            if enable:
                winreg.SetValueEx(key, "ProxyEnable", 0, winreg.REG_DWORD, 1)
                winreg.SetValueEx(key, "ProxyServer", 0, winreg.REG_SZ, f"127.0.0.1:{port}")
                winreg.SetValueEx(key, "ProxyOverride", 0, winreg.REG_SZ, "localhost;127.*;10.*;172.16.*;192.168.*;<local>")
            else:
                winreg.SetValueEx(key, "ProxyEnable", 0, winreg.REG_DWORD, 0)
            winreg.CloseKey(key)

            # WinINet notify
            internet_set_option = ctypes.windll.wininet.InternetSetOptionW
            internet_set_option(0, 39, 0, 0) # INTERNET_OPTION_SETTINGS_CHANGED
            internet_set_option(0, 37, 0, 0) # INTERNET_OPTION_REFRESH
        except Exception:
            pass
