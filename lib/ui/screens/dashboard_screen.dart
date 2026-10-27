import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vpn_provider.dart';
import '../../services/xray_service.dart';
import '../../models/vless_node.dart';
import '../../models/subscription_model.dart';
import 'settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vpn = ref.watch(vpnProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Планшеты (Android / iPad) и ПК используют двухколоночный режим (кнопка справа, серверы слева)
    // Телефоны используют вертикальный режим (кнопка сверху, серверы снизу)
    final isTabletOrDesktop = MediaQuery.of(context).size.shortestSide >= 600 || MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('MaterialVless', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Настройки',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28),
            tooltip: 'Добавить подписку или узел',
            onPressed: () => _showAddSubscriptionDialog(context),
          ),
        ],
      ),
      body: isTabletOrDesktop
          // Двухпанельный режим для ПК и планшетов (Android / iPad)
          ? Row(
              children: [
                Expanded(flex: 5, child: _buildSubscriptionsAndServersList(context)),
                VerticalDivider(width: 1, color: colorScheme.outlineVariant.withOpacity(0.4)),
                Expanded(flex: 6, child: _buildPowerControlArea(context, isCompact: false)),
              ],
            )
          // Вертикальный режим для телефонов
          : Column(
              children: [
                if (!vpn.hideEverything)
                  _buildPowerControlArea(context, isCompact: true),
                Expanded(child: _buildSubscriptionsAndServersList(context)),
              ],
            ),
    );
  }

  // ==================== БЛОК ПОДКЛЮЧЕНИЯ И ТАЙМЕРА ====================
  Widget _buildPowerControlArea(BuildContext context, {required bool isCompact}) {
    final vpn = ref.watch(vpnProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnected = vpn.status == CoreState.connected;
    final isConnecting = vpn.status == CoreState.connecting;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: isCompact ? 12 : 24),
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

          // Круглая кнопка подключения со светящейся аурой
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final scale = isConnected ? _pulseAnimation.value : 1.0;
                final size = isCompact ? 150.0 : 210.0;
                return Transform.scale(
                  scale: scale,
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
                            color: (isConnected ? colorScheme.primary : colorScheme.outlineVariant).withOpacity(0.4),
                            blurRadius: isConnected ? 36 : 14,
                            spreadRadius: isConnected ? 8 : 2,
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
                                    size: isCompact ? 48 : 72,
                                    color: isConnected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                                  ),
                                  if (isConnected) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'CONNECTED',
                                      style: TextStyle(
                                        color: colorScheme.onPrimary,
                                        fontSize: isCompact ? 10 : 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    Text(
                                      vpn.formattedTimer,
                                      style: TextStyle(
                                        color: colorScheme.onPrimary.withOpacity(0.9),
                                        fontSize: isCompact ? 12 : 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Строка пинга и кнопки "Hide everything"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isConnected ? '${vpn.currentPingMs} ms' : 'Отключено',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                TextButton(
                  onPressed: () => ref.read(vpnProvider.notifier).toggleHideEverything(),
                  child: Text(
                    vpn.hideEverything ? 'Показать всё' : 'Hide everything',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),

          if (!isCompact) ...[
            const Spacer(),
            if (vpn.selectedNode != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFlagIcon(vpn.selectedNode!.remark),
                  const SizedBox(width: 8),
                  Text(
                    vpn.selectedNode!.remark,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: 200,
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
                    : const Text('Тест пинга', style: TextStyle(fontWeight: FontWeight.bold)),
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
              Icon(Icons.cloud_off_rounded, size: 56, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Подписок пока нет\nНажмите + вверху, чтобы добавить подписку или ссылку',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      children: [
        // Каждая подписка — это отдельная сущность и сворачиваемая вкладка
        for (final sub in vpn.subscriptions) ...[
          _buildCollapsibleSubscriptionContainer(context, sub),
          const SizedBox(height: 14),
        ],

        // Секция ручных ссылок (если добавлены без подписки)
        if (vpn.manualNodes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              'Отдельные узлы',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          for (final node in vpn.manualNodes) _buildServerTile(context, node),
        ],
      ],
    );
  }

  Widget _buildCollapsibleSubscriptionContainer(BuildContext context, SubscriptionModel sub) {
    final vpn = ref.watch(vpnProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Шапка подписки (клик сворачивает / разворачивает)
          InkWell(
            onTap: () => ref.read(vpnProvider.notifier).toggleSubscriptionExpanded(sub.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Иконка сворачивания (стрелка вниз или вправо)
                      Icon(
                        sub.isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              sub.name,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6),
                            const Text('💥', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Обновить подписку',
                        onPressed: () => ref.read(vpnProvider.notifier).refreshSubscription(sub.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.speed_rounded, size: 20),
                        tooltip: 'Пинг серверов',
                        onPressed: () => ref.read(vpnProvider.notifier).pingAllNodes(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz_rounded, size: 20),
                        tooltip: 'Опции',
                        onPressed: () {},
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 34.0),
                    child: Text(
                      '${sub.lastUpdated.day}.${sub.lastUpdated.month}.${sub.lastUpdated.year} | Автообновление • 2ч. ⭐',
                      style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Полоса израсходованного трафика (как на скриншоте 1)
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
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: sub.usedPercentage,
                                    child: Container(
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      '${SubscriptionModel.formatBytes(sub.usedBytes)} / ${sub.totalBytes > 0 ? SubscriptionModel.formatBytes(sub.totalBytes) : '∞'}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (sub.expireDate != null)
                              Text(
                                'Истекает: ${sub.expireDate!.day}.${sub.expireDate!.month}.${sub.expireDate!.year}',
                                style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Список серверов внутри подписки (скрывается если свернуто)
          if (sub.isExpanded) ...[
            const Divider(height: 1),
            for (final node in sub.nodes) _buildServerTile(context, node),
          ],
        ],
      ),
    );
  }

  Widget _buildServerTile(BuildContext context, VlessNode node) {
    final vpn = ref.watch(vpnProvider);
    final isSelected = vpn.selectedNode?.id == node.id;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: isSelected ? colorScheme.secondaryContainer.withOpacity(0.4) : Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: _buildFlagIcon(node.remark),
        title: Row(
          children: [
            Expanded(
              child: Text(
                node.remark,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Text('⚡', style: TextStyle(fontSize: 14)),
          ],
        ),
        subtitle: Text(
          '${node.protocol.name.toUpperCase()} / ${node.streamType.toUpperCase()} / ${node.security.toUpperCase()} / JSON',
          style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: node.pingMs != null
            ? Container(
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
            : Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant, size: 20),
        onTap: () => ref.read(vpnProvider.notifier).selectNode(node),
      ),
    );
  }

  Widget _buildFlagIcon(String title) {
    final lower = title.toLowerCase();
    String flag = '🌐';
    if (lower.contains('германия') || lower.contains('germany') || lower.contains('frankfurt')) flag = '🇩🇪';
    if (lower.contains('австрия') || lower.contains('вена') || lower.contains('vienna')) flag = '🇦🇹';
    if (lower.contains('нидерланды') || lower.contains('амстердам')) flag = '🇳🇱';
    if (lower.contains('польша') || lower.contains('варшава')) flag = '🇵🇱';
    if (lower.contains('россия') || lower.contains('петербург') || lower.contains('москва')) flag = '🇷🇺';
    if (lower.contains('литва') || lower.contains('вильнюс')) flag = '🇱🇹';
    if (lower.contains('сша') || lower.contains('usa') || lower.contains('йорк')) flag = '🇺🇸';
    if (lower.contains('финляндия') || lower.contains('helsinki')) flag = '🇫🇮';
    if (lower.contains('автоматический') || lower.contains('auto') || lower.contains('trusted') || lower.contains('доверенных')) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: const Center(child: Icon(Icons.public_rounded, color: Colors.blue, size: 20)),
      );
    }

    return Text(flag, style: const TextStyle(fontSize: 24));
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
            hintText: 'Вставьте ссылку подписки, прямую ссылку vless:// или путь к .txt файлу',
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
