import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vpn_provider.dart';
import '../../services/xray_service.dart';
import '../../models/vless_node.dart';
import '../../models/subscription_model.dart';
import '../../utils/country_flag_helper.dart';
import '../widgets/logo.dart';
import '../widgets/country_flag_widget.dart';
import 'settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vpn = ref.watch(vpnProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isWide = MediaQuery.of(context).size.width >= 780;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 14),
            const MaterialVlessLogo(size: 26),
            const SizedBox(width: 10),
            const Text('MaterialVless', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.speed_rounded),
            tooltip: 'Проверить пинг всех серверов',
            onPressed: vpn.isTestingPing
                ? null
                : () => ref.read(vpnProvider.notifier).pingAllNodes(),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 26),
            tooltip: 'Добавить подписку или узел',
            onPressed: () => _showAddSubscriptionDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Настройки',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                Expanded(flex: 5, child: _buildSubscriptionsAndServersList(context)),
                VerticalDivider(width: 1, color: colorScheme.outlineVariant.withOpacity(0.3)),
                Expanded(flex: 5, child: _buildPowerControlArea(context, isCompact: false)),
              ],
            )
          : Column(
              children: [
                _buildPowerControlArea(context, isCompact: true),
                Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.3)),
                Expanded(child: _buildSubscriptionsAndServersList(context)),
              ],
            ),
    );
  }

  // ==================== БЛОК ПОДКЛЮЧЕНИЯ И ТАЙМЕРА (БЕЗ АНИМАЦИИ) ====================
  Widget _buildPowerControlArea(BuildContext context, {required bool isCompact}) {
    final vpn = ref.watch(vpnProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnected = vpn.status == CoreState.connected;
    final isConnecting = vpn.status == CoreState.connecting;
    final size = isCompact ? 144.0 : 190.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: isCompact ? 16 : 28),
      color: colorScheme.surface,
      child: Column(
        mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (!isCompact) ...[
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text('Защита (TUN + Прокси)', style: theme.textTheme.labelMedium),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],

          // Статичная, четкая круглая кнопка включения в дизайне Material You
          Center(
            child: GestureDetector(
              onTap: () => ref.read(vpnProvider.notifier).toggleConnection(),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                  boxShadow: [
                    BoxShadow(
                      color: (isConnected ? colorScheme.primary : colorScheme.outlineVariant).withOpacity(0.3),
                      blurRadius: isConnected ? 28 : 10,
                      spreadRadius: isConnected ? 4 : 1,
                    ),
                  ],
                ),
                child: Center(
                  child: isConnecting
                      ? CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 4)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.power_settings_new_rounded,
                              size: isCompact ? 46 : 64,
                              color: isConnected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isConnected ? 'ПОДКЛЮЧЕНО' : 'ПОДКЛЮЧИТЬ',
                              style: TextStyle(
                                color: isConnected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                                fontSize: isCompact ? 11 : 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            if (isConnected) ...[
                              const SizedBox(height: 4),
                              Text(
                                vpn.formattedTimer,
                                style: TextStyle(
                                  color: colorScheme.onPrimary.withOpacity(0.95),
                                  fontSize: isCompact ? 13 : 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Карточка выбранного сервера под кнопкой с аутентичным флагом
          if (vpn.selectedNode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CountryFlagWidget(
                    isoCode: CountryFlagHelper.getCountryCode(vpn.selectedNode!.remark),
                    width: 28,
                    height: 19,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CountryFlagHelper.cleanRemark(vpn.selectedNode!.remark),
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${vpn.selectedNode!.protocol.name.toUpperCase()} • ${vpn.selectedNode!.streamType.toUpperCase()}',
                          style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (vpn.selectedNode!.pingMs != null && vpn.selectedNode!.pingMs! > 0) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${vpn.selectedNode!.pingMs} ms',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            Text(
              'Выберите сервер для подключения',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),

          if (!isCompact) ...[
            const Spacer(),
            SizedBox(
              width: 220,
              height: 44,
              child: FilledButton.tonal(
                onPressed: vpn.isTestingPing
                    ? null
                    : () {
                        ref.read(vpnProvider.notifier).pingAllNodes();
                      },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: vpn.isTestingPing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.speed_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Тест всех серверов', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  // ==================== СПИСОК ПОДПИСОК (ОТДЕЛЬНЫЕ СВОРАЧИВАЕМЫЕ ВКЛАДКИ) ====================
  Widget _buildSubscriptionsAndServersList(BuildContext context) {
    final vpn = ref.watch(vpnProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (vpn.subscriptions.isEmpty && vpn.manualNodes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 52, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Подписок пока нет\nНажмите + в правом верхнем углу, чтобы добавить подписку или ссылку',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      children: [
        for (final sub in vpn.subscriptions) ...[
          _buildCollapsibleSubscriptionContainer(context, sub),
          const SizedBox(height: 14),
        ],

        if (vpn.manualNodes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Отдельные серверы (${vpn.manualNodes.length})',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          for (final node in vpn.manualNodes)
            _buildServerTile(context, node, canDelete: true),
        ],
      ],
    );
  }

  Widget _buildCollapsibleSubscriptionContainer(BuildContext context, SubscriptionModel sub) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dateStr = '${sub.lastUpdated.day.toString().padLeft(2, '0')}.${sub.lastUpdated.month.toString().padLeft(2, '0')}.${sub.lastUpdated.year} '
        '${sub.lastUpdated.hour.toString().padLeft(2, '0')}:${sub.lastUpdated.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => ref.read(vpnProvider.notifier).toggleSubscriptionExpanded(sub.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        sub.isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sub.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Обновить подписку',
                        onPressed: () => ref.read(vpnProvider.notifier).refreshSubscription(sub.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.speed_rounded, size: 20),
                        tooltip: 'Пинг серверов в подписке',
                        onPressed: () => ref.read(vpnProvider.notifier).pingAllNodes(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        tooltip: 'Настройки подписки',
                        onPressed: () => _showSubscriptionOptionsDialog(context, sub),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 34.0),
                    child: Text(
                      'Обновлено: $dateStr • ${sub.autoUpdate ? 'Автообновление каждые ${sub.autoUpdateIntervalHours} ч.' : 'Автообновление выкл.'}',
                      style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 34.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: sub.usedPercentage,
                                    child: Container(
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withOpacity(0.55),
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      '${SubscriptionModel.formatBytes(sub.usedBytes)} / ${sub.totalBytes > 0 ? SubscriptionModel.formatBytes(sub.totalBytes) : '∞'}',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (sub.expireDate != null) ...[
                              const SizedBox(width: 10),
                              Text(
                                'Истекает: ${sub.expireDate!.day}.${sub.expireDate!.month}.${sub.expireDate!.year}',
                                style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (sub.isExpanded) ...[
            const Divider(height: 1),
            for (final node in sub.nodes)
              _buildServerTile(context, node),
          ],
        ],
      ),
    );
  }

  Widget _buildServerTile(BuildContext context, VlessNode node, {bool canDelete = false}) {
    final vpn = ref.watch(vpnProvider);
    final isSelected = vpn.selectedNode?.id == node.id;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: isSelected ? colorScheme.secondaryContainer.withOpacity(0.35) : Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withOpacity(0.12) : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: CountryFlagWidget(
            isoCode: CountryFlagHelper.getCountryCode(node.remark),
            width: 26,
            height: 18,
          ),
        ),
        title: Text(
          CountryFlagHelper.cleanRemark(node.remark),
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${node.protocol.name.toUpperCase()} / ${node.streamType.toUpperCase()} / ${node.security.toUpperCase()}',
          style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (node.pingMs != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: node.pingMs! > 0 ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  node.pingMs! > 0 ? '${node.pingMs} ms' : 'Timeout',
                  style: TextStyle(
                    color: node.pingMs! > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            else
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: 20,
              ),
            if (canDelete) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Удалить узел',
                onPressed: () => ref.read(vpnProvider.notifier).deleteManualNode(node.id),
              ),
            ],
          ],
        ),
        onTap: () => ref.read(vpnProvider.notifier).selectNode(node),
      ),
    );
  }

  // ==================== ДИАЛОГ НАСТРОЕК ПОДПИСКИ ====================
  void _showSubscriptionOptionsDialog(BuildContext context, SubscriptionModel sub) {
    int selectedInterval = sub.autoUpdateIntervalHours;
    bool autoUpdate = sub.autoUpdate;
    final nameController = TextEditingController(text: sub.name);

    final dateStr = '${sub.lastUpdated.day.toString().padLeft(2, '0')}.${sub.lastUpdated.month.toString().padLeft(2, '0')}.${sub.lastUpdated.year} '
        '${sub.lastUpdated.hour.toString().padLeft(2, '0')}:${sub.lastUpdated.minute.toString().padLeft(2, '0')}:${sub.lastUpdated.second.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Опции подписки'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название подписки',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Последнее обновление из файла:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Автообновление'),
                  subtitle: const Text('Периодически загружать свежие узлы'),
                  value: autoUpdate,
                  onChanged: (val) {
                    setDialogState(() => autoUpdate = val);
                  },
                ),
                if (autoUpdate) ...[
                  const SizedBox(height: 8),
                  const Text('Интервал обновления:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [1, 2, 6, 12, 24].map((hours) {
                      final isSel = selectedInterval == hours;
                      return ChoiceChip(
                        label: Text('$hours ч.'),
                        selected: isSel,
                        onSelected: (sel) {
                          if (sel) setDialogState(() => selectedInterval = hours);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _confirmDeleteSubscription(context, sub);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Удалить'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(vpnProvider.notifier).updateSubscriptionOptions(
                      sub.id,
                      intervalHours: selectedInterval,
                      autoUpdate: autoUpdate,
                      customName: nameController.text.trim().isNotEmpty ? nameController.text.trim() : null,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSubscription(BuildContext context, SubscriptionModel sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить подписку?'),
        content: Text('Вы действительно хотите удалить подписку "${sub.name}" и все её серверы?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              ref.read(vpnProvider.notifier).deleteSubscription(sub.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showAddSubscriptionDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить подписку или узел'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Вставьте ссылку подписки, прямую ссылку vless://, ss://, hy2:// или путь к .txt файлу',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                ref.read(vpnProvider.notifier).addSubscription(text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }
}
