import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vpn_provider.dart';
import '../../services/xray_service.dart';
import '../../services/tray_service.dart';
import '../../services/update_service.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TrayService.instance.init(
        onRestartCore: () async {
          await ref.read(vpnProvider.notifier).restartCore();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ядро VPN успешно перезагружено')),
            );
          }
        },
        onExitApp: () async {
          await ref.read(vpnProvider.notifier).exitApp();
          await TrayService.instance.cleanUpAndExit();
        },
      );

      _checkAppUpdate();
    });
  }

  Future<void> _checkAppUpdate({bool manual = false}) async {
    final result = await UpdateService.checkDetailedUpdate();
    if (!mounted) return;

    if (result.hasUpdate && result.updateInfo != null) {
      await UpdateService.showUpdateDialog(context, result.updateInfo!);
    } else if (manual) {
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'У вас установлена самая актуальная версия (v)',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Не удалось проверить обновления'),
          ),
        );
      }
    }
  }

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
            icon: const Icon(Icons.system_update_rounded),
            tooltip: 'Проверить обновления',
            onPressed: () => _checkAppUpdate(manual: true),
          ),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: sub.isPinned
              ? colorScheme.primary.withOpacity(0.55)
              : colorScheme.outlineVariant.withOpacity(0.25),
          width: sub.isPinned ? 1.5 : 1,
        ),
        boxShadow: sub.isPinned
            ? [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => ref.read(vpnProvider.notifier).toggleSubscriptionExpansion(sub.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isCompact = constraints.maxWidth < 490;

                      Widget buildM3IconButton({
                        required IconData icon,
                        required String tooltip,
                        required VoidCallback onPressed,
                        Color? color,
                        double size = 19,
                      }) {
                        return Tooltip(
                          message: tooltip,
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: onPressed,
                              hoverColor: colorScheme.primary.withValues(alpha: 0.12),
                              highlightColor: colorScheme.primary.withValues(alpha: 0.20),
                              splashColor: colorScheme.primary.withValues(alpha: 0.25),
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(7.0),
                                child: Icon(
                                  icon,
                                  size: size,
                                  color: color ?? colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return Row(
                        children: [
                          // Живая кнопка сворачивания/разворачивания с M3 hover-кружком
                          Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => ref.read(vpnProvider.notifier).toggleSubscriptionExpansion(sub.id),
                              hoverColor: colorScheme.primary.withValues(alpha: 0.12),
                              highlightColor: colorScheme.primary.withValues(alpha: 0.20),
                              splashColor: colorScheme.primary.withValues(alpha: 0.25),
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  sub.isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    sub.name,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (sub.isPinned) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.push_pin, size: 11, color: colorScheme.onPrimaryContainer),
                                        const SizedBox(width: 3),
                                        Text(
                                          'ЗАКРЕПЛЕНО',
                                          style: TextStyle(
                                            color: colorScheme.onPrimaryContainer,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // На широком экране: все 6 кнопок (Закрепить, Вверх, Вниз, Обновить, Пинг, Настройки)
                          if (!isCompact) ...[
                            buildM3IconButton(
                              icon: sub.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                              tooltip: sub.isPinned ? 'Открепить подписку' : 'Закрепить сверху',
                              color: sub.isPinned ? colorScheme.primary : null,
                              onPressed: () => ref.read(vpnProvider.notifier).togglePinSubscription(sub.id),
                            ),
                            buildM3IconButton(
                              icon: Icons.arrow_upward_rounded,
                              tooltip: 'Переместить выше',
                              onPressed: () => ref.read(vpnProvider.notifier).moveSubscriptionUp(sub.id),
                            ),
                            buildM3IconButton(
                              icon: Icons.arrow_downward_rounded,
                              tooltip: 'Переместить ниже',
                              onPressed: () => ref.read(vpnProvider.notifier).moveSubscriptionDown(sub.id),
                            ),
                            buildM3IconButton(
                              icon: Icons.refresh_rounded,
                              tooltip: 'Обновить подписку',
                              onPressed: () => ref.read(vpnProvider.notifier).refreshSubscription(sub.id),
                            ),
                            buildM3IconButton(
                              icon: Icons.speed_rounded,
                              tooltip: 'Замерить пинг подписки',
                              onPressed: () => ref.read(vpnProvider.notifier).pingSubscription(sub.id),
                            ),
                            buildM3IconButton(
                              icon: Icons.more_vert_rounded,
                              tooltip: 'Настройки подписки',
                              onPressed: () => _showSubscriptionOptionsDialog(context, sub),
                            ),
                          ]
                          // При сжатии: ровно 3 кнопки (Обновить, Пинг, Троеточие с настройками и перемещением)
                          else ...[
                            buildM3IconButton(
                              icon: Icons.refresh_rounded,
                              tooltip: 'Обновить подписку',
                              onPressed: () => ref.read(vpnProvider.notifier).refreshSubscription(sub.id),
                            ),
                            buildM3IconButton(
                              icon: Icons.speed_rounded,
                              tooltip: 'Замерить пинг подписки',
                              onPressed: () => ref.read(vpnProvider.notifier).pingSubscription(sub.id),
                            ),
                            Theme(
                              data: theme.copyWith(
                                popupMenuTheme: PopupMenuThemeData(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  color: colorScheme.surfaceContainerHigh,
                                ),
                              ),
                              child: PopupMenuButton<String>(
                                tooltip: 'Действия с подпиской',
                                icon: Icon(Icons.more_vert_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'pin':
                                      ref.read(vpnProvider.notifier).togglePinSubscription(sub.id);
                                      break;
                                    case 'up':
                                      ref.read(vpnProvider.notifier).moveSubscriptionUp(sub.id);
                                      break;
                                    case 'down':
                                      ref.read(vpnProvider.notifier).moveSubscriptionDown(sub.id);
                                      break;
                                    case 'settings':
                                      _showSubscriptionOptionsDialog(context, sub);
                                      break;
                                    case 'delete':
                                      ref.read(vpnProvider.notifier).deleteSubscription(sub.id);
                                      break;
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(
                                    value: 'pin',
                                    child: Row(
                                      children: [
                                        Icon(sub.isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18, color: colorScheme.primary),
                                        const SizedBox(width: 10),
                                        Text(sub.isPinned ? 'Открепить' : 'Закрепить сверху'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'up',
                                    child: Row(
                                      children: [
                                        Icon(Icons.arrow_upward_rounded, size: 18),
                                        SizedBox(width: 10),
                                        Text('Переместить выше'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'down',
                                    child: Row(
                                      children: [
                                        Icon(Icons.arrow_downward_rounded, size: 18),
                                        SizedBox(width: 10),
                                        Text('Переместить ниже'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: 'settings',
                                    child: Row(
                                      children: [
                                        Icon(Icons.settings_outlined, size: 18),
                                        SizedBox(width: 10),
                                        Text('Настройки подписки'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                        SizedBox(width: 10),
                                        Text('Удалить подписку', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
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
    bool updateOnStart = sub.updateOnStart;
    bool pingOnStart = sub.pingOnStart;
    bool connectBestOnStart = sub.connectBestOnStart;
    bool sendHwid = sub.sendHwid;
    bool useAltHwid = sub.useAltHwid;

    final nameController = TextEditingController(text: sub.name);
    final urlController = TextEditingController(text: sub.url);
    final uaController = TextEditingController(text: sub.customUserAgent ?? '');
    final altHwidController = TextEditingController(text: sub.altHwid ?? '');

    final dateStr = '${sub.lastUpdated.day.toString().padLeft(2, '0')}.${sub.lastUpdated.month.toString().padLeft(2, '0')}.${sub.lastUpdated.year} '
        '${sub.lastUpdated.hour.toString().padLeft(2, '0')}:${sub.lastUpdated.minute.toString().padLeft(2, '0')}:${sub.lastUpdated.second.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.tune_rounded),
              SizedBox(width: 10),
              Expanded(child: Text('Опции подписки', overflow: TextOverflow.ellipsis)),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, minWidth: 360),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: Icon(sub.isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18),
                          label: Text(sub.isPinned ? 'Открепить' : 'Закрепить сверху'),
                          onPressed: () {
                            ref.read(vpnProvider.notifier).togglePinSubscription(sub.id);
                            Navigator.pop(ctx);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.arrow_upward_rounded),
                        tooltip: 'Переместить выше',
                        onPressed: () {
                          ref.read(vpnProvider.notifier).moveSubscriptionUp(sub.id);
                          Navigator.pop(ctx);
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.arrow_downward_rounded),
                        tooltip: 'Переместить ниже',
                        onPressed: () {
                          ref.read(vpnProvider.notifier).moveSubscriptionDown(sub.id);
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название подписки',
                      prefixIcon: Icon(Icons.label_outline_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: urlController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'URL адрес подписки',
                      hintText: 'https://...',
                      prefixIcon: const Icon(Icons.link_rounded),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => urlController.clear(),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: uaController,
                    decoration: const InputDecoration(
                      labelText: 'Кастомный User-Agent (необязательно)',
                      hintText: 'По умолчанию: глобальный User-Agent',
                      prefixIcon: Icon(Icons.web_rounded),
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
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Последнее обновление из источника:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Автообновление по расписанию'),
                    subtitle: const Text('Периодически загружать свежие узлы из источника'),
                    value: autoUpdate,
                    onChanged: (val) => setDialogState(() => autoUpdate = val),
                  ),
                  if (autoUpdate) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Wrap(
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
                    ),
                  ],
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Обновлять при старте клиента'),
                    subtitle: const Text('Автоматически проверять обновления подписки при старте'),
                    value: updateOnStart,
                    onChanged: (val) => setDialogState(() => updateOnStart = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Замерять пинг при старте'),
                    subtitle: const Text('Автоматически пинговать узлы этой подписки'),
                    value: pingOnStart,
                    onChanged: (val) => setDialogState(() => pingOnStart = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Подключаться к лучшему серверу'),
                    subtitle: const Text('Автоматически выбирать сервер с наименьшим пингом'),
                    value: connectBestOnStart,
                    onChanged: (val) => setDialogState(() => connectBestOnStart = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Отправлять аппаратный ID (HWID)'),
                    subtitle: const Text('Передавать заголовок X-HWID для серверов с привязкой'),
                    value: sendHwid,
                    onChanged: (val) => setDialogState(() => sendHwid = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Альтернативный HWID'),
                    subtitle: const Text('Использовать другой идентификатор для этого профиля'),
                    value: useAltHwid,
                    onChanged: (val) => setDialogState(() => useAltHwid = val),
                  ),
                  if (useAltHwid) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: altHwidController,
                      decoration: const InputDecoration(
                        labelText: 'Пользовательский HWID',
                        hintText: 'Например: custom-hwid-device-1',
                        prefixIcon: Icon(Icons.fingerprint_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
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
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                final customName = nameController.text.trim();
                final newUrl = urlController.text.trim();
                final customUa = uaController.text.trim();
                final altHwid = altHwidController.text.trim();

                ref.read(vpnProvider.notifier).updateSubscriptionOptions(
                      sub.id,
                      intervalHours: selectedInterval,
                      autoUpdate: autoUpdate,
                      customName: customName.isNotEmpty ? customName : null,
                      newUrl: newUrl.isNotEmpty ? newUrl : null,
                      customUserAgent: customUa.isNotEmpty ? customUa : null,
                      updateOnStart: updateOnStart,
                      pingOnStart: pingOnStart,
                      connectBestOnStart: connectBestOnStart,
                      sendHwid: sendHwid,
                      useAltHwid: useAltHwid,
                      altHwid: altHwid.isNotEmpty ? altHwid : null,
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
        title: Row(
          children: const [
            Icon(Icons.add_link_rounded),
            SizedBox(width: 10),
            Text('Добавить подписку или узел'),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, minWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                minLines: 2,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Вставьте ссылку подписки (https://...), прямую ссылку vless://, ss://, hy2:// или путь к .txt файлу',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => controller.clear(),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Поддерживаются: vless://, vmess://, shadowsocks (ss://), trojan://, hysteria2 (hy2://), а также зашифрованные конфигурации.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
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
