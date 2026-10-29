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
            child: vpn.nodes.isEmpty
                ? Center(
                    child: Text(
                      'Список узлов пуст.\nДобавьте ссылку на подписку.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    itemCount: vpn.nodes.length,
                    itemBuilder: (context, index) {
                      final node = vpn.nodes[index];
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
                        trailing: node.pingMs != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: node.pingMs! > 0
                                      ? Colors.green.withOpacity(0.12)
                                      : Colors.red.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  node.pingMs! > 0 ? '${node.pingMs} ms' : 'Таймаут',
                                  style: TextStyle(
                                    color: node.pingMs! > 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () => ref.read(vpnProvider.notifier).selectNode(node),
                      );
                    },
                  ),
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