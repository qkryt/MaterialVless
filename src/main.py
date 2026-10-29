import os
import sys
import ctypes
from PyQt6.QtWidgets import QApplication
from PyQt6.QtGui import QFontDatabase, QIcon
from PyQt6.QtCore import Qt

def is_admin() -> bool:
    if sys.platform != "win32":
        return True
    try:
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except Exception:
        return False

def elevate_or_exit():
    if not is_admin():
        try:
            # Re-launch with UAC elevation
            ret = ctypes.windll.shell32.ShellExecuteW(
                None,
                "runas",
                sys.executable,
                " ".join([f'"{arg}"' for arg in sys.argv]),
                None,
                1
            )
            # If user rejected UAC prompt or failed, exit immediately
            sys.exit(0)
        except Exception:
            sys.exit(0)

def main():
    elevate_or_exit()

    app = QApplication(sys.argv)
    app.setApplicationName("MaterialVless")
    app.setApplicationDisplayName("MaterialVless 2.0 (Qt6 Edition)")

    # Set Application Icon
    icon_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "icons", "app_icon.ico")
    if os.path.isfile(icon_path):
        app.setWindowIcon(QIcon(icon_path))

    # Import MainWindow
    from src.ui.main_window import MainWindow
    window = MainWindow()
    window.show()

    sys.exit(app.exec())

if __name__ == "__main__":
    main()
