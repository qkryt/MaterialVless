import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/widgets/smooth_scroll.dart';
import 'providers/vpn_provider.dart';
import 'utils/admin_helper.dart';
import 'services/single_instance_service.dart';
import 'services/url_scheme_service.dart';
import 'services/custom_font_service.dart';
import 'services/background_service.dart';
import 'services/log_service.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Инициализация записи логов в log.txt
  await LogService.init();
  LogService.log('Application starting with arguments: $args');

  // 1. Проверка на единственный запущенный экземпляр программы
  final isPrimary = await SingleInstanceService.ensureSingleInstance(args);
  if (!isPrimary) {
    LogService.log('Another primary instance detected, closing secondary process.');
    exit(0); // Рабочий инстанс уже запущен и активирован
  }

  // 2. На Windows требуются права Администратора для Wintun
  if (Platform.isWindows) {
    final hasAdmin = await AdminHelper.ensureAdminPrivileges();
    if (!hasAdmin) {
      LogService.log('Admin privileges not granted, exiting.');
      exit(0);
    }
    // Регистрация URL-схем material:// и happ://
    UrlSchemeService.registerWindowsProtocolHandlers();
  }

  // 3. Загрузка кастомных шрифтов
  await CustomFontService.loadAllCustomFonts();

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
      LogService.log('Received message from another instance: $msg');
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
    final hasBackgroundImage = vpn.settings.hasBackgroundImage;
    final bgPath = vpn.settings.backgroundImagePath;
    final bgDimming = vpn.settings.backgroundDimming;

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
          themeAnimationDuration: Duration.zero,
          theme: AppTheme.light(
            lightScheme,
            fontFamily: fontFamily,
            accentColor: accentColor,
            hasBackgroundImage: hasBackgroundImage,
          ),
          darkTheme: AppTheme.dark(
            darkScheme,
            fontFamily: fontFamily,
            isAmoled: themeMode == 'amoled',
            accentColor: accentColor,
            hasBackgroundImage: hasBackgroundImage,
          ),
          themeMode: mode,
          scrollBehavior: const SmoothScrollBehavior(),
          builder: (context, child) {
            final activeBgPath = vpn.settings.activeBackgroundImagePath;
            if (!hasBackgroundImage || activeBgPath == null) {
              return child ?? const SizedBox();
            }

            Uint8List? bgBytes;
            try {
              bgBytes = File(activeBgPath).readAsBytesSync();
            } catch (_) {}

            if (bgBytes == null || bgBytes.isEmpty) {
              return child ?? const SizedBox();
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: Image.memory(
                    bgBytes,
                    key: ValueKey('$activeBgPath-${bgBytes.length}-${File(activeBgPath).lastModifiedSync().millisecondsSinceEpoch}'),
                    fit: BoxFit.fill,
                    width: double.infinity,
                    height: double.infinity,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(bgDimming.clamp(0.05, 0.95)),
                  ),
                ),
                if (child != null) child,
              ],
            );
          },
          home: const DashboardScreen(),
        );
      },
    );
  }
}
