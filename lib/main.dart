import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MaterialVlessApp(),
    ),
  );
}

class MaterialVlessApp extends StatelessWidget {
  const MaterialVlessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'MaterialVless',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(lightDynamic),
          darkTheme: AppTheme.dark(darkDynamic),
          themeMode: ThemeMode.system,
          home: const DashboardScreen(),
        );
      },
    );
  }
}