import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class TrayService with TrayListener, WindowListener {
  static final TrayService instance = TrayService._();
  TrayService._();

  bool _initialized = false;
  Future<void> Function()? onRestartCore;
  Future<void> Function()? onExitApp;

  Future<void> init({
    required Future<void> Function() onRestartCore,
    required Future<void> Function() onExitApp,
  }) async {
    this.onRestartCore = onRestartCore;
    this.onExitApp = onExitApp;

    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;

    try {
      // Инициализация оконного менеджера для работы в фоне / трее
      await windowManager.ensureInitialized();
      windowManager.addListener(this);
      await windowManager.setPreventClose(true);

      // Инициализация системного трея
      await trayManager.ensureInitialized();
      trayManager.addListener(this);

      // Определение пути к иконке приложения
      String iconPath = 'assets/icons/app_icon.png';
      if (Platform.isWindows) {
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        final candidate1 = '$exeDir/app_icon.ico';
        final candidate2 = '$exeDir/data/flutter_assets/assets/icons/app_icon.ico';
        if (File(candidate1).existsSync()) {
          iconPath = candidate1;
        } else if (File(candidate2).existsSync()) {
          iconPath = candidate2;
        } else {
          iconPath = 'assets/icons/app_icon.ico';
        }
      }

      try {
        await trayManager.setIcon(iconPath);
      } catch (e) {
        debugPrint('Tray icon warning: $e');
      }

      await updateTrayMenu();
      _initialized = true;
    } catch (e) {
      debugPrint('TrayService init error: $e');
    }
  }

  Future<void> updateTrayMenu({String statusText = 'MaterialVless'}) async {
    try {
      final menu = Menu(
        items: [
          MenuItem(
            key: 'show_window',
            label: 'Открыть',
          ),
          MenuItem(
            key: 'restart_core',
            label: 'Перезагрузить ядро',
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'exit_app',
            label: 'Выйти',
          ),
        ],
      );
      await trayManager.setContextMenu(menu);
      await trayManager.setToolTip(statusText);
    } catch (e) {
      debugPrint('updateTrayMenu warning: $e');
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show_window') {
      await showAppWindow();
    } else if (menuItem.key == 'restart_core') {
      await onRestartCore?.call();
    } else if (menuItem.key == 'exit_app') {
      await onExitApp?.call();
    }
  }

  @override
  void onTrayIconMouseDown() async {
    await showAppWindow();
  }

  @override
  void onTrayIconRightMouseDown() async {
    try {
      await trayManager.popUpContextMenu();
    } catch (_) {}
  }

  @override
  void onWindowClose() async {
    try {
      final isPrevent = await windowManager.isPreventClose();
      if (isPrevent) {
        await windowManager.hide();
      } else {
        await onExitApp?.call();
      }
    } catch (_) {
      exit(0);
    }
  }

  Future<void> showAppWindow() async {
    try {
      await windowManager.show();
      await windowManager.focus();
    } catch (_) {}
  }

  Future<void> hideAppWindow() async {
    try {
      await windowManager.hide();
    } catch (_) {}
  }

  Future<void> cleanUpAndExit() async {
    try {
      await trayManager.destroy();
    } catch (_) {}
    try {
      await windowManager.destroy();
    } catch (_) {}
    exit(0);
  }
}
