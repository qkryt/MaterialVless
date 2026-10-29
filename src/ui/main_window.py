import os
import sys
import time
from typing import List, Optional
from PyQt6.QtWidgets import (
    QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QPushButton, QLineEdit, QTreeWidget, QTreeWidgetItem,
    QFrame, QSystemTrayIcon, QMenu, QInputDialog, QMessageBox,
    QStatusBar, QHeaderView
)
from PyQt6.QtCore import Qt, QTimer
from PyQt6.QtGui import QIcon, QColor, QFont, QAction

from ..models import SubscriptionModel, VlessNode, AppSettings
from ..core_service import CoreService
from ..storage_service import StorageService
from ..subscription_service import SubscriptionService
from ..theme import get_qt6_dark_stylesheet
from .subscription_dialog import SubscriptionDialog
from .settings_dialog import SettingsDialog

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("MaterialVless 2.0 (Qt6 Edition)")
        self.resize(920, 620)
        self.setMinimumSize(780, 520)

        # Services & State
        self.core = CoreService()
        self.subscriptions: List[SubscriptionModel] = []
        self.manual_nodes: List[VlessNode] = []
        self.selected_node: Optional[VlessNode] = None
        self.settings = AppSettings()

        self._connected_seconds = 0
        self._session_timer = QTimer(self)
        self._session_timer.setInterval(1000)
        self._session_timer.timeout.connect(self._tick_session_timer)

        # Load persisted data
        self._load_initial_data()

        # Build UI
        self._setup_tray()
        self._build_ui()
        self._apply_theme()

        # Connect core signals
        self.core.state_changed.connect(self._on_core_state_changed)
        self.core.speed_updated.connect(self._on_speed_updated)

    def _load_initial_data(self):
        subs, manual, sel_id, settings = StorageService.load_data()
        self.subscriptions = subs
        self.manual_nodes = manual
        self.settings = settings

        # Restore selected node
        if sel_id:
            for s in self.subscriptions:
                for n in s.nodes:
                    if n.id == sel_id:
                        self.selected_node = n
                        break
                if self.selected_node: break

        if not self.selected_node and self.subscriptions and self.subscriptions[0].nodes:
            self.selected_node = self.subscriptions[0].nodes[0]

    def _setup_tray(self):
        icon_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "assets", "icons", "app_icon.ico")
        if not os.path.isfile(icon_path):
            icon_path = os.path.join(os.getcwd(), "assets", "icons", "app_icon.ico")

        icon = QIcon(icon_path) if os.path.isfile(icon_path) else QIcon()
        self.setWindowIcon(icon)

        self.tray = QSystemTrayIcon(icon, self)
        tray_menu = QMenu()

        # Exactly 3 buttons as requested
        open_act = QAction("Открыть", self)
        open_act.triggered.connect(self.showNormal)
        tray_menu.addAction(open_act)

        restart_act = QAction("Перезагрузить ядро", self)
        restart_act.triggered.connect(self.restart_core)
        tray_menu.addAction(restart_act)

        tray_menu.addSeparator()

        exit_act = QAction("Выйти", self)
        exit_act.triggered.connect(self.exit_application)
        tray_menu.addAction(exit_act)

        self.tray.setContextMenu(tray_menu)
        self.tray.activated.connect(self._on_tray_activated)
        self.tray.show()

    def _on_tray_activated(self, reason):
        if reason == QSystemTrayIcon.ActivationReason.DoubleClick:
            self.showNormal()

    def _build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        main_layout = QHBoxLayout(central)
        main_layout.setContentsMargins(12, 12, 12, 8)
        main_layout.setSpacing(12)

        # Left Panel (Subscriptions & Nodes)
        left_panel = QFrame()
        left_panel.setProperty("card", "true")
        left_layout = QVBoxLayout(left_panel)
        left_layout.setContentsMargins(10, 10, 10, 10)
        left_layout.setSpacing(8)

        # Toolbar
        top_bar = QHBoxLayout()
        title_lbl = QLabel("Серверы и Подписки")
        title_lbl.setStyleSheet("font-weight: bold; font-size: 14px;")
        top_bar.addWidget(title_lbl)
        top_bar.addStretch()

        ping_all_btn = QPushButton("Пинг")
        ping_all_btn.setToolTip("Замерить пинг всех серверов")
        ping_all_btn.clicked.connect(self.ping_all_nodes)
        top_bar.addWidget(ping_all_btn)

        add_btn = QPushButton("+")
        add_btn.setToolTip("Добавить подписку или ссылку vless://")
        add_btn.clicked.connect(self._add_subscription_dialog)
        top_bar.addWidget(add_btn)

        settings_btn = QPushButton("⚙")
        settings_btn.setToolTip("Настройки клиента")
        settings_btn.clicked.connect(self._open_settings)
        top_bar.addWidget(settings_btn)

        left_layout.addLayout(top_bar)

        # Search bar
        self.search_edit = QLineEdit()
        self.search_edit.setPlaceholderText("Поиск серверов...")
        self.search_edit.textChanged.connect(self._filter_nodes)
        left_layout.addWidget(self.search_edit)

        # Tree View for Subscriptions and Nodes
        self.tree = QTreeWidget()
        self.tree.setHeaderHidden(True)
        self.tree.itemClicked.connect(self._on_tree_item_clicked)
        left_layout.addWidget(self.tree)

        main_layout.addWidget(left_panel, stretch=5)

        # Right Panel (Connection, Dashboard, Telemetry)
        right_panel = QFrame()
        right_panel.setProperty("card", "true")
        right_layout = QVBoxLayout(right_panel)
        right_layout.setContentsMargins(16, 16, 16, 16)
        right_layout.setSpacing(16)

        # Selected Server Card
        self.server_card = QFrame()
        self.server_card.setProperty("card", "true")
        sc_layout = QVBoxLayout(self.server_card)
        sc_layout.setContentsMargins(12, 10, 12, 10)

        sc_top = QHBoxLayout()
        self.sel_name_lbl = QLabel("Выберите сервер из списка")
        self.sel_name_lbl.setStyleSheet("font-weight: bold; font-size: 14px;")
        sc_top.addWidget(self.sel_name_lbl)
        sc_top.addStretch()

        self.sel_ping_badge = QLabel("")
        self.sel_ping_badge.setStyleSheet("color: #10B981; font-weight: bold; padding: 2px 6px; border: 1px solid #10B981; border-radius: 4px;")
        self.sel_ping_badge.setVisible(False)
        sc_top.addWidget(self.sel_ping_badge)
        sc_layout.addLayout(sc_top)

        self.sel_detail_lbl = QLabel("")
        self.sel_detail_lbl.setStyleSheet("color: #9AA0A6; font-size: 11px;")
        sc_layout.addWidget(self.sel_detail_lbl)
        right_layout.addWidget(self.server_card)

        # Center Power Button
        right_layout.addStretch()
        btn_center = QHBoxLayout()
        btn_center.addStretch()

        self.power_btn = QPushButton("ПОДКЛЮЧИТЬ")
        self.power_btn.setObjectName("powerBtn")
        self.power_btn.setFixedSize(150, 150)
        self.power_btn.clicked.connect(self.toggle_connection)
        btn_center.addWidget(self.power_btn)

        btn_center.addStretch()
        right_layout.addLayout(btn_center)

        self.timer_lbl = QLabel("00:00:00")
        self.timer_lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.timer_lbl.setStyleSheet("font-size: 16px; font-weight: bold; color: #10B981; margin-top: 4px;")
        self.timer_lbl.setVisible(False)
        right_layout.addWidget(self.timer_lbl)

        right_layout.addStretch()

        # Telemetry row (Download / Upload / Routing)
        telem_row = QHBoxLayout()

        dl_card = QFrame()
        dl_card.setProperty("card", "true")
        dl_lay = QVBoxLayout(dl_card)
        dl_lay.setContentsMargins(10, 8, 10, 8)
        dl_lay.addWidget(QLabel("↓ Скачивание", styleSheet="color: #9AA0A6; font-size: 11px;"))
        self.dl_speed_lbl = QLabel("0.0 KB/s", styleSheet="font-weight: bold; font-size: 14px; color: #3574F0;")
        dl_lay.addWidget(self.dl_speed_lbl)
        telem_row.addWidget(dl_card)

        ul_card = QFrame()
        ul_card.setProperty("card", "true")
        ul_lay = QVBoxLayout(ul_card)
        ul_lay.setContentsMargins(10, 8, 10, 8)
        ul_lay.addWidget(QLabel("↑ Загрузка", styleSheet="color: #9AA0A6; font-size: 11px;"))
        self.ul_speed_lbl = QLabel("0.0 KB/s", styleSheet="font-weight: bold; font-size: 14px; color: #10B981;")
        ul_lay.addWidget(self.ul_speed_lbl)
        telem_row.addWidget(ul_card)

        mode_card = QFrame()
        mode_card.setProperty("card", "true")
        mode_lay = QVBoxLayout(mode_card)
        mode_lay.setContentsMargins(10, 8, 10, 8)
        mode_lay.addWidget(QLabel("Маршрутизация", styleSheet="color: #9AA0A6; font-size: 11px;"))
        self.mode_val_lbl = QLabel("🇷🇺 Обход РФ" if self.settings.routing_preset == "russia" else "🌐 Весь трафик", styleSheet="font-weight: bold; font-size: 13px;")
        mode_lay.addWidget(self.mode_val_lbl)
        telem_row.addWidget(mode_card)

        right_layout.addLayout(telem_row)

        main_layout.addWidget(right_panel, stretch=5)

        # Status Bar
        self.status_bar = QStatusBar()
        self.setStatusBar(self.status_bar)
        self._update_status_bar()

        # Render tree
        self._populate_tree()
        self._update_selected_server_display()

    def _apply_theme(self):
        self.setStyleSheet(get_qt6_dark_stylesheet(self.settings.font_family))

    def _populate_tree(self):
        self.tree.clear()

        # Sort pinned subscriptions to top
        sorted_subs = sorted(self.subscriptions, key=lambda s: not s.is_pinned)

        for sub in sorted_subs:
            sub_item = QTreeWidgetItem(self.tree)
            sub_item.setData(0, Qt.ItemDataRole.UserRole, ("sub", sub))

            header_widget = QWidget()
            h_layout = QHBoxLayout(header_widget)
            h_layout.setContentsMargins(4, 2, 4, 2)

            pin_badge = "📌 " if sub.is_pinned else ""
            title = QLabel(f"{pin_badge}{sub.name} ({len(sub.nodes)})")
            title.setStyleSheet("font-weight: bold;")
            h_layout.addWidget(title)
            h_layout.addStretch()

            # Refresh button
            ref_btn = QPushButton("🔄")
            ref_btn.setFixedSize(26, 24)
            ref_btn.setToolTip("Обновить подписку")
            ref_btn.clicked.connect(lambda _, s_id=sub.id: self.refresh_subscription(s_id))
            h_layout.addWidget(ref_btn)

            # Ping button
            png_btn = QPushButton("⚡")
            png_btn.setFixedSize(26, 24)
            png_btn.setToolTip("Пинг серверов подписки")
            png_btn.clicked.connect(lambda _, s_id=sub.id: self.ping_subscription(s_id))
            h_layout.addWidget(png_btn)

            # Options button
            opt_btn = QPushButton("⋮")
            opt_btn.setFixedSize(26, 24)
            opt_btn.setToolTip("Настройки подписки")
            opt_btn.clicked.connect(lambda _, s=sub: self._open_subscription_options(s))
            h_layout.addWidget(opt_btn)

            self.tree.setItemWidget(sub_item, 0, header_widget)

            # Nodes
            for node in sub.nodes:
                node_item = QTreeWidgetItem(sub_item)
                node_item.setData(0, Qt.ItemDataRole.UserRole, ("node", node))

                node_widget = QWidget()
                n_layout = QHBoxLayout(node_widget)
                n_layout.setContentsMargins(18, 2, 6, 2)

                flag = self._get_country_flag(node.remark)
                n_title = QLabel(f"{flag} {node.remark}")
                n_layout.addWidget(n_title)
                n_layout.addStretch()

                if node.ping_ms is not None:
                    p_badge = QLabel(f"{node.ping_ms} ms")
                    p_color = "#10B981" if node.ping_ms < 120 else ("#FBBF24" if node.ping_ms < 300 else "#EF4444")
                    p_badge.setStyleSheet(f"color: {p_color}; font-size: 11px; font-weight: bold;")
                    n_layout.addWidget(p_badge)

                self.tree.setItemWidget(node_item, 0, node_widget)

            sub_item.setExpanded(sub.is_expanded)

    def _get_country_flag(self, text: str) -> str:
        t = text.upper()
        if "RU" in t or "РОСС" in t: return "🇷🇺"
        if "DE" in t or "ГЕРМ" in t: return "🇩🇪"
        if "NL" in t or "НИДЕР" in t: return "🇳🇱"
        if "US" in t or "США" in t: return "🇺🇸"
        if "FI" in t or "ФИН" in t: return "🇫🇮"
        if "GB" in t or "UK" in t or "АНГЛ" in t: return "🇬🇧"
        if "FR" in t or "ФРАН" in t: return "🇫🇷"
        if "SE" in t or "ШВЕЦ" in t: return "🇸🇪"
        if "TR" in t or "ТУРЦ" in t: return "🇹🇷"
        if "KZ" in t or "КАЗАХ" in t: return "🇰🇿"
        return "🌐"

    def _on_tree_item_clicked(self, item: QTreeWidgetItem, column: int):
        data = item.data(0, Qt.ItemDataRole.UserRole)
        if not data: return
        kind, obj = data
        if kind == "node":
            self.select_node(obj)

    def select_node(self, node: VlessNode):
        is_different = not self.selected_node or self.selected_node.id != node.id
        self.selected_node = node
        self._update_selected_server_display()
        self._persist_data()

        if is_different and self.core.state == "connected":
            self.core.restart(node, self.settings)

    def _update_selected_server_display(self):
        if self.selected_node:
            self.sel_name_lbl.setText(self.selected_node.remark)
            self.sel_detail_lbl.setText(
                f"{self.selected_node.protocol.upper()} • {self.selected_node.address}:{self.selected_node.port} • "
                f"Security: {self.selected_node.security} • SNI: {self.selected_node.sni or '-'}"
            )
            if self.selected_node.ping_ms is not None:
                self.sel_ping_badge.setText(f"{self.selected_node.ping_ms} ms")
                self.sel_ping_badge.setVisible(True)
            else:
                self.sel_ping_badge.setVisible(False)
        else:
            self.sel_name_lbl.setText("Выберите сервер из списка")
            self.sel_detail_lbl.setText("Нет активного подключения")
            self.sel_ping_badge.setVisible(False)
        self._update_status_bar()

    def toggle_connection(self):
        if self.core.state == "connected":
            self.core.stop()
        elif self.selected_node and self.core.state != "connecting":
            self.core.start(self.selected_node, self.settings)

    def _on_core_state_changed(self, state: str):
        if state == "connected":
            self.power_btn.setText("ПОДКЛЮЧЕНО")
            self.power_btn.setProperty("connected", "true")
            self.power_btn.style().polish(self.power_btn)
            self.timer_lbl.setVisible(True)
            self._connected_seconds = 0
            self._session_timer.start()
        elif state == "connecting":
            self.power_btn.setText("ПОДКЛЮЧЕНИЕ...")
            self.power_btn.setProperty("connected", "false")
            self.power_btn.style().polish(self.power_btn)
            self.timer_lbl.setVisible(False)
        else:
            self.power_btn.setText("ПОДКЛЮЧИТЬ")
            self.power_btn.setProperty("connected", "false")
            self.power_btn.style().polish(self.power_btn)
            self.timer_lbl.setVisible(False)
            self._session_timer.stop()
        self._update_status_bar()

    def _tick_session_timer(self):
        self._connected_seconds += 1
        h = self._connected_seconds // 3600
        m = (self._connected_seconds % 3600) // 60
        s = self._connected_seconds % 60
        self.timer_lbl.setText(f"{h:02d}:{m:02d}:{s:02d}")

    def _on_speed_updated(self, up_bps: int, dl_bps: int):
        self.ul_speed_lbl.setText(f"{up_bps / 1024:.1f} KB/s")
        self.dl_speed_lbl.setText(f"{dl_bps / (1024 * 1024):.1f} MB/s" if dl_bps > 1024 * 1024 else f"{dl_bps / 1024:.1f} KB/s")

    def _update_status_bar(self):
        st = self.core.state
        dot = "🟢 Подключено" if st == "connected" else ("🟡 Подключение" if st == "connecting" else "⚪ Отключено")
        node_str = f"{self.selected_node.remark} ({self.selected_node.address}:{self.selected_node.port})" if self.selected_node else "Сервер не выбран"
        self.status_bar.showMessage(f"{dot}  |  {node_str}  |  TUN: material-tun (system)  |  sing-box 1.14")

    def _open_subscription_options(self, sub: SubscriptionModel):
        dlg = SubscriptionDialog(self, sub)
        dlg.exec()

    def save_and_update_subscription(self, sub: SubscriptionModel, url_changed: bool = False):
        for i, s in enumerate(self.subscriptions):
            if s.id == sub.id:
                self.subscriptions[i] = sub
                break
        self._persist_data()
        self._populate_tree()
        if url_changed:
            self.refresh_subscription(sub.id)

    def delete_subscription(self, sub_id: str):
        self.subscriptions = [s for s in self.subscriptions if s.id != sub_id]
        if self.selected_node and self.selected_node.subscription_id == sub_id:
            self.selected_node = self.subscriptions[0].nodes[0] if self.subscriptions and self.subscriptions[0].nodes else None
        self._persist_data()
        self._populate_tree()
        self._update_selected_server_display()

    def refresh_subscription(self, sub_id: str):
        sub = next((s for s in self.subscriptions if s.id == sub_id), None)
        if not sub: return
        try:
            nodes, meta = SubscriptionService.load_subscription(sub.url, self.settings, sub.name)
            sub.nodes = nodes
            sub.last_updated = time.time()
            if meta.get("upload"): sub.upload_bytes = meta["upload"]
            if meta.get("download"): sub.download_bytes = meta["download"]
            if meta.get("total"): sub.total_bytes = meta["total"]
            self._persist_data()
            self._populate_tree()
        except Exception as e:
            QMessageBox.warning(self, "Ошибка обновления", f"Не удалось обновить подписку:\n{e}")

    def ping_subscription(self, sub_id: str):
        sub = next((s for s in self.subscriptions if s.id == sub_id), None)
        if not sub: return
        for n in sub.nodes:
            n.ping_ms = SubscriptionService.ping_node(n, self.settings.ping_timeout_ms)
        self._populate_tree()
        self._update_selected_server_display()

    def ping_all_nodes(self):
        for sub in self.subscriptions:
            for n in sub.nodes:
                n.ping_ms = SubscriptionService.ping_node(n, self.settings.ping_timeout_ms)
        self._populate_tree()
        self._update_selected_server_display()

    def _add_subscription_dialog(self):
        text, ok = QInputDialog.getText(self, "Добавить подписку", "Вставьте ссылку на подписку (URL) или узел vless://:")
        if ok and text.strip():
            url = text.strip()
            name = "Импортированная подписка"
            nodes, meta = SubscriptionService.load_subscription(url, self.settings, name)
            new_sub = SubscriptionModel(
                id=str(int(time.time())),
                name=name,
                url=url,
                nodes=nodes,
                total_bytes=meta.get("total", 0)
            )
            self.subscriptions.append(new_sub)
            if not self.selected_node and nodes:
                self.selected_node = nodes[0]
            self._persist_data()
            self._populate_tree()
            self._update_selected_server_display()

    def _open_settings(self):
        dlg = SettingsDialog(self, self.settings)
        dlg.exec()

    def save_settings(self, new_settings: AppSettings):
        self.settings = new_settings
        self._apply_theme()
        self.mode_val_lbl.setText("🇷🇺 Обход РФ" if self.settings.routing_preset == "russia" else "🌐 Весь трафик")
        self._persist_data()

    def _filter_nodes(self, text: str):
        q = text.lower().strip()
        for i in range(self.tree.topLevelItemCount()):
            sub_item = self.tree.topLevelItem(i)
            has_match = False
            for j in range(sub_item.childCount()):
                child = sub_item.child(j)
                data = child.data(0, Qt.ItemDataRole.UserRole)
                if data and data[0] == "node":
                    node = data[1]
                    match = q in node.remark.lower() or q in node.address.lower()
                    child.setHidden(not match if q else False)
                    if match: has_match = True
            sub_item.setHidden(not has_match if q else False)

    def restart_core(self):
        if self.selected_node:
            self.core.restart(self.selected_node, self.settings)

    def _persist_data(self):
        StorageService.save_data(
            self.subscriptions,
            self.manual_nodes,
            self.selected_node.id if self.selected_node else None,
            self.settings
        )

    def exit_application(self):
        self.core.stop()
        self.tray.hide()
        sys.exit(0)

    def closeEvent(self, event):
        # Minimize to tray
        event.ignore()
        self.hide()
        self.tray.showMessage(
            "MaterialVless",
            "Приложение свернуто в системный трей.",
            QSystemTrayIcon.MessageIcon.Information,
            1500
        )
