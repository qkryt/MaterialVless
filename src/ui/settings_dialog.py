import os
import shutil
from PyQt6.QtWidgets import (
    QDialog, QVBoxLayout, QHBoxLayout, QLabel, QLineEdit,
    QPushButton, QCheckBox, QComboBox, QSlider, QFrame,
    QFileDialog, QMessageBox, QScrollArea, QWidget
)
from PyQt6.QtGui import QFontDatabase, QFont
from PyQt6.QtCore import Qt
from ..models import AppSettings
from ..subscription_service import SubscriptionService

POPULAR_USER_AGENTS = [
    "v2rayN/6.42",
    "v2rayN/6.23",
    "sing-box/1.14.4",
    "sing-box/1.11.0",
    "ClashMeta/v1.18.0",
    "Clash.Meta",
    "Shadowrocket/1982",
    "QuantumultX/1.0.30",
    "Surge/5.0.0",
    "FlClash/0.8.0",
    "NekoRay/3.26",
    "MaterialVless",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/130.0.0.0",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:132.0) Firefox/132.0",
]

class SettingsDialog(QDialog):
    def __init__(self, parent, settings: AppSettings):
        super().__init__(parent)
        self.settings = settings
        self.setWindowTitle("Настройки клиента (Qt6 Edition)")
        self.resize(540, 580)

        main_layout = QVBoxLayout(self)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.Shape.NoFrame)
        content_widget = QWidget()
        layout = QVBoxLayout(content_widget)
        layout.setSpacing(16)

        # 1. Routing & Traffic
        layout.addWidget(self._make_header("Маршрутизация (Трафик)"))
        route_card = QFrame()
        route_card.setProperty("card", "true")
        route_layout = QVBoxLayout(route_card)

        r_row = QHBoxLayout()
        r_row.addWidget(QLabel("Режим туннелирования:"))
        self.preset_combo = QComboBox()
        self.preset_combo.addItem("🇷🇺 Обход сайтов РФ (Россия напрямую)", "russia")
        self.preset_combo.addItem("🌐 Глобальный (Все в VPN)", "none")
        if self.settings.routing_preset == "none":
            self.preset_combo.setCurrentIndex(1)
        r_row.addWidget(self.preset_combo)
        route_layout.addLayout(r_row)

        # Requirement 2: Active toggle for Secure DNS
        self.secure_dns_chk = QCheckBox("Защищенный DNS (DoH)")
        self.secure_dns_chk.setChecked(self.settings.secure_dns_enabled)
        self.secure_dns_chk.setToolTip("Шифрованные DNS запросы Cloudflare (1.1.1.1) и Google (8.8.8.8) внутри туннеля")
        route_layout.addWidget(self.secure_dns_chk)

        # Requirement 2: Active toggle for Bypass LAN
        self.bypass_lan_chk = QCheckBox("Обход локальной сети (LAN)")
        self.bypass_lan_chk.setChecked(self.settings.bypass_lan_enabled)
        self.bypass_lan_chk.setToolTip("Прямой доступ к локальным IP (192.168.*, 10.*, 172.16.*)")
        route_layout.addWidget(self.bypass_lan_chk)

        layout.addWidget(route_card)

        # 2. Ping & Latency (Requirement 3: 1 to 5 seconds)
        layout.addWidget(self._make_header("Пинг и Задержка"))
        ping_card = QFrame()
        ping_card.setProperty("card", "true")
        ping_layout = QVBoxLayout(ping_card)

        p_row = QHBoxLayout()
        p_row.addWidget(QLabel("URL для замера пинга:"))
        self.ping_url_edit = QLineEdit(self.settings.ping_url)
        p_row.addWidget(self.ping_url_edit)
        ping_layout.addLayout(p_row)

        # Slider 1 to 5 sec
        slider_row = QHBoxLayout()
        slider_row.addWidget(QLabel("Таймаут пинга:"))
        curr_sec = max(1, min(5, round(self.settings.ping_timeout_ms / 1000)))
        self.timeout_val_lbl = QLabel(f"{curr_sec} сек.")
        self.timeout_val_lbl.setStyleSheet("color: #3574F0; font-weight: bold;")
        slider_row.addWidget(self.timeout_val_lbl)
        slider_row.addStretch()
        ping_layout.addLayout(slider_row)

        self.timeout_slider = QSlider(Qt.Orientation.Horizontal)
        self.timeout_slider.setRange(1, 5)
        self.timeout_slider.setValue(curr_sec)
        self.timeout_slider.valueChanged.connect(lambda v: self.timeout_val_lbl.setText(f"{v} сек."))
        ping_layout.addWidget(self.timeout_slider)

        layout.addWidget(ping_card)

        # 3. Theme & Custom Fonts (Requirement 4)
        layout.addWidget(self._make_header("Тема и Пользовательский Шрифт"))
        font_card = QFrame()
        font_card.setProperty("card", "true")
        font_layout = QVBoxLayout(font_card)

        font_row = QHBoxLayout()
        font_row.addWidget(QLabel("Текущий шрифт:"))
        self.font_lbl = QLabel(self.settings.font_family)
        self.font_lbl.setStyleSheet("font-weight: bold; color: #3574F0;")
        font_row.addWidget(self.font_lbl)
        font_row.addStretch()

        import_font_btn = QPushButton("Импорт (.ttf, .otf)")
        import_font_btn.clicked.connect(self._import_font)
        font_row.addWidget(import_font_btn)

        reset_font_btn = QPushButton("Сброс")
        reset_font_btn.clicked.connect(self._reset_font)
        font_row.addWidget(reset_font_btn)
        font_layout.addLayout(font_row)

        theme_row = QHBoxLayout()
        theme_row.addWidget(QLabel("Режим темы:"))
        self.theme_combo = QComboBox()
        self.theme_combo.addItem("Qt6 Fusion Dark", "dark")
        self.theme_combo.addItem("Qt6 Fusion Light", "light")
        self.theme_combo.addItem("AMOLED Black", "amoled")
        t_idx = self.theme_combo.findData(self.settings.theme_mode)
        if t_idx >= 0:
            self.theme_combo.setCurrentIndex(t_idx)
        theme_row.addWidget(self.theme_combo)
        font_layout.addLayout(theme_row)

        layout.addWidget(font_card)

        # 4. User-Agent & HWID (Requirement 5)
        layout.addWidget(self._make_header("Подписка и User-Agent"))
        ua_card = QFrame()
        ua_card.setProperty("card", "true")
        ua_layout = QVBoxLayout(ua_card)

        ua_row = QHBoxLayout()
        ua_row.addWidget(QLabel("User-Agent:"))
        self.ua_combo = QComboBox()
        self.ua_combo.setEditable(True)
        for ua in POPULAR_USER_AGENTS:
            self.ua_combo.addItem(ua)
        self.ua_combo.setCurrentText(self.settings.user_agent)
        ua_row.addWidget(self.ua_combo)
        ua_layout.addLayout(ua_row)

        self.send_hwid_chk = QCheckBox("Отправлять аппаратный ID (HWID)")
        self.send_hwid_chk.setChecked(self.settings.send_hwid)
        ua_layout.addWidget(self.send_hwid_chk)

        hwid_row = QHBoxLayout()
        hwid_row.addWidget(QLabel("HWID:"))
        hwid_val = QLabel(SubscriptionService.get_hwid())
        hwid_val.setStyleSheet("font-weight: bold; color: #9AA0A6;")
        hwid_row.addWidget(hwid_val)
        hwid_row.addStretch()
        ua_layout.addLayout(hwid_row)

        layout.addWidget(ua_card)

        # 5. System Tray (Requirement 6: NO "Фоновая работа" plate)
        layout.addWidget(self._make_header("Системный трей и Выход"))
        tray_card = QFrame()
        tray_card.setProperty("card", "true")
        tray_layout = QVBoxLayout(tray_card)

        exit_btn = QPushButton("Полностью выйти из приложения")
        exit_btn.setProperty("danger", "true")
        exit_btn.clicked.connect(self._exit_app)
        tray_layout.addWidget(exit_btn)

        layout.addWidget(tray_card)

        scroll.setWidget(content_widget)
        main_layout.addWidget(scroll)

        # Bottom Buttons
        btn_box = QHBoxLayout()
        btn_box.addStretch()

        cancel_btn = QPushButton("Отмена")
        cancel_btn.clicked.connect(self.reject)
        btn_box.addWidget(cancel_btn)

        save_btn = QPushButton("Сохранить настройки")
        save_btn.setProperty("primary", "true")
        save_btn.clicked.connect(self._save)
        btn_box.addWidget(save_btn)

        main_layout.addLayout(btn_box)

    def _make_header(self, text: str) -> QLabel:
        lbl = QLabel(text)
        lbl.setStyleSheet("color: #3574F0; font-weight: bold; font-size: 13px; margin-top: 4px;")
        return lbl

    def _import_font(self):
        file_path, _ = QFileDialog.getOpenFileName(
            self,
            "Выберите файл шрифта",
            "",
            "Шрифты (*.ttf *.otf);;Все файлы (*.*)"
        )
        if file_path and os.path.isfile(file_path):
            font_id = QFontDatabase.addApplicationFont(file_path)
            if font_id >= 0:
                families = QFontDatabase.applicationFontFamilies(font_id)
                if families:
                    family = families[0]
                    self.settings.font_family = family
                    self.settings.custom_font_path = file_path
                    self.font_lbl.setText(family)
                    QMessageBox.information(self, "Шрифт", f"Шрифт '{family}' успешно импортирован!")
                    return
            QMessageBox.warning(self, "Ошибка", "Не удалось загрузить шрифт.")

    def _reset_font(self):
        self.settings.font_family = "Segoe UI"
        self.settings.custom_font_path = None
        self.font_lbl.setText("Segoe UI")

    def _exit_app(self):
        self.parent().exit_application()

    def _save(self):
        self.settings.routing_preset = self.preset_combo.currentData()
        self.settings.secure_dns_enabled = self.secure_dns_chk.isChecked()
        self.settings.bypass_lan_enabled = self.bypass_lan_chk.isChecked()
        self.settings.ping_url = self.ping_url_edit.text().strip() or "http://cp.cloudflare.com/"
        self.settings.ping_timeout_ms = self.timeout_slider.value() * 1000
        self.settings.theme_mode = self.theme_combo.currentData()
        self.settings.user_agent = self.ua_combo.currentText().strip() or "v2rayN/6.42"
        self.settings.send_hwid = self.send_hwid_chk.isChecked()

        self.parent().save_settings(self.settings)
        self.accept()
