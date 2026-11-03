import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/vpn_provider.dart';
import '../../services/hwid_service.dart';
import '../../services/tray_service.dart';
import '../../services/update_service.dart';
import '../../services/custom_font_service.dart';
import '../../services/localization_service.dart';
import '../../services/background_service.dart';
import '../../services/log_service.dart';
import '../../services/ping_service.dart';
import '../theme/app_theme.dart';
import '../widgets/smooth_scroll.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final SmoothScrollController _mainScrollController = SmoothScrollController();
  final SmoothScrollController _pingScrollController = SmoothScrollController();
  final SmoothScrollController _aboutScrollController = SmoothScrollController();

  String _hwid = 'Загрузка...';
  bool _isCheckingUpdate = false;
  bool _isSelectingCustomUa = false;
  late final TextEditingController _customUaController;

  final List<String> _popularUserAgents = const [
    'MaterialVless/3.0',
    'v2rayN/6.42',
    'v2rayN/6.23',
    'Xray/26.10.21',
    'Xray/1.8.24',
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
    _mainScrollController.dispose();
    _pingScrollController.dispose();
    _aboutScrollController.dispose();
    super.dispose();
  }

  Future<void> _pickAndImportFont() async {
    String? selectedPath;
    if (Platform.isWindows) {
      try {
        final script = 'Add-Type -AssemblyName System.Windows.Forms; '
            '$f = New-Object System.Windows.Forms.OpenFileDialog; '
            '$f.Title = "Выберите файл шрифта TTF или OTF"; '
            '$f.Filter = "Шрифты TrueType / OpenType (*.ttf;*.otf)|*.ttf;*.otf|Все файлы (*.*)|*.*"; '
            'if ($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $f.FileName }';
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

  Future<void> _pickBackgroundImage() async {
    final path = await BackgroundService.pickImageFile();
    if (path != null && mounted) {
      final success = await ref.read(vpnProvider.notifier).setBackgroundImage(path);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Фоновое изображение успешно установлено!' : 'Не удалось установить изображение'),
          ),
        );
      }
    }
  }

  Future<void> _removeBackgroundImage() async {
    await ref.read(vpnProvider.notifier).removeBackgroundImage();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Фоновое изображение сброшено на стандартный цвет темы')),
      );
    }
  }

  void _showFeedbackDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.feedback_rounded, color: colorScheme.onPrimaryContainer, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Обратная связь',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Нашли ошибку, узел не подключается или есть идея по улучшению MaterialVless? Напишите напрямую автору!',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                leading: const Icon(Icons.send_rounded, color: Color(0xFF29B6F6)),
                title: const Text('Telegram канал', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Новости и обновления проекта', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () {
                  Navigator.pop(ctx);
                  UpdateService.openUrl('https://t.me/qkryt');
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                leading: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF0088CC)),
                title: const Text('Личный Telegram', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('@qkryt', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () {
                  Navigator.pop(ctx);
                  UpdateService.openUrl('https://t.me/qkryt');
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                leading: const Icon(Icons.bug_report_outlined, color: Colors.orangeAccent),
                title: const Text('GitHub Issues', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Баг-репорты и предложения коду', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () {
                  Navigator.pop(ctx);
                  UpdateService.openUrl('https://github.com/qkryt/MaterialVless/issues');
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showLocalFontsDialog(BuildContext context) async {
    final localFonts = await CustomFontService.listInstalledCustomFonts();
    final settings = ref.read(vpnProvider).settings;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.folder_special_outlined),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Локальные шрифты',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 400),
          child: localFonts.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'В папке customfonts пока нет шрифтов.\nВы можете нажать "+ Импорт (.ttf, .otf)", чтобы добавить шрифт.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: localFonts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (c, idx) {
                    final f = localFonts[idx];
                    final isCurrent = settings.customFontPath == f.path || settings.fontFamily == f.name;

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: Icon(
                        isCurrent ? Icons.check_circle_rounded : Icons.font_download_outlined,
                        color: isCurrent ? Theme.of(context).colorScheme.primary : null,
                      ),
                      title: Text(f.name, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500)),
                      subtitle: Text(
                        f.path,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCurrent)
                            FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await ref.read(vpnProvider.notifier).importCustomFont(f.path);
                              },
                              child: const Text('Применить', style: TextStyle(fontSize: 12)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                            tooltip: 'Удалить файл шрифта',
                            onPressed: () async {
                              await CustomFontService.deleteCustomFont(f.path);
                              if (isCurrent) {
                                await ref.read(vpnProvider.notifier).resetDefaultFont();
                              }
                              Navigator.pop(ctx);
                              _showLocalFontsDialog(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Закрыть')),
        ],
      ),
    );
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

  void _updateAutoStart(bool enabled) async {
    ref.read(vpnProvider.notifier).updateSettings(
          ref.read(vpnProvider).settings.copyWith(autoStartWithWindows: enabled),
        );
    try {
      if (Platform.isWindows) {
        final exePath = Platform.resolvedExecutable;
        if (enabled) {
          await Process.run('reg', [
            'add',
            'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run',
            '/v',
            'MaterialVless',
            '/t',
            'REG_SZ',
            '/d',
            '"$exePath"',
            '/f',
          ]);
        } else {
          await Process.run('reg', [
            'delete',
            'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run',
            '/v',
            'MaterialVless',
            '/f',
          ]);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final vpn = ref.watch(vpnProvider);
    final settings = vpn.settings;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = settings.appLanguage;

    String t(String key) => AppStrings.t(key, lang);

    final cardColor = settings.hasBackgroundImage
        ? colorScheme.surfaceContainer.withOpacity(0.85)
        : colorScheme.surfaceContainer;

    final bgPath = settings.activeBackgroundImagePath;
    final hasBg = settings.hasBackgroundImage && bgPath != null && File(bgPath).existsSync();

    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Scaffold(
        backgroundColor: hasBg ? Colors.black : colorScheme.surface,
        appBar: AppBar(
          backgroundColor: hasBg ? Colors.transparent : null,
          title: Text(t('settings_title')),
          bottom: TabBar(
            isScrollable: false,
            indicatorColor: colorScheme.primary,
            indicatorWeight: 3,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(
                icon: Icon(Icons.tune_rounded),
                text: 'Основные',
              ),
              Tab(
                icon: Icon(Icons.network_ping_rounded),
                text: 'Пинг и задержка',
              ),
              Tab(
                icon: Icon(Icons.favorite_rounded),
                text: 'О программе & Поддержка',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMainTab(context, settings, cardColor, t),
            _buildPingTab(context, settings, cardColor, t),
            _buildAboutTab(context, settings, cardColor, t),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ВКЛАДКА 1: ОСНОВНЫЕ НАСТРОЙКИ
  // ==========================================
  Widget _buildMainTab(BuildContext context, dynamic settings, Color cardColor, String Function(String) t) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isWindows = Platform.isWindows;

    final bool isKnownPreset = _popularUserAgents.contains(settings.userAgent);
    if (!isKnownPreset && _customUaController.text != settings.userAgent && !_customUaController.selection.isValid) {
      _customUaController.text = settings.userAgent;
    }

    return ListView(
      controller: _mainScrollController,
      cacheExtent: 300,
      addRepaintBoundaries: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // 1. ЯДРО VPN (для Desktop)
        if (isWindows) ...[
          _buildSectionHeader('Ядро VPN (Core Engine)'),
          Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.bolt_rounded, color: colorScheme.onPrimaryContainer, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Xray Core v26.10.21 (XTLS)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Полная поддержка Wintun TUN (весь трафик системы), VLESS Reality, Vision, gRPC, WebSocket, TCP, VMess, Trojan, Shadowsocks.',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Активно', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // 2. СЕТЬ И МАРШРУТИЗАЦИЯ
        _buildSectionHeader(t('section_network')),
        Card(
          color: cardColor,
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
                    DropdownMenuItem(value: 'russia', child: Text('Обход сайтов РФ')),
                    DropdownMenuItem(value: 'none', child: Text('Глобальный (Все в VPN)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(routingPreset: val));
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const Icon(Icons.lan_outlined),
                title: Text(t('ip_strategy')),
                subtitle: Text('Стратегия разрешения IP: ${settings.ipStrategy.toUpperCase()}'),
                trailing: DropdownButton<String>(
                  value: settings.ipStrategy,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'auto', child: Text('Auto (IPv4 + IPv6)')),
                    DropdownMenuItem(value: 'ipv4', child: Text('Только IPv4')),
                    DropdownMenuItem(value: 'ipv6', child: Text('Только IPv6')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(ipStrategy: val));
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.dns_rounded),
                title: Text(t('secure_dns')),
                subtitle: const Text('DNS-over-HTTPS (DoH) через Cloudflare / Google для защиты от спуфинга'),
                value: settings.secureDnsEnabled,
                onChanged: (val) {
                  ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(secureDnsEnabled: val));
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.home_work_outlined),
                title: Text(t('bypass_lan')),
                subtitle: const Text('Прямое подключение к домашней/локальной сети (192.168.*, 10.*)'),
                value: settings.bypassLanEnabled,
                onChanged: (val) {
                  ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(bypassLanEnabled: val));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3. ПОДПИСКИ И USER-AGENT
        _buildSectionHeader(t('section_subscription')),
        Card(
          color: cardColor,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t('user_agent'),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Текущий: ${settings.userAgent}',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        DropdownButton<String>(
                          value: isKnownPreset ? settings.userAgent : null,
                          hint: const Text('Выбрать пресет UA'),
                          underline: const SizedBox(),
                          items: _popularUserAgents.map((ua) => DropdownMenuItem(value: ua, child: Text(ua))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              _customUaController.text = val;
                              ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(userAgent: val));
                            }
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Свой UA'),
                          onPressed: () => _editStringDialog('Пользовательский User-Agent', settings.userAgent, (val) {
                            ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(userAgent: val));
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint_rounded),
                title: Text(t('send_hwid')),
                subtitle: Text('Анонимный ID устройства: $_hwid'),
                value: settings.sendHwid,
                onChanged: (val) {
                  ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(sendHwid: val));
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.sync_rounded),
                title: Text(t('auto_update_subs')),
                subtitle: const Text('Автоматически обновлять подписки при запуске программы'),
                value: settings.autoUpdateOnStart,
                onChanged: (val) {
                  ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(autoUpdateOnStart: val));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 4. ОФОРМЛЕНИЕ И ТЕМА (ПОЛНОСТЬЮ АДАПТИВНО — НИКАКИХ СЖАТЫХ СТРОК)
        _buildSectionHeader(t('section_appearance')),
        Card(
          color: cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(themeMode: val));
                    }
                  },
                ),
              ),
              const Divider(height: 1),

              // Акцентный цвет
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Цветовой акцент интерфейса', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _paletteColors.map((item) {
                        final val = item['value'] as int;
                        final c = item['color'] as Color;
                        final isSelected = settings.accentColor == val;
                        return InkWell(
                          onTap: () {
                            ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(accentColor: val));
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: c.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ШРИФТ ИНТЕРФЕЙСА (Адаптивный Wrap — устраняет вертикальное сжатие букв)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.font_download_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t('font_family'),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Текущий шрифт: ${settings.fontFamily}',
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PopupMenuButton<String>(
                          initialValue: settings.fontFamily,
                          onSelected: (val) {
                            ref.read(vpnProvider.notifier).updateSettings(
                                  settings.copyWith(fontFamily: val, customFontPath: null),
                                );
                          },
                          itemBuilder: (context) {
                            final fonts = [
                              'Google Sans',
                              'Roboto',
                              'Inter',
                              'Segoe UI',
                              'Arial',
                              'JetBrains Mono',
                              'Fira Code',
                              'Comfortaa',
                              'Montserrat',
                            ];
                            return fonts.map((f) => PopupMenuItem(
                              value: f,
                              child: Text(f, style: TextStyle(fontFamily: f)),
                            )).toList();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colorScheme.outlineVariant),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  settings.fontFamily,
                                  style: TextStyle(fontWeight: FontWeight.w600, fontFamily: settings.fontFamily, fontSize: 13),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_drop_down, size: 20, color: colorScheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(t('font_import')),
                          onPressed: _pickAndImportFont,
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.folder_special_outlined, size: 16),
                          label: const Text('Локальные шрифты'),
                          onPressed: () => _showLocalFontsDialog(context),
                        ),
                        if (settings.customFontPath != null)
                          IconButton(
                            icon: const Icon(Icons.restart_alt_rounded),
                            tooltip: 'Сбросить на системный шрифт',
                            onPressed: () => ref.read(vpnProvider.notifier).resetDefaultFont(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ФОНОВОЕ ИЗОБРАЖЕНИЕ (Адаптивный Wrap — устраняет вертикальное сжатие "браже ние")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.wallpaper_rounded),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Фоновое изображение',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      settings.hasBackgroundImage
                          ? 'Пользовательский фон (автоподстройка под окно)'
                          : 'Стандартный цвет темы',
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: Text(settings.hasBackgroundImage ? 'Сменить' : 'Выбрать картинку'),
                          onPressed: _pickBackgroundImage,
                        ),
                        if (settings.hasBackgroundImage)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                            label: const Text('Сбросить фон', style: TextStyle(color: Colors.redAccent)),
                            onPressed: _removeBackgroundImage,
                          ),
                      ],
                    ),
                    if (settings.hasBackgroundImage) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.brightness_medium_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Затемнение фона: ${(settings.backgroundDimming * 100).toInt()}%',
                            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      Slider(
                        value: settings.backgroundDimming,
                        min: 0.05,
                        max: 0.85,
                        divisions: 16,
                        label: '${(settings.backgroundDimming * 100).toInt()}%',
                        onChanged: (val) {
                          ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(backgroundDimming: val));
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 5. СИСТЕМНЫЙ ТРЕЙ И ПОВЕДЕНИЕ (Только для Windows Desktop)
        if (isWindows) ...[
          _buildSectionHeader(t('section_system')),
          Card(
            color: cardColor,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.grid_view_rounded),
                  title: Text(t('autostart')),
                  subtitle: Text(t('autostart_desc')),
                  value: settings.autoStartWithWindows,
                  onChanged: (val) => _updateAutoStart(val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.close_fullscreen_rounded),
                  title: Text(t('minimize_to_tray')),
                  subtitle: Text(t('minimize_to_tray_desc')),
                  value: settings.minimizeToTrayOnClose,
                  onChanged: (val) {
                    ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(minimizeToTrayOnClose: val));
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.visibility_off_outlined),
                  title: Text(t('start_minimized')),
                  subtitle: Text(t('start_minimized_desc')),
                  value: settings.startMinimized,
                  onChanged: (val) {
                    ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(startMinimized: val));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  // ==========================================
  // ВКЛАДКА 2: ПИНГ И ЗАДЕРЖКА (ОТДЕЛЬНАЯ ВКЛАДКА)
  // ==========================================
  Widget _buildPingTab(BuildContext context, dynamic settings, Color cardColor, String Function(String) t) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vpn = ref.watch(vpnProvider);

    return ListView(
      controller: _pingScrollController,
      cacheExtent: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // 1. ВЫБОР РЕЖИМА ПИНГА
        _buildSectionHeader('Режим замера пинга (Ping Engine)'),
        Card(
          color: cardColor,
          child: Column(
            children: [
              RadioListTile<String>(
                value: 'proxyGet',
                groupValue: settings.pingMode,
                activeColor: colorScheme.primary,
                title: const Text('via Proxy(GET)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('HTTP GET запрос через туннель прокси к проверочному сайту (честная проверка сквозного доступа в Интернет)'),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(pingMode: val));
                  }
                },
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                value: 'proxyHead',
                groupValue: settings.pingMode,
                activeColor: colorScheme.primary,
                title: const Text('via Proxy(HEAD)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('HTTP HEAD запрос через туннель прокси (быстрый замер только заголовков ответа)'),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(pingMode: val));
                  }
                },
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                value: 'tcp',
                groupValue: settings.pingMode,
                activeColor: colorScheme.primary,
                title: const Text('TCP', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Сетевой 3-way handshake к хосту и порту сервера (нативная сетевая задержка к узлу)'),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(pingMode: val));
                  }
                },
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                value: 'icmp',
                groupValue: settings.pingMode,
                activeColor: colorScheme.primary,
                title: const Text('ICMP', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Системный эхо-запрос ICMP ping к IP/хосту узла (классический системный пинг)'),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(pingMode: val));
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. ФОРМАТ ОТОБРАЖЕНИЯ У СЕРВЕРОВ
        _buildSectionHeader('Формат отображения у серверов'),
        Card(
          color: cardColor,
          child: Column(
            children: [
              RadioListTile<String>(
                value: 'time_ms',
                groupValue: settings.pingDisplayFormat,
                activeColor: colorScheme.primary,
                title: const Text('Time (XXXX ms/icon)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Отображает время задержки в скобках с цветным индикатором качества связи (Рекомендовано)'),
                secondary: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.withOpacity(0.35)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text('Time (85 ms)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(pingDisplayFormat: val));
                  }
                },
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                value: 'ms_only',
                groupValue: settings.pingDisplayFormat,
                activeColor: colorScheme.primary,
                title: const Text('XXXX ms', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Отображает только миллисекунды задержки'),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(pingDisplayFormat: val));
                  }
                },
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                value: 'icon_only',
                groupValue: settings.pingDisplayFormat,
                activeColor: colorScheme.primary,
                title: const Text('Только значок (icon only)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Компактный режим: отображает только цветной значок задержки'),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(pingDisplayFormat: val));
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3. АДРЕСА ДЛЯ ЗАМЕРА
        _buildSectionHeader('Эндпоинты проверки задержки'),
        Card(
          color: cardColor,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.link_rounded),
                title: const Text('URL для проверки пинга'),
                subtitle: Text(settings.pingUrl),
                trailing: const Icon(Icons.edit_outlined, size: 20),
                onTap: () => _editStringDialog('URL для пинга', settings.pingUrl, (val) {
                  ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(pingUrl: val));
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.cloud_queue_rounded, size: 16),
                      label: const Text('Cloudflare 204'),
                      onPressed: () {
                        ref.read(vpnProvider.notifier).updateSettings(
                              settings.copyWith(pingUrl: 'http://cp.cloudflare.com/generate_204'),
                            );
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.public_rounded, size: 16),
                      label: const Text('Google 204'),
                      onPressed: () {
                        ref.read(vpnProvider.notifier).updateSettings(
                              settings.copyWith(pingUrl: 'http://www.google.com/generate_204'),
                            );
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.speed_rounded, size: 16),
                      label: const Text('CacheFly 1MB'),
                      onPressed: () {
                        ref.read(vpnProvider.notifier).updateSettings(
                              settings.copyWith(pingUrl: 'http://cachefly.cachefly.net/1mb.test'),
                            );
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.language_rounded, size: 16),
                      label: const Text('Yandex'),
                      onPressed: () {
                        ref.read(vpnProvider.notifier).updateSettings(
                              settings.copyWith(pingUrl: 'https://ya.ru'),
                            );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.downloading_rounded),
                title: const Text('URL для теста скачивания'),
                subtitle: Text(settings.speedtestUrl),
                trailing: const Icon(Icons.edit_outlined, size: 20),
                onTap: () => _editStringDialog('URL скачивания', settings.speedtestUrl, (val) {
                  ref.read(vpnProvider.notifier).updateSettings(settings.copyWith(speedtestUrl: val));
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 4. ТАЙМАУТ ЗАМЕРА
        _buildSectionHeader('Таймаут замера'),
        Card(
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t('ping_timeout'), style: const TextStyle(fontWeight: FontWeight.w600)),
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
                          settings.copyWith(pingTimeoutMs: (val * 1000).toInt()),
                        );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 5. ДЕЙСТВИЕ: ЗАПУСК ПИНГА ВСЕХ СЕРВЕРОВ
        Card(
          color: colorScheme.primaryContainer.withOpacity(0.4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.flash_on_rounded, color: colorScheme.primary, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Массовый тест серверов', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        'Замерить задержку всех добавленных узлов с текущим режимом (${settings.pingMode})',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: vpn.isTestingPing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(vpn.isTestingPing ? 'Замер...' : 'Запустить'),
                  onPressed: vpn.isTestingPing ? null : () => ref.read(vpnProvider.notifier).pingAllNodes(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ==========================================
  // ВКЛАДКА 3: О ПРОГРАММЕ & ПОДДЕРЖКА (ДОНАТ)
  // ==========================================
  Widget _buildAboutTab(BuildContext context, dynamic settings, Color cardColor, String Function(String) t) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isWindows = Platform.isWindows;

    return ListView(
      controller: _aboutScrollController,
      cacheExtent: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // 1. ПОДДЕРЖАТЬ ПРОЕКТ (ДОНАТ)
        _buildSectionHeader('Поддержка проекта'),
        Card(
          elevation: 2,
          color: colorScheme.surfaceContainerHighest.withOpacity(0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: Border.all(color: Colors.pinkAccent.withOpacity(0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Поддержать развитие MaterialVless',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'DonationAlerts: donationalerts.com/r/qkryt',
                            style: TextStyle(fontSize: 12, color: Colors.pinkAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'MaterialVless создается и поддерживается автором на энтузиазме для быстрого, безопасного и свободного Интернета без цензуры. '
                  'Ваш донат помогает оплачивать тестовые сервера и стимулирует выпуск свежих обновлений!',
                  style: TextStyle(fontSize: 13, height: 1.4, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Center(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.favorite_rounded, size: 20),
                    label: const Text(
                      'Поддержать',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => UpdateService.openUrl('https://www.donationalerts.com/r/qkryt'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. ИНФОРМАЦИЯ О КЛИЕНТЕ
        _buildSectionHeader('Информация о клиенте'),
        Card(
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.shield_rounded, color: colorScheme.onPrimaryContainer, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MaterialVless v3.0',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            'Актуальная версия 3.0.0 (Сборка 30)',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: _isCheckingUpdate
                          ? null
                          : () async {
                              setState(() => _isCheckingUpdate = true);
                              final res = await UpdateService.checkForUpdates();
                              if (mounted) {
                                setState(() => _isCheckingUpdate = false);
                                if (res.hasUpdate && res.updateInfo != null) {
                                  UpdateService.showUpdateDialog(context, res.updateInfo!);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('У вас установлена самая последняя версия 3.0!')),
                                  );
                                }
                              }
                            },
                      child: _isCheckingUpdate
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Проверить'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Современный быстрый клиент для туннелирования трафика на базе официального ядра Xray-core (XTLS) с поддержкой нативного режима Wintun TUN. '
                  'Маршрутизирует 100% сетевого трафика системы (включая Telegram, GitHub, Git CLI, Discord, игры) и поддерживает VLESS (Reality, Vision), Trojan, Shadowsocks, VMess.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoBadge('Xray Core v26.10.21', Icons.bolt_rounded, colorScheme),
                    _buildInfoBadge('Wintun TUN Driver', Icons.shield_rounded, colorScheme),
                    _buildInfoBadge('XTLS / Reality', Icons.security_rounded, colorScheme),
                    _buildInfoBadge('Multi-mode Ping Engine', Icons.network_ping_rounded, colorScheme),
                    _buildInfoBadge('Material Design 3', Icons.palette_outlined, colorScheme),
                    _buildInfoBadge('Windows / Linux / macOS', Icons.devices_rounded, colorScheme),
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
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.bug_report_outlined, size: 16),
                          label: const Text('Сообщить автору'),
                          onPressed: () => _showFeedbackDialog(context),
                        ),
                        if (isWindows)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.description_outlined, size: 16),
                            label: const Text('log.txt'),
                            onPressed: () => LogService.openLogFile(),
                          ),
                        TextButton.icon(
                          icon: const Icon(Icons.code_rounded, size: 16),
                          label: const Text('GitHub'),
                          onPressed: () => UpdateService.openUrl('https://github.com/qkryt/MaterialVless'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 3. АВАРИЙНОЕ ЗАВЕРШЕНИЕ ЯДРА (Только Desktop Windows)
        if (isWindows) ...[
          _buildSectionHeader('Аварийное завершение ядра'),
          Card(
            color: cardColor,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.gpp_bad_rounded, color: Colors.red),
              ),
              title: const Text('Аварийное выключение процессов', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Принудительно останавливает фоновые процессы xray.exe, сбрасывает системный прокси и сетевой адаптер'),
              trailing: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.15),
                  foregroundColor: Colors.red,
                ),
                onPressed: () async {
                  await ref.read(vpnProvider.notifier).emergencyKillAllProcesses();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Все процессы ядра Xray принудительно завершены!')),
                    );
                  }
                },
                child: const Text('Завершить всё'),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // 4. ЗАВЕРШЕНИЕ РАБОТЫ
        _buildSectionHeader('Завершение работы'),
        Card(
          color: cardColor,
          child: ListTile(
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
        ),
        const SizedBox(height: 32),
      ],
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
