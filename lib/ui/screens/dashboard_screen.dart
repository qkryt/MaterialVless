import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vpn_provider.dart';
import '../../services/xray_service.dart';
import 'node_list_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vpn = ref.watch(vpnProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnected = vpn.status == CoreState.connected;
    final isConnecting = vpn.status == CoreState.connecting;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MaterialVless',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.dns_rounded),
            tooltip: 'Список узлов',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NodeListScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              SegmentedButton<NetworkMode>(
                segments: const [
                  ButtonSegment(
                    value: NetworkMode.tun,
                    label: Text('TUN Режим'),
                    icon: Icon(Icons.shield_outlined),
                  ),
                  ButtonSegment(
                    value: NetworkMode.systemProxy,
                    label: Text('Системный прокси'),
                    icon: Icon(Icons.alt_route_rounded),
                  ),
                ],
                selected: {vpn.mode},
                onSelectionChanged: (set) => ref.read(vpnProvider.notifier).setMode(set.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: colorScheme.secondaryContainer,
                  selectedForegroundColor: colorScheme.onSecondaryContainer,
                ),
              ),
              const Spacer(),
              Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    final scale = isConnected ? _pulseAnimation.value : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: GestureDetector(
                        onTap: () => ref.read(vpnProvider.notifier).toggleConnection(),
                        child: Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest,
                            boxShadow: [
                              BoxShadow(
                                color: (isConnected
                                        ? colorScheme.primary
                                        : colorScheme.outlineVariant)
                                    .withOpacity(0.35),
                                blurRadius: isConnected ? 32 : 12,
                                spreadRadius: isConnected ? 8 : 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: isConnecting
                                ? CircularProgressIndicator(
                                    color: colorScheme.onPrimary,
                                    strokeWidth: 4,
                                  )
                                : Icon(
                                    Icons.power_settings_new_rounded,
                                    size: 76,
                                    color: isConnected
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isConnecting
                    ? 'Подключение...'
                    : isConnected
                        ? 'Защищено (VLESS Reality)'
                        : 'Отключено',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isConnected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (isConnected)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMetric(
                        context,
                        icon: Icons.arrow_downward_rounded,
                        label: 'Загрузка',
                        value: '${(vpn.downloadSpeedBps / 1000000).toStringAsFixed(1)} Mbps',
                        color: colorScheme.primary,
                      ),
                      Container(height: 36, width: 1, color: colorScheme.outlineVariant),
                      _buildMetric(
                        context,
                        icon: Icons.arrow_upward_rounded,
                        label: 'Отдача',
                        value: '${(vpn.uploadSpeedBps / 1000000).toStringAsFixed(1)} Mbps',
                        color: colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              Card(
                color: colorScheme.surfaceContainerHigh,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NodeListScreen()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.vpn_lock_rounded,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vpn.selectedNode?.remark ?? 'Выберите узел',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vpn.selectedNode != null
                                    ? '${vpn.selectedNode!.streamType.toUpperCase()} • ${vpn.selectedNode!.sni}'
                                    : 'Нажмите для выбора сервера',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (vpn.selectedNode?.pingMs != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${vpn.selectedNode!.pingMs} ms',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}