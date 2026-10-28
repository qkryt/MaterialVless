import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/dashboard_screen.dart';
import 'providers/vpn_provider.dart';
import 'utils/admin_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // На Windows строго требуются права Администратора для управления TUN-драйвером Wintun
  if (Platform.isWindows) {
    final hasAdmin = await AdminHelper.ensureAdminPrivileges();
    if (!hasAdmin) {
      exit(0); // Пользователь отклонил UAC — немедленный выход!
    }
  }

  runApp(
    const ProviderScope(
      child: MaterialVlessApp(),
    ),
  );
}

class MaterialVlessApp extends ConsumerWidget {
  const MaterialVlessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vpn = ref.watch(vpnProvider);
    final themeMode = vpn.settings.themeMode;
    final fontFamily = vpn.settings.fontFamily;
    final useDynamic = vpn.settings.useDynamicColor;

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
          theme: AppTheme.light(lightScheme, fontFamily: fontFamily),
          darkTheme: AppTheme.dark(
            darkScheme,
            fontFamily: fontFamily,
            isAmoled: themeMode == 'amoled',
          ),
          themeMode: mode,
          home: const DashboardScreen(),
        );
      },
    );
  }
}
