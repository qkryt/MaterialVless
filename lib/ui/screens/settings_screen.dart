import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vpn_provider.dart';
import '../../services/hwid_service.dart';
import '../../services/subscription_service.dart';

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
          _buildSectionHeader('Маршрутизация'),
          Card(
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Предустановленный пресет'),
                  subtitle: Text(
                    settings.routingPreset == 'none'
                        ? '1. None (по умолчанию - весь трафик через прокси)'
                        : '2. Russia (обход сайтов РФ и локальных IP)',
                  ),
                  trailing: DropdownButton<String>(
                    value: settings.routingPreset,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('None (Default)')),
                      DropdownMenuItem(value: 'russia', child: Text('Russia')),
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
                SwitchListTile(
                  title: const Text('Автообновление GeoIP и GeoSite'),
                  subtitle: const Text('Скачивать свежие базы правил Loyalsoldier при входе'),
                  value: settings.autoUpdateRulesOnStart,
                  onChanged: (val) {
                    ref.read(vpnProvider.notifier).updateSettings(
                          settings.copyWith(autoUpdateRulesOnStart: val),
                        );
                  },
                ),
                ListTile(
                  title: const Text('Обновить базы правил сейчас'),
                  subtitle: const Text('Loyalsoldier v2ray-rules-dat'),
                  trailing: FilledButton.tonal(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Обновление GeoIP и GeoSite...')),
                      );
                      await SubscriptionService.updateGeoDatabases(
                        targetDir: '.',
                        geoipUrl: settings.geoipUrl,
                        geositeUrl: settings.geositeUrl,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Базы GeoIP/GeoSite успешно обновлены!')),
                        );
                      }
                    },
                    child: const Text('Обновить'),
                  ),
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
