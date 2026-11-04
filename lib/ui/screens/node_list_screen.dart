import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/vpn_provider.dart';
import '../../models/subscription_info.dart';

class NodeListScreen extends ConsumerWidget {
  const NodeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vpn = ref.watch(vpnProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    var displayNodes = vpn.nodes;
    if (vpn.settings.sortByPing) {
      final isAsc = vpn.settings.pingSortOrder != 'desc';
      displayNodes = List<VlessNode>.from(displayNodes)..sort((a, b) {
        final pA = a.pingMs ?? -1;
        final pB = b.pingMs ?? -1;
        if (pA <= 0 && pB <= 0) return 0;
        if (pA <= 0) return 1;
        if (pB <= 0) return -1;
        return isAsc ? pA.compareTo(pB) : pB.compareTo(pA);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Узлы MaterialVless'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_rounded),
            tooltip: 'Замер задержки всех узлов',
            onPressed: () => ref.read(vpnProvider.notifier).pingAllNodes(),
          ),
          IconButton(
            icon: const Icon(Icons.add_link_rounded),
            tooltip: 'Добавить подписку',
            onPressed: () => _showAddSubscriptionDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          if (vpn.subscriptionInfo != null)
            Card(
              margin: const EdgeInsets.all(16.0),
              color: colorScheme.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Использование трафика',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${SubscriptionInfo.formatBytes(vpn.subscriptionInfo!.usedBytes)} / ${SubscriptionInfo.formatBytes(vpn.subscriptionInfo!.totalBytes)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: vpn.subscriptionInfo!.usedPercentage,
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Истекает: ${DateFormat('dd.MM.yyyy').format(vpn.subscriptionInfo!.expireDate)}',
                      style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: displayNodes.isEmpty
                ? Center(
                    child: Text(
                      'Список узлов пуст.\nДобавьте ссылку на подписку.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    itemCount: displayNodes.length,
                    itemBuilder: (context, index) {
                      final node = displayNodes[index];
                      final isSelected = vpn.selectedNode?.id == node.id;

                      return ListTile(
                        leading: Radio<String>(
                          value: node.id,
                          groupValue: vpn.selectedNode?.id,
                          onChanged: (_) => ref.read(vpnProvider.notifier).selectNode(node),
                        ),
                        title: Text(
                          node.remark,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${node.streamType.toUpperCase()} • ${node.security.toUpperCase()}',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        trailing: _buildPingBadge(node.pingMs),
                        onTap: () => ref.read(vpnProvider.notifier).selectNode(node),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPingBadge(int? pingMs) {
    if (pingMs == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.network_ping_rounded, size: 13, color: Colors.grey),
            SizedBox(width: 4),
            Text('Time (-- ms)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
          ],
        ),
      );
    }

    if (pingMs <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 13, color: Colors.redAccent),
            SizedBox(width: 4),
            Text('Time (Timeout)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
          ],
        ),
      );
    }

    final Color color;
    final IconData icon;
    if (pingMs < 120) {
      color = const Color(0xFF4CAF50);
      icon = Icons.bolt_rounded;
    } else if (pingMs < 250) {
      color = const Color(0xFF8BC34A);
      icon = Icons.signal_cellular_alt_rounded;
    } else if (pingMs < 450) {
      color = const Color(0xFFFFB300);
      icon = Icons.signal_cellular_alt_2_bar_rounded;
    } else {
      color = const Color(0xFFE53935);
      icon = Icons.signal_cellular_alt_1_bar_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            'Time ($pingMs ms)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  void _showAddSubscriptionDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новая подписка'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://provider.com/sub/token',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                ref.read(vpnProvider.notifier).addSubscription(url);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Загрузить'),
          ),
        ],
      ),
    );
  }
}