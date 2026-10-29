def get_qt6_dark_stylesheet(font_family: str = "Segoe UI") -> str:
    return f"""
    * {{
        font-family: "{font_family}", "Segoe UI", sans-serif;
        font-size: 13px;
        color: #EDEDED;
    }}

    QMainWindow, QDialog {{
        background-color: #1B1D22;
    }}

    QWidget {{
        background-color: transparent;
    }}

    /* Card Panels */
    QFrame[card="true"] {{
        background-color: #24272F;
        border: 1px solid #383D4A;
        border-radius: 6px;
    }}

    /* Buttons */
    QPushButton {{
        background-color: #2D313B;
        color: #EDEDED;
        border: 1px solid #383D4A;
        border-radius: 6px;
        padding: 6px 14px;
        font-weight: 600;
    }}
    QPushButton:hover {{
        background-color: #363B48;
        border-color: #4A5060;
    }}
    QPushButton:pressed {{
        background-color: #1E2127;
    }}

    QPushButton[primary="true"] {{
        background-color: #3574F0;
        color: #FFFFFF;
        border: 1px solid #2962D9;
    }}
    QPushButton[primary="true"]:hover {{
        background-color: #2D68E2;
    }}
    QPushButton[primary="true"]:pressed {{
        background-color: #1F54C7;
    }}

    QPushButton[danger="true"] {{
        background-color: rgba(239, 68, 68, 0.15);
        color: #F87171;
        border: 1px solid rgba(239, 68, 68, 0.3);
    }}
    QPushButton[danger="true"]:hover {{
        background-color: rgba(239, 68, 68, 0.25);
    }}

    /* Big Power Button */
    QPushButton#powerBtn {{
        background-color: #24272F;
        color: #EDEDED;
        border: 2px solid #383D4A;
        border-radius: 75px;
        font-size: 15px;
        font-weight: bold;
        letter-spacing: 1px;
    }}
    QPushButton#powerBtn:hover {{
        border-color: #3574F0;
        background-color: #2B303B;
    }}
    QPushButton#powerBtn[connected="true"] {{
        background-color: #10B981;
        color: #FFFFFF;
        border: 2px solid #059669;
    }}

    /* Line Edit */
    QLineEdit {{
        background-color: #24272F;
        border: 1px solid #383D4A;
        border-radius: 6px;
        padding: 6px 10px;
        color: #EDEDED;
    }}
    QLineEdit:focus {{
        border: 1.5px solid #3574F0;
    }}

    /* ComboBox */
    QComboBox {{
        background-color: #24272F;
        border: 1px solid #383D4A;
        border-radius: 6px;
        padding: 5px 10px;
        color: #EDEDED;
    }}
    QComboBox:hover {{
        border-color: #4A5060;
    }}
    QComboBox::drop-down {{
        border: none;
        width: 20px;
    }}
    QComboBox QAbstractItemView {{
        background-color: #24272F;
        border: 1px solid #383D4A;
        selection-background-color: #3574F0;
        selection-color: #FFFFFF;
    }}

    /* Sliders */
    QSlider::groove:horizontal {{
        height: 6px;
        background: #383D4A;
        border-radius: 3px;
    }}
    QSlider::sub-page:horizontal {{
        background: #3574F0;
        border-radius: 3px;
    }}
    QSlider::handle:horizontal {{
        background: #EDEDED;
        border: 2px solid #3574F0;
        width: 16px;
        margin-top: -5px;
        margin-bottom: -5px;
        border-radius: 8px;
    }}

    /* Checkbox & Switch */
    QCheckBox {{
        spacing: 8px;
    }}
    QCheckBox::indicator {{
        width: 18px;
        height: 18px;
        border-radius: 4px;
        border: 1px solid #383D4A;
        background-color: #24272F;
    }}
    QCheckBox::indicator:checked {{
        background-color: #3574F0;
        border-color: #3574F0;
    }}

    /* Scrollbars */
    QScrollBar:vertical {{
        background: transparent;
        width: 8px;
        margin: 0px;
    }}
    QScrollBar::handle:vertical {{
        background: #383D4A;
        min-height: 20px;
        border-radius: 4px;
    }}
    QScrollBar::handle:vertical:hover {{
        background: #4A5060;
    }}
    QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {{
        height: 0px;
    }}

    /* Status Bar */
    QStatusBar {{
        background-color: #17181C;
        border-top: 1px solid #2F333C;
        font-size: 11px;
        color: #9AA0A6;
    }}

    /* QTreeWidget / QListWidget */
    QTreeWidget, QListWidget {{
        background-color: #1B1D22;
        border: none;
    }}
    QTreeWidget::item, QListWidget::item {{
        padding: 6px 8px;
        border-radius: 6px;
    }}
    QTreeWidget::item:selected, QListWidget::item:selected {{
        background-color: #24272F;
        border: 1px solid #3574F0;
    }}
    QTreeWidget::item:hover, QListWidget::item:hover {{
        background-color: #22252C;
    }}
    """
