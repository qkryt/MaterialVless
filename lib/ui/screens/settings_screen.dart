import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vpn_provider.dart';
import '../../services/hwid_service.dart';
import '../../services/tray_service.dart';
import '../../services/update_service.dart';
import '../../services/localization_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _hwid = 'Загрузка...';
  bool _isCheckingUpdate = false;
  bool _isSelectingCustomUa = false;
  late final TextEditingController _customUaController;

  final List<String> _popularUserAgents = const [
    'MaterialVless/2.12',
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
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/130.0.0.0',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:132.0) Firefox/132.0',
  ];

  static const List<Map<String, dynamic>> _paletteColors = [
    {'name': 'Deep Purple', 'value': 0xFF6750A4, 'color': Color(0xFF6750A4)},
    {'name': 'Electric Blue', 'value': 0xFF1E88E5, 'color': Color(0xFF1E88E5)},
    {'name': 'Emerald Teal', 'value': 0xFF00897B, 'color': Color(0xFF00897B)},
    {'name': 'Forest Green', 'value': 0xFF2E7D32, 'color': Color(0xFF2E7D32)},
    {'name': 'Sunset Orange', 'value': 0xFFF57C00, 'color': Color(0xFFF57C00)},
    {'name': 'Ruby Crimson', 'value': 0xFFD32F2F, 'color': Color(0xFFD32F2F)},
    {'name': 'Cyber Pink', 'value': 0xFFE91E63, 'color': Color(0xFFE91E63)},
    {'name': 'Graphite Slate', 'value': 0xFF546E7A, 'color': Color(0xFF546E7A)},
  ];

  @override
  void initState() {
    super.initState();
    _customUaController = TextEditingController();
    HwidService.getHWID().then((val) {
      if (mounted) setState(() => _hwid = val);
    });
  }

  @override
  void dispose() {
    _customUaController.dispose();
    super.dispose();
  }

  Future<void> _pickAndImportFont() async {
    String? selectedPath;
    if (Platform.isWindows) {
      try {
        final script = 'Add-Type -AssemblyName System.Windows.Forms; '
            '\$f = New-Object System.Windows.Forms.OpenFileDialog; '
            '\$f.Title = "Выберите файл шрифта TTF или OTF"; '
            '\$f.Filter = "Шрифты TrueType / OpenType (*.ttf;*.otf)|*.ttf;*.otf|Все файлы (*.*)|*.*"; '
            'if (\$f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { \$f.FileName }';
        final res = await Process.run('powershell', ['-NoProfile', '-Command', script]);
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

  void _updateAutoStart(bool enable) {
    if (Platform.isWindows) {
      try {
        final exePath = Platform.resolvedExecutable;
        if (enable) {
          Process.run('reg', ['add', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run', '/v', 'MaterialVless', '/t', 'REG_SZ', '/d', '"$exePath"', '/f']);
        } else {
          Process.run('reg', ['delete', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run', '/v', 'MaterialVless', '/f']);
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final vpn = ref.watch(vpnProvider);
    final settings = vpn.settings;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = settings.appLanguage;

    String t(String key) => AppStrings.t(key, lang);

    final bool isKnownPreset = _popularUserAgents.contains(settings.userAgent);
    final bool showCustomInput = !isKnownPreset || _isSelectingCustomUa;
    if (!isKnownPreset && _customUaController.text != settings.userAgent && !_customUaController.selection.isValid) {
      _customUaController.text = settings.userAgent;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('settings_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ==================== СЕТЬ И МАРШРУТИЗАЦИЯ ====================
          _buildSectionHeader(t('section_network')),
          Card(
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.alt_route_rounded),
                  title: Text(t('routing_preset')),
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
                  leading: const Icon(Icons.public_rounded),
                  title: Text(t('ip_strategy_title')),
                  subtitle: Text(
                    settings.ipStrategy == 'ipv4'
                        ? 'IPv4 Only (Только адреса IPv4)'
                        : settings.ipStrategy == 'ipv6'
                            ? 'IPv6 Preferred (Приоритет IPv6)'
                            : 'Auto (Автоматический выбор IPv4 / IPv6)',
                  ),
                  trailing: DropdownButton<String>(
                    value: settings.ipStrategy,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(
                        value: 'auto',
                        child: Text(t('ip_strategy_auto')),
                      ),
                      DropdownMenuItem(
                        value: 'ipv4',
                        child: Text(t('ip_strategy_ipv4')),
                      ),
                      DropdownMenuItem(
                        value: 'ipv6',
                        child: Text(t('ip_strategy_ipv6')),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(vpnProvider.notifier).updateSettings(
                              settings.copyWith(ipStrategy: val),
                            );
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  secondary: const Icon(Icons.dns_rounded),
                  title: Text(t('secure_dns')),
                  subtitle: Text(t('secure_dns_desc')),
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
                  title: Text(t('bypass_lan')),
                  subtitle: Text(t('bypass_lan_desc')),
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

          // ==================== ВНЕШНИЙ ВИД И MATERIAL YOU ====================
          _buildSectionHeader(t('section_appearance')),
          Card(
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(t('language_title')),
                  subtitle: Text(lang == 'en' ? 'English' : 'Русский'),
                  trailing: DropdownButton<String>(
                    value: lang,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'ru', child: Text('🇷🇺 Русский')),
                      DropdownMenuItem(value: 'en', child: Text('🇬🇧 English')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(vpnProvider.notifier).updateSettings(
                              settings.copyWith(appLanguage: val),
                            );
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.palette_outlined, size: 20),
                          const SizedBox(width: 12),
                          Text(t('color_theme'), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: _paletteColors.map((item) {
                          final int val = item['value'] as int;
                          final Color color = item['color'] as Color;
                          final String name = item['name'] as String;
                          final bool isSelected = settings.accentColor == val && !settings.useDynamicColor;

                          return Tooltip(
                            message: name,
                            child: InkWell(
                              onTap: () {
                                ref.read(vpnProvider.notifier).updateSettings(
                                      settings.copyWith(
                                        accentColor: val,
                                        useDynamicColor: false,
                                      ),
                                    );
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? colorScheme.onSurface : Colors.transparent,
                                    width: isSelected ? 3 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withOpacity(0.4),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white, size: 22)
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.font_download_outlined),
                  title: Text(t('font_title')),
                  subtitle: Text('Текущий шрифт: ${settings.fontFamily}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<String>(
                        value: AppTheme.builtInFonts.contains(settings.fontFamily)
                            ? settings.fontFamily
                            : null,
                        hint: const Text('Шрифт'),
                        underline: const SizedBox(),
                        items: AppTheme.builtInFonts
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(vpnProvider.notifier).updateSettings(
                                  settings.copyWith(fontFamily: val, customFontPath: null),
                                );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.file_open_outlined, size: 16),
                        label: Text(t('font_import')),
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
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: Text(t('theme_mode')),
                  subtitle: Text(settings.themeMode.toUpperCase()),
                  trailing: DropdownButton<String>(
                    value: settings.themeMode,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(value: 'system', child: Text(t('theme_system'))),
                      DropdownMenuItem(value: 'light', child: Text(t('theme_light'))),
                      DropdownMenuItem(value: 'dark', child: Text(t('theme_dark'))),
                      DropdownMenuItem(value: 'amoled', child: Text(t('theme_amoled'))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(vpnProvider.notifier).updateSettings(
                              settings.copyWith(themeMode: val),
                            );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ==================== СИСТЕМНЫЙ ТРЕЙ И ПОВЕДЕНИЕ ====================
          _buildSectionHeader(t('section_system')),
          Card(
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.window_rounded),
                  title: Text(t('autostart')),
                  subtitle: const Text('Автоматический запуск программы при входе в Windows'),
                  value: settings.autoStartWithWindows,
                  onChanged: (val) {
                    ref.read(vpnProvider.notifier).updateSettings(
                          settings.copyWith(autoStartWithWindows: val),
                        );
                    _updateAutoStart(val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.close_fullscreen_rounded),
                  title: Text(t('minimize_to_tray')),
                  subtitle: const Text('При нажатии на крестик окно скрывается в область уведомлений'),
                  value: settings.minimizeToTrayOnClose,
                  onChanged: (val) {
                    ref.read(vpnProvider.notifier).updateSettings(
                          settings.copyWith(minimizeToTrayOnClose: val),
                        );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.visibility_off_outlined),
                  title: const Text('Запускать свёрнутым в трей'),
                  subtitle: const Text('Не показывать главное окно при автозагрузке или старте'),
                  value: settings.startMinimized,
                  onChanged: (val) {
                    ref.read(vpnProvider.notifier).updateSettings(
                          settings.copyWith(startMinimized: val),
                        );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ==================== ПИНГ И ЗАДЕРЖКА ====================
          _buildSectionHeader(t('section_ping')),
          Card(
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                ListTile(
                  title: Text(t('ping_url')),
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
                          Text(t('ping_timeout'), style: const TextStyle(fontWeight: FontWeight.w500)),
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
                  title: Text(t('ping_proxy')),
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

          // ==================== ПОДПИСКА И USER-AGENT ====================
          _buildSectionHeader('Подписка и User-Agent'),
          Card(
            color: colorScheme.surfaceContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: const Text('Глобальный User-Agent'),
                  subtitle: Text(settings.userAgent),
                  trailing: DropdownButton<String>(
                    value: (!isKnownPreset || _isSelectingCustomUa) ? 'Custom' : settings.userAgent,
                    underline: const SizedBox(),
                    items: [
                      ..._popularUserAgents.map((ua) => DropdownMenuItem(value: ua, child: Text(ua))),
                      const DropdownMenuItem(value: 'Custom', child: Text('Пользовательский (Ввести свой)...')),
                    ],
                    onChanged: (val) {
                      if (val == 'Custom') {
                        setState(() {
                          _isSelectingCustomUa = true;
                          _customUaController.text = !isKnownPreset ? settings.userAgent : '';
                        });
                      } else if (val != null) {
                        setState(() => _isSelectingCustomUa = false);
                        ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(userAgent: val));
                      }
                    },
                  ),
                ),
                if (showCustomInput) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _customUaController,
                      decoration: InputDecoration(
                        labelText: 'Пользовательский User-Agent',
                        hintText: 'Например: MyCustomClient/1.0',
                        prefixIcon: const Icon(Icons.edit_note_rounded),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          tooltip: 'Применить',
                          onPressed: () {
                            final customUa = _customUaController.text.trim();
                            if (customUa.isNotEmpty) {
                              ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(userAgent: customUa));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Пользовательский User-Agent применен')),
                              );
                            }
                          },
                        ),
                      ),
                      onChanged: (val) {
                        final clean = val.trim();
                        if (clean.isNotEmpty) {
                          ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(userAgent: clean));
                        }
                      },
                    ),
                  ),
                ],
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
                  trailing: IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    tooltip: 'Скопировать HWID',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _hwid));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('HWID скопирован в буфер обмена')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ==================== ОБНОВЛЕНИЯ ====================
          _buildSectionHeader(t('section_about')),
          Card(
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.system_update_rounded),
                  title: Text(t('client_version')),
                  subtitle: const Text('MaterialVless 2.12 • Патч 2.12 (v2.12.0)'),
                  trailing: _isCheckingUpdate
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : FilledButton.tonalIcon(
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: Text(t('check_btn')),
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
                                  content: Text('У вас установлена самая актуальная версия (v2.12.0)'),
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
                  leading: const Icon(Icons.download_rounded),
                  title: Text(t('download_installer')),
                  subtitle: const Text('Загрузить и обновить клиент автоматически'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () async {
                    setState(() => _isCheckingUpdate = true);
                    final result = await UpdateService.checkDetailedUpdate();
                    setState(() => _isCheckingUpdate = false);
                    if (!mounted) return;
                    if (result.updateInfo != null && result.updateInfo!.setupDownloadUrl != null) {
                      await UpdateService.downloadAndLaunchInstaller(
                        context,
                        result.updateInfo!.setupDownloadUrl!,
                      );
                    } else {
                      UpdateService.openUrl('https://github.com/qkryt/MaterialVless/releases/latest');
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.open_in_new_rounded, size: 20),
                  title: Text(t('open_releases')),
                  subtitle: const Text('Открыть страницу релизов на GitHub'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => UpdateService.openUrl('https://github.com/qkryt/MaterialVless/releases'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ==================== О ПРОГРАММЕ (ABOUT) ====================
          _buildSectionHeader('Информация о программе'),
          Card(
            color: colorScheme.surfaceContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.vpn_lock_rounded,
                          color: colorScheme.onPrimaryContainer,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MaterialVless',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Версия 2.12.0 • Патч 2.12 (Выпуск 2026)',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Современный быстрый клиент для туннелирования трафика на базе Sing-box и драйвера Wintun. '
                    'Поддерживает протоколы VLESS, Trojan, Shadowsocks, Hysteria2 и передовые протокольные схемы deep-linking.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoBadge('Sing-box v1.14.4', Icons.bolt_rounded, colorScheme),
                      _buildInfoBadge('Wintun v0.14.1', Icons.shield_outlined, colorScheme),
                      _buildInfoBadge('Material Design 3', Icons.palette_outlined, colorScheme),
                      _buildInfoBadge('Windows x64 Native', Icons.laptop_windows_rounded, colorScheme),
                      _buildInfoBadge('Deep Link: material:// & happ://', Icons.link_rounded, colorScheme),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Разработчик: qkryt • Лицензия MIT',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.code_rounded, size: 16),
                        label: const Text('GitHub Repo'),
                        onPressed: () => UpdateService.openUrl('https://github.com/qkryt/MaterialVless'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ==================== ЗАВЕРШЕНИЕ РАБОТЫ ====================
          _buildSectionHeader('Завершение работы'),
          Card(
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.power_settings_new_rounded, color: Colors.red),
                  title: Text(t('exit_app'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  subtitle: Text(t('exit_app_desc')),
                  trailing: FilledButton.tonal(
                    style: FilledButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () async {
                      await ref.read(vpnProvider.notifier).exitApp();
                      await TrayService.instance.cleanUpAndExit();
                    },
                    child: Text(t('exit_app')),
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

  Widget _buildInfoBadge(String label, IconData icon, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
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
