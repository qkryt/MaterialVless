import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/dashboard_screen.dart';
import 'providers/vpn_provider.dart';
import 'utils/admin_helper.dart';
import 'services/single_instance_service.dart';
import 'services/url_scheme_service.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Проверка на единственный запущенный экземпляр программы
  final isPrimary = await SingleInstanceService.ensureSingleInstance(args);
  if (!isPrimary) {
    exit(0); // Рабочий инстанс уже запущен и активирован
  }

  // 2. На Windows требуются права Администратора для Wintun
  if (Platform.isWindows) {
    final hasAdmin = await AdminHelper.ensureAdminPrivileges();
    if (!hasAdmin) {
      exit(0);
    }
    // Регистрация URL-схем material:// и happ://
    UrlSchemeService.registerWindowsProtocolHandlers();
  }

  runApp(
    ProviderScope(
      child: MaterialVlessApp(initialArgs: args),
    ),
  );
}

class MaterialVlessApp extends ConsumerStatefulWidget {
  final List<String> initialArgs;
  const MaterialVlessApp({super.key, this.initialArgs = const []});

  @override
  ConsumerState<MaterialVlessApp> createState() => _MaterialVlessAppState();
}

class _MaterialVlessAppState extends ConsumerState<MaterialVlessApp> {
  @override
  void initState() {
    super.initState();
    // Слушатель сообщений от последующих инстансов (URL-схемы / активация окна)
    SingleInstanceService.setMessageHandler((msg) {
      if (msg.startsWith('material://') || msg.startsWith('happ://')) {
        UrlSchemeService.handleUrl(msg, ref.read(vpnProvider.notifier));
      }
    });

    if (widget.initialArgs.isNotEmpty) {
      final arg = widget.initialArgs.first;
      if (arg.startsWith('material://') || arg.startsWith('happ://')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          UrlSchemeService.handleUrl(arg, ref.read(vpnProvider.notifier));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vpn = ref.watch(vpnProvider);
    final themeMode = vpn.settings.themeMode;
    final fontFamily = vpn.settings.fontFamily;
    final useDynamic = vpn.settings.useDynamicColor;
    final accentColor = vpn.settings.accentColor;

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightScheme = useDynamic ? lightDynamic : null;
        final darkScheme = useDynamic ? darkDynamic : null;

        ThemeMode mode;
        if (themeMode == 'light') {
          mode = ThemeMode.light;
        } else if (themeMode == 'dark' || themeMode == 'amoled') {
          mode = ThemeMode.dark;
        } else {
          mode = ThemeMode.system;
        }

        return MaterialApp(
          title: 'MaterialVless',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(
            lightScheme,
            fontFamily: fontFamily,
            accentColor: accentColor,
          ),
          darkTheme: AppTheme.dark(
            darkScheme,
            fontFamily: fontFamily,
            isAmoled: themeMode == 'amoled',
            accentColor: accentColor,
          ),
          themeMode: mode,
          home: const DashboardScreen(),
        );
      },
    );
  }
}
