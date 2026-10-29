from PyQt6.QtWidgets import (
    QDialog, QVBoxLayout, QHBoxLayout, QLabel, QLineEdit,
    QPushButton, QCheckBox, QComboBox, QFrame, QMessageBox
)
from PyQt6.QtCore import Qt
from ..models import SubscriptionModel

class SubscriptionDialog(QDialog):
    def __init__(self, parent, sub: SubscriptionModel):
        super().__init__(parent)
        self.sub = sub
        self.setWindowTitle("Настройки подписки")
        self.resize(480, 360)

        layout = QVBoxLayout(self)
        layout.setSpacing(14)

        # Pin Button
        top_row = QHBoxLayout()
        self.pin_btn = QPushButton("Открепить" if sub.is_pinned else "Закрепить сверху")
        self.pin_btn.clicked.connect(self._toggle_pin)
        top_row.addWidget(self.pin_btn)
        layout.addLayout(top_row)

        # Name Field
        layout.addWidget(QLabel("Название подписки:"))
        self.name_edit = QLineEdit(sub.name)
        layout.addWidget(self.name_edit)

        # URL Field (Requirement 7)
        layout.addWidget(QLabel("URL адрес подписки (можно редактировать):"))
        self.url_edit = QLineEdit(sub.url)
        self.url_edit.setPlaceholderText("https://...")
        layout.addWidget(self.url_edit)

        # Last Updated Card
        info_card = QFrame()
        info_card.setProperty("card", "true")
        info_layout = QVBoxLayout(info_card)
        info_layout.setContentsMargins(10, 8, 10, 8)
        info_layout.addWidget(QLabel("Последнее обновление:"))
        date_str = sub.last_updated.strftime("%d.%m.%Y %H:%M:%S")
        val_lbl = QLabel(date_str)
        val_lbl.setStyleSheet("color: #3574F0; font-weight: bold;")
        info_layout.addWidget(val_lbl)
        layout.addWidget(info_card)

        # Auto-update
        self.auto_update_chk = QCheckBox("Автообновление узлов")
        self.auto_update_chk.setChecked(sub.auto_update)
        layout.addWidget(self.auto_update_chk)

        interval_row = QHBoxLayout()
        interval_row.addWidget(QLabel("Периодичность обновления:"))
        self.interval_combo = QComboBox()
        for h in [1, 2, 6, 12, 24]:
            self.interval_combo.addItem(f"{h} ч.", h)
        idx = self.interval_combo.findData(sub.auto_update_interval_hours)
        if idx >= 0:
            self.interval_combo.setCurrentIndex(idx)
        interval_row.addWidget(self.interval_combo)
        layout.addLayout(interval_row)

        layout.addStretch()

        # Action Buttons
        btn_row = QHBoxLayout()
        del_btn = QPushButton("Удалить")
        del_btn.setProperty("danger", "true")
        del_btn.clicked.connect(self._delete_sub)
        btn_row.addWidget(del_btn)

        btn_row.addStretch()

        cancel_btn = QPushButton("Отмена")
        cancel_btn.clicked.connect(self.reject)
        btn_row.addWidget(cancel_btn)

        save_btn = QPushButton("Сохранить")
        save_btn.setProperty("primary", "true")
        save_btn.clicked.connect(self._save_sub)
        btn_row.addWidget(save_btn)

        layout.addLayout(btn_row)

    def _toggle_pin(self):
        self.sub.is_pinned = not self.sub.is_pinned
        self.pin_btn.setText("Открепить" if self.sub.is_pinned else "Закрепить сверху")

    def _delete_sub(self):
        confirm = QMessageBox.question(
            self,
            "Удаление подписки",
            f"Вы действительно хотите удалить подписку '{self.sub.name}'?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )
        if confirm == QMessageBox.StandardButton.Yes:
            self.parent().delete_subscription(self.sub.id)
            self.accept()

    def _save_sub(self):
        new_name = self.name_edit.text().strip()
        new_url = self.url_edit.text().strip()

        url_changed = (new_url != self.sub.url and len(new_url) > 0)
        self.sub.name = new_name if new_name else self.sub.name
        self.sub.url = new_url if new_url else self.sub.url
        self.sub.auto_update = self.auto_update_chk.isChecked()
        self.sub.auto_update_interval_hours = self.interval_combo.currentData()

        self.parent().save_and_update_subscription(self.sub, url_changed=url_changed)
        self.accept()
