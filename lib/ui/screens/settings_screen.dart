import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vpn_provider.dart';
import '../../services/hwid_service.dart';
import '../../services/subscription_service.dart';
import '../../services/tray_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _hwid = 'Загрузка...';

  @override
  void initState() {
    super.initState();
    HwidService.getHWID().then((val) {
      if (mounted) setState(() => _hwid = val);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vpn = ref.watch(vpnProvider);
    final settings = vpn.settings;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSectionHeader('Маршрутизация (Трафик)'),
          Card(
            color: colorScheme.surfaceContainer,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.alt_route_rounded),
                  title: const Text('Режим туннелирования'),
                  subtitle: Text(
                    settings.routingPreset == 'russia'
                        ? '🇷🇺 Обход сайтов РФ (Россия напрямую, остальное в VPN)'
                        : '🌐 Глобальный (100% трафика системы через VPN)',
                  ),
                  trailing: DropdownButton<String>(
                    value: settings.routingPreset,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'russia',
                        child: Text('Обход сайтов РФ'),
                      ),
                      DropdownMenuItem(
                        value: 'none',
                        child: Text('Глобальный (Все в VPN)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(vpnProvider.notifier).updateSettings(
                              settings.copyWith(routingPreset: val),
                            );
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.dns_rounded),
                  title: const Text('Защищенный DNS (DoH)'),
                  subtitle: const Text('DNS-over-HTTPS Cloudflare (1.1.1.1) внутри туннеля'),
                  trailing: Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.lan_rounded),
                  title: const Text('Обход локальной сети (LAN)'),
                  subtitle: const Text('Прямой доступ к домашним устройствам и принтерам (192.168.*, 10.*)'),
                  trailing: Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildSectionHeader('Пинг и Задержка'),
          Card(
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Сайт для замера пинга'),
                  subtitle: Text(settings.pingUrl),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editStringDialog('URL для пинга', settings.pingUrl, (val) {
                    ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(pingUrl: val));
                  }),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('URL для теста скачивания'),
                  subtitle: Text(settings.speedtestUrl),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editStringDialog('URL скачивания', settings.speedtestUrl, (val) {
                    ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(speedtestUrl: val));
                  }),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Таймаут пинга'),
                  subtitle: Text('${settings.pingTimeoutMs} мс (1 секунда)'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Пинг через Proxy GET'),
                  subtitle: const Text('Реальная задержка через прокси соединение'),
                  value: settings.pingViaProxy,
                  onChanged: (val) {
                    ref.read(vpnProvider.notifier).updateSettings(
                          settings.copyWith(pingViaProxy: val),
                        );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Отключать VPN перед пингом всех серверов'),
                  subtitle: const Text('Автоматически разрывать соединение для чистого замера'),
                  value: settings.disconnectBeforePing,
                  onChanged: (val) {
                    ref.read(vpnProvider.notifier).updateSettings(
                          settings.copyWith(disconnectBeforePing: val),
                        );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildSectionHeader('Тема и шрифт'),
          Card(
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Шрифт приложения'),
                  subtitle: Text(settings.fontFamily),
                  trailing: DropdownButton<String>(
                    value: settings.fontFamily,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'Google Sans', child: Text('Google Sans')),
                      DropdownMenuItem(value: 'Roboto', child: Text('Roboto')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(fontFamily: val));
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Режим темы'),
                  subtitle: Text(settings.themeMode.toUpperCase()),
                  trailing: DropdownButton<String>(
                    value: settings.themeMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('Системная')),
                      DropdownMenuItem(value: 'light', child: Text('Светлая')),
                      DropdownMenuItem(value: 'dark', child: Text('Тёмная')),
                      DropdownMenuItem(value: 'amoled', child: Text('AMOLED Black')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(themeMode: val));
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Material You (Dynamic Color)'),
                  subtitle: const Text('Адаптивные системные акцентные цвета палитры'),
                  value: settings.useDynamicColor,
                  onChanged: (val) {
                    ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(useDynamicColor: val));
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildSectionHeader('Подписка и HWID'),
          Card(
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                ListTile(
                  title: const Text('User-Agent запроса'),
                  subtitle: Text(settings.userAgent),
                  trailing: DropdownButton<String>(
                    value: settings.userAgent,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'MaterialVless', child: Text('MaterialVless')),
                      DropdownMenuItem(value: 'v2rayN', child: Text('v2rayN')),
                      DropdownMenuItem(value: 'Clash.Meta', child: Text('Clash.Meta')),
                      DropdownMenuItem(value: 'Sing-box', child: Text('Sing-box')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(userAgent: val));
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Отправлять аппаратный ID (HWID)'),
                  subtitle: const Text('Необходимо для авторизации подписок Marzban / V2Board'),
                  value: settings.sendHwid,
                  onChanged: (val) {
                    ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(sendHwid: val));
                  },
                ),
                ListTile(
                  title: const Text('Аппаратный HWID устройства'),
                  subtitle: SelectableText(_hwid, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('Системный трей и завершение работы'),
          Card(
            color: colorScheme.surfaceContainer,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Icon(Icons.vertical_split_rounded),
                  title: Text('Фоновая работа в трее'),
                  subtitle: Text('При нажатии [X] окно сворачивается в системный трей, сохраняя подключение'),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.power_settings_new_rounded, color: Colors.red),
                  title: const Text('Полностью выйти из приложения', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Отключить VPN, очистить прокси и завершить все процессы'),
                  trailing: FilledButton.tonal(
                    style: FilledButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () async {
                      await ref.read(vpnProvider.notifier).exitApp();
                      await TrayService.instance.cleanUpAndExit();
                    },
                    child: const Text('Выйти'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  void _editStringDialog(String title, String initialValue, Function(String) onSave) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
