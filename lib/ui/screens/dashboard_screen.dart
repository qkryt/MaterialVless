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
    final isWide = MediaQuery.of(context).size.width > 750;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MaterialVless', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Настройки',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                Expanded(flex: 5, child: _buildServersListPane(context)),
                VerticalDivider(width: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
                Expanded(flex: 6, child: _buildConnectionControlPane(context)),
              ],
            )
          : Column(
              children: [
                Expanded(flex: 6, child: _buildConnectionControlPane(context)),
                const Divider(height: 1),
                Expanded(flex: 5, child: _buildServersListPane(context)),
              ],
            ),
    );
  }

  Widget _buildServersListPane(BuildContext context) {
    final vpn = ref.watch(vpnProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Серверы',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_link_rounded),
                  tooltip: 'Добавить подписку или узел (.txt / URL)',
                  onPressed: () => _showAddSubscriptionDialog(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Введите текст для поиска',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => ref.read(vpnProvider.notifier).setSearchQuery(val),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (final sub in vpn.subscriptions) ...[
                  _buildSubscriptionCard(context, sub),
                  const SizedBox(height: 12),
                ],
                if (vpn.filteredNodes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.cloud_off_rounded, size: 48, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(
                            'Список узлов пуст\nНажмите + чтобы добавить подписку или ссылку',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final node in vpn.filteredNodes) _buildServerTile(context, node),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, SubscriptionModel sub) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(sub.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Обновить подписку',
                  onPressed: () => ref.read(vpnProvider.notifier).refreshSubscription(sub.id),
                ),
                IconButton(
                  icon: const Icon(Icons.bolt_rounded, size: 20),
                  tooltip: 'Пинг всех серверов',
                  onPressed: () => ref.read(vpnProvider.notifier).pingAllNodes(),
                ),
              ],
            ),
            Text(
              'Автообновление • ${SubscriptionModel.formatBytes(sub.usedBytes)} / ${SubscriptionModel.formatBytes(sub.totalBytes)}',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: sub.usedPercentage,
              borderRadius: BorderRadius.circular(6),
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
            if (sub.expireDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  'Истекает: ${sub.expireDate!.day}.${sub.expireDate!.month}.${sub.expireDate!.year}',
                  style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerTile(BuildContext context, VlessNode node) {
    final vpn = ref.watch(vpnProvider);
    final isSelected = vpn.selectedNode?.id == node.id;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: isSelected ? colorScheme.secondaryContainer : colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Text(_getCountryFlag(node.remark), style: const TextStyle(fontSize: 22)),
        title: Text(
          node.remark,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${node.protocol.name.toUpperCase()} • ${node.streamType.toUpperCase()} • ${node.security.toUpperCase()}',
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
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
            : const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: () => ref.read(vpnProvider.notifier).selectNode(node),
      ),
    );
  }

  Widget _buildConnectionControlPane(BuildContext context) {
    final vpn = ref.watch(vpnProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnected = vpn.status == CoreState.connected;
    final isConnecting = vpn.status == CoreState.connecting;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
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
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = isConnected ? _pulseAnimation.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: () => ref.read(vpnProvider.notifier).toggleConnection(),
                  child: Container(
                    width: 210,
                    height: 210,
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
                          : Icon(
                              Icons.power_settings_new_rounded,
                              size: 88,
                              color: isConnected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            isConnecting ? 'Подключение к защищенной сети...' : isConnected ? 'Подключено' : 'Отключено',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isConnected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (vpn.selectedNode != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_getCountryFlag(vpn.selectedNode!.remark), style: const TextStyle(fontSize: 22)),
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
      ),
    );
  }

  String _getCountryFlag(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('вена') || lower.contains('австрия') || lower.contains('vienna')) return '🇦🇹';
    if (lower.contains('франкфурт') || lower.contains('германия') || lower.contains('germany')) return '🇩🇪';
    if (lower.contains('амстердам') || lower.contains('нидерланды') || lower.contains('netherlands')) return '🇳🇱';
    if (lower.contains('варшава') || lower.contains('польша') || lower.contains('poland')) return '🇵🇱';
    if (lower.contains('санкт') || lower.contains('петербург') || lower.contains('россия')) return '🇷🇺';
    if (lower.contains('вильнюс') || lower.contains('литва') || lower.contains('lithuania')) return '🇱🇹';
    if (lower.contains('йорк') || lower.contains('сша') || lower.contains('usa')) return '🇺🇸';
    if (lower.contains('финляндия') || lower.contains('helsinki') || lower.contains('finland')) return '🇫🇮';
    return '🌐';
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
