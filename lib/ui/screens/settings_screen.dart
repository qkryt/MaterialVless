import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vpn_provider.dart';
import '../../services/hwid_service.dart';
import '../../services/tray_service.dart';
import '../../services/update_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _hwid = 'Загрузка...';
  bool _isCheckingUpdate = false;

  final List<String> _popularUserAgents = const [
    'v2rayN/6.42',
    'v2rayN/6.23',
    'sing-box/1.14.4',
    'sing-box/1.11.0',
    'ClashMeta/v1.18.0',
    'Clash.Meta',
    'ClashVerge/1.7.7',
    'Shadowrocket/1982',
    'QuantumultX/1.0.30',
    'Surge/5.0.0',
    'FlClash/0.8.0',
    'NekoRay/3.26',
    'Karing/1.0.31',
    'V2Ray/5.14.1',
    'Hiddify/2.5.7',
    'Streisand/1.6.4',
    'Loon/3.2.1',
    'Foxray/1.4.2',
    'Wings/1.0.0',
    'MaterialVless/2.0',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/130.0.0.0',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:132.0) Firefox/132.0',
  ];

  @override
  void initState() {
    super.initState();
    HwidService.getHWID().then((val) {
      if (mounted) setState(() => _hwid = val);
    });
  }

  Future<void> _pickAndImportFont() async {
    String? selectedPath;
    if (Platform.isWindows) {
      try {
        final res = await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          r'''
Add-Type -AssemblyName System.Windows.Forms
$f = New-Object System.Windows.Forms.OpenFileDialog
$f.Title = "Выберите файл шрифта TTF или OTF"
$f.Filter = "Шрифты TrueType / OpenType (*.ttf;*.otf)|*.ttf;*.otf|Все файлы (*.*)|*.*"
if ($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $f.FileName
}
'''
        ]);
        final path = res.stdout.toString().trim();
        if (path.isNotEmpty && File(path).existsSync()) {
          selectedPath = path;
        }
      } catch (_) {}
    }

    if (selectedPath != null) {
      final success = await ref.read(vpnProvider.notifier).importCustomFont(selectedPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Шрифт успешно импортирован и применен!' : 'Не удалось загрузить файл шрифта'),
          ),
        );
      }
    } else if (mounted) {
      _showManualFontDialog();
    }
  }

  void _showManualFontDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Укажите путь к файлу шрифта'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Путь к .ttf или .otf',
            hintText: 'C:\\Windows\\Fonts\\arial.ttf',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final p = controller.text.trim().replaceAll('"', '');
              if (p.isNotEmpty) {
                final success = await ref.read(vpnProvider.notifier).importCustomFont(p);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Шрифт успешно импортирован и применен!' : 'Файл шрифта не найден или некорректен'),
                    ),
                  );
                }
              }
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
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
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  secondary: const Icon(Icons.dns_rounded),
                  title: const Text('Защищенный DNS (DoH)'),
                  subtitle: const Text('DNS-over-HTTPS Cloudflare (1.1.1.1) и Google (8.8.8.8) через туннель'),
                  value: settings.secureDnsEnabled,
                  onChanged: (val) {
                    ref.read(vpnProvider.notifier).updateSettings(
                          settings.copyWith(secureDnsEnabled: val),
                        );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  secondary: const Icon(Icons.lan_rounded),
                  title: const Text('Обход локальной сети (LAN)'),
                  subtitle: const Text('Прямой доступ к домашним устройствам (192.168.*, 10.*, 172.16.*)'),
                  value: settings.bypassLanEnabled,
                  onChanged: (val) {
                    ref.read(vpnProvider.notifier).updateSettings(
                          settings.copyWith(bypassLanEnabled: val),
                        );
                  },
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
                  trailing: const Icon(Icons.edit_outlined, size: 20),
                  onTap: () => _editStringDialog('URL для пинга', settings.pingUrl, (val) {
                    ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(pingUrl: val));
                  }),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('URL для теста скачивания'),
                  subtitle: Text(settings.speedtestUrl),
                  trailing: const Icon(Icons.edit_outlined, size: 20),
                  onTap: () => _editStringDialog('URL скачивания', settings.speedtestUrl, (val) {
                    ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(speedtestUrl: val));
                  }),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Таймаут пинга (от 1 до 5 секунд)', style: TextStyle(fontWeight: FontWeight.w500)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                            ),
                            child: Text(
                              '${(settings.pingTimeoutMs / 1000).round()} сек (${settings.pingTimeoutMs} мс)',
                              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Slider(
                        value: (settings.pingTimeoutMs / 1000).clamp(1.0, 5.0),
                        min: 1.0,
                        max: 5.0,
                        divisions: 4,
                        label: '${(settings.pingTimeoutMs / 1000).round()} сек.',
                        onChanged: (val) {
                          ref.read(vpnProvider.notifier).updateSettings(
                                settings.copyWith(pingTimeoutMs: val.round() * 1000),
                              );
                        },
                      ),
                    ],
                  ),
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

          _buildSectionHeader('Тема и Пользовательские Шрифты'),
          Card(
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.font_download_outlined),
                  title: const Text('Шрифт интерфейса'),
                  subtitle: Text('Текущий шрифт: ${settings.fontFamily}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.file_open_outlined, size: 16),
                        label: const Text('Импорт (.ttf, .otf)'),
                        onPressed: _pickAndImportFont,
                      ),
                      if (settings.customFontPath != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.restart_alt_rounded),
                          tooltip: 'Сбросить на системный',
                          onPressed: () => ref.read(vpnProvider.notifier).resetDefaultFont(),
                        ),
                      ],
                    ],
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
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildSectionHeader('Подписка и User-Agent'),
          Card(
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                ListTile(
                  title: const Text('User-Agent запроса'),
                  subtitle: Text(settings.userAgent),
                  trailing: DropdownButton<String>(
                    value: _popularUserAgents.contains(settings.userAgent) ? settings.userAgent : 'Custom',
                    underline: const SizedBox(),
                    items: [
                      ..._popularUserAgents.map((ua) => DropdownMenuItem(value: ua, child: Text(ua))),
                      const DropdownMenuItem(value: 'Custom', child: Text('Пользовательский (Ввести свой)...')),
                    ],
                    onChanged: (val) {
                      if (val == 'Custom') {
                        _editStringDialog('Пользовательский User-Agent', settings.userAgent, (customUa) {
                          if (customUa.isNotEmpty) {
                            ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(userAgent: customUa));
                          }
                        });
                      } else if (val != null) {
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
                const Divider(height: 1),
                ListTile(
                  title: const Text('Аппаратный HWID устройства'),
                  subtitle: SelectableText(_hwid, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('О приложении и обновлениях'),
          Card(
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Версия клиента'),
                  subtitle: Text('MaterialVless 2.0 • v (Актуальная версия)'),
                  trailing: _isCheckingUpdate
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : FilledButton.tonalIcon(
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Проверить'),
                          onPressed: () async {
                            setState(() => _isCheckingUpdate = true);
                            final result = await UpdateService.checkDetailedUpdate();
                            setState(() => _isCheckingUpdate = false);
                            if (!mounted) return;
                            if (result.hasUpdate && result.updateInfo != null) {
                              await UpdateService.showUpdateDialog(context, result.updateInfo!);
                            } else if (result.isSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('У вас установлена самая актуальная версия (v2.0.0)'),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result.errorMessage ?? 'Не удалось проверить обновления'),
                                ),
                              );
                            }
                          },
                        ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.open_in_new_rounded, size: 20),
                  title: const Text('Релизы и список изменений'),
                  subtitle: const Text('Открыть официальную страницу на GitHub'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => UpdateService.openUrl('https://github.com/qkryt/MaterialVless/releases'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('Системный трей и завершение работы'),
          Card(
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.power_settings_new_rounded, color: Colors.red),
                  title: const Text('Полностью выйти из приложения', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Отключить VPN, очистить системный прокси и закрыть клиент'),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
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
