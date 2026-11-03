import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vpn_provider.dart';
import '../../services/xray_service.dart';
import '../../services/tray_service.dart';
import '../../services/update_service.dart';
import '../../services/config_generator.dart';

import '../../models/vless_node.dart';

import '../../models/subscription_model.dart';

import '../../utils/country_flag_helper.dart';

import '../widgets/logo.dart';

import '../widgets/country_flag_widget.dart';

import '../widgets/smooth_scroll.dart';

import 'settings_screen.dart';



class DashboardScreen extends ConsumerStatefulWidget {

  const DashboardScreen({super.key});



  @override

  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();

}



class _DashboardScreenState extends ConsumerState<DashboardScreen> with TickerProviderStateMixin {

  late final AnimationController _spinController;
  late final AnimationController _pulseController;

  bool _isButtonHovered = false;

  final TextEditingController _searchController = TextEditingController();

  final SmoothScrollController _serverScrollController = SmoothScrollController();
  final SmoothScrollController _subscriptionScrollController = SmoothScrollController();

  String _selectedSubId = '';
  String? _pingingNodeId;

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    _subscriptionScrollController.dispose();
    _serverScrollController.dispose();
    super.dispose();

  }



  @override

  void initState() {

    super.initState();

    _spinController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

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

              'У вас установлена самая актуальная версия (v${UpdateService.currentVersion})',

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

  Widget build(BuildContext context) {

    final vpn = ref.watch(vpnProvider);

    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;



    final isWide = MediaQuery.of(context).size.width >= 780;



    return Scaffold(
      backgroundColor: vpn.settings.hasBackgroundImage ? Colors.transparent : colorScheme.surface,
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

          // Кнопка "Поддержать"
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 16),
            label: const Text('Поддержать', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => UpdateService.openUrl('https://www.donationalerts.com/r/qkryt'),
          ),

          const SizedBox(width: 4),

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

          const SizedBox(width: 4),

          IconButton(

            icon: const Icon(Icons.settings_outlined),

            tooltip: 'Настройки',

            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const SettingsScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
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

    final isBusy = isConnecting || vpn.isTestingPing;

    if (isBusy && !_spinController.isAnimating) {
      _spinController.repeat();
    } else if (!isBusy && _spinController.isAnimating) {
      _spinController.stop();
      _spinController.reset();
    }

    if (isConnected && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isConnected && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }



    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: isCompact ? 16 : 28),
      color: Colors.transparent,
      child: Column(

        mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,

        children: [

          if (!isCompact) ...[

            Align(

              alignment: Alignment.topRight,

              child: Container(

                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),

                decoration: BoxDecoration(

                  color: vpn.settings.hasBackgroundImage
                      ? colorScheme.surfaceContainerHigh.withOpacity(0.85)
                      : colorScheme.surfaceContainerHigh,

                  borderRadius: BorderRadius.circular(20),

                ),

                child: Row(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    Icon(Icons.shield_rounded, size: 16, color: colorScheme.primary),

                    const SizedBox(width: 6),

                    Text(
                      'Защита (Xray TUN + Прокси)',
                      style: theme.textTheme.labelMedium,
                    ),

                  ],

                ),

              ),

            ),

            const Spacer(),

          ],



          // Живая круглая кнопка включения в дизайне Material You с анимацией при пинге/подключении

                    // Живая круглая кнопка включения в дизайне Material You с анимациями
          Center(
            child: SizedBox(
              width: size + 36,
              height: size + 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Пульсирующая живая аура при активном подключении
                  if (isConnected) ...[
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final wave = _pulseController.value;
                        return Container(
                          width: size + 14 + (16 * wave),
                          height: size + 14 + (16 * wave),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.primary.withOpacity((1.0 - wave) * 0.45),
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity((1.0 - wave) * 0.30),
                                blurRadius: 22 * wave + 10,
                                spreadRadius: 4 * wave,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  // 2. Вращающееся динамическое кольцо анимации при пинге или подключении
                  if (isBusy) ...[
                    AnimatedBuilder(
                      animation: _spinController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _spinController.value * 2 * 3.1415926535,
                          child: CustomPaint(
                            size: Size(size + 24, size + 24),
                            painter: _BusyRingPainter(
                              color: colorScheme.primary,
                              secondaryColor: colorScheme.tertiary,
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  // 3. Живая кнопка: отклик на наведение курсора с анимацией масштаба и тени
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _isButtonHovered = true),
                    onExit: (_) => setState(() => _isButtonHovered = false),
                    child: AnimatedScale(
                      scale: _isButtonHovered ? 1.045 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isConnected
                                  ? colorScheme.primary.withOpacity(_isButtonHovered ? 0.45 : 0.35)
                                  : Colors.black.withOpacity(_isButtonHovered ? 0.25 : 0.15),
                              blurRadius: isConnected ? (_isButtonHovered ? 30 : 22) : (_isButtonHovered ? 16 : 8),
                              spreadRadius: isConnected ? (_isButtonHovered ? 4 : 2) : 0,
                            ),
                          ],
                        ),
                        child: Material(
                          color: isConnected
                              ? colorScheme.primary
                              : (vpn.settings.hasBackgroundImage
                                  ? colorScheme.surfaceContainerHighest.withOpacity(0.9)
                                  : colorScheme.surfaceContainerHighest),
                          shape: const CircleBorder(),
                          elevation: _isButtonHovered ? 6 : (isConnected ? 3 : 1),
                          shadowColor: Colors.black.withOpacity(0.3),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => ref.read(vpnProvider.notifier).toggleConnection(),
                            customBorder: const CircleBorder(),
                            hoverColor: isConnected
                                ? Colors.white.withOpacity(0.12)
                                : colorScheme.primary.withOpacity(0.12),
                            highlightColor: isConnected
                                ? Colors.white.withOpacity(0.20)
                                : colorScheme.primary.withOpacity(0.20),
                            splashColor: isConnected
                                ? Colors.white.withOpacity(0.25)
                                : colorScheme.primary.withOpacity(0.25),
                            child: SizedBox(
                              width: size,
                              height: size,
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  transitionBuilder: (child, anim) => FadeTransition(
                                    opacity: anim,
                                    child: ScaleTransition(scale: anim, child: child),
                                  ),
                                  child: isConnecting
                                      ? Column(
                                          key: const ValueKey('connecting'),
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              color: isConnected ? colorScheme.onPrimary : colorScheme.primary,
                                              strokeWidth: 3.5,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'ПОДКЛЮЧЕНИЕ...',
                                              style: TextStyle(
                                                color: isConnected ? colorScheme.onPrimary : colorScheme.primary,
                                                fontSize: isCompact ? 10 : 11,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          key: ValueKey(isConnected ? 'connected' : 'disconnected'),
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
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Карточка выбранного сервера под кнопкой со скруглениями
          if (vpn.selectedNode != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: vpn.settings.hasBackgroundImage
                    ? colorScheme.surfaceContainerHigh.withOpacity(0.85)
                    : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                  const SizedBox(width: 10),
                  _buildServerPingBadge(vpn.selectedNode!.pingMs),
                ],
              ),
            )
          else
            Text(
              'Сервер не выбран',
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
                          Text('Замерить пинг всех', style: TextStyle(fontWeight: FontWeight.bold)),
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

  // ==================== ВЫДЕЛЕННЫЙ СПИСОК СЕРВЕРОВ И ПОДПИСОК ====================

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



    final totalTabs = vpn.subscriptions.length + (vpn.manualNodes.isNotEmpty ? 1 : 0);
    final hasMultiple = totalTabs > 1;

    // Автоматический выбор первой валидной подписки или вкладки 'manual'
    if (_selectedSubId.isEmpty || _selectedSubId == 'all' || (_selectedSubId != 'manual' && !vpn.subscriptions.any((s) => s.id == _selectedSubId))) {
      if (vpn.subscriptions.isNotEmpty) {
        _selectedSubId = vpn.subscriptions.first.id;
      } else if (vpn.manualNodes.isNotEmpty) {
        _selectedSubId = 'manual';
      }
    }

    SubscriptionModel? currentSub;
    if (_selectedSubId != 'manual') {
      final matches = vpn.subscriptions.where((s) => s.id == _selectedSubId);
      if (matches.isNotEmpty) {
        currentSub = matches.first;
      } else if (vpn.subscriptions.isNotEmpty) {
        currentSub = vpn.subscriptions.first;
        _selectedSubId = currentSub.id;
      }
    }

    List<VlessNode> displayNodes;
    if (_selectedSubId == 'manual') {
      displayNodes = vpn.manualNodes;
    } else if (currentSub != null) {
      displayNodes = currentSub.nodes;
    } else if (vpn.subscriptions.isNotEmpty) {
      displayNodes = vpn.subscriptions.first.nodes;
    } else {
      displayNodes = vpn.manualNodes;
    }

    return Column(
      children: [
        // 1. Панель переключения подписок (вкладки сверху с поддержкой плавного горизонтального скроллинга)
        if (hasMultiple) ...[
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Прокрутить влево',
                  onPressed: () {
                    if (_subscriptionScrollController.hasClients) {
                      final target = (_subscriptionScrollController.offset - 220).clamp(
                        0.0,
                        _subscriptionScrollController.position.maxScrollExtent,
                      );
                      _subscriptionScrollController.animateTo(
                        target,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: HorizontalSmoothScroll(
                    controller: _subscriptionScrollController,
                    child: Scrollbar(
                      controller: _subscriptionScrollController,
                      thumbVisibility: false,
                      child: ListView(
                        controller: _subscriptionScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        children: [
                          for (int i = 0; i < vpn.subscriptions.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            ChoiceChip(
                              showCheckmark: false,
                              avatar: vpn.subscriptions[i].isPinned ? const Icon(Icons.push_pin, size: 14) : null,
                              label: Text('${vpn.subscriptions[i].name} (${vpn.subscriptions[i].nodes.length})'),
                              selected: _selectedSubId == vpn.subscriptions[i].id,
                              onSelected: (val) {
                                if (val) setState(() => _selectedSubId = vpn.subscriptions[i].id);
                              },
                            ),
                          ],
                          if (vpn.manualNodes.isNotEmpty) ...[
                            if (vpn.subscriptions.isNotEmpty) const SizedBox(width: 8),
                            ChoiceChip(
                              showCheckmark: false,
                              label: Text('Сервера (${vpn.manualNodes.length})'),
                              selected: _selectedSubId == 'manual',
                              onSelected: (val) {
                                if (val) setState(() => _selectedSubId = 'manual');
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Прокрутить вправо',
                  onPressed: () {
                    if (_subscriptionScrollController.hasClients) {
                      final target = (_subscriptionScrollController.offset + 220).clamp(
                        0.0,
                        _subscriptionScrollController.position.maxScrollExtent,
                      );
                      _subscriptionScrollController.animateTo(
                        target,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],



        // 2. Закреплённая плашка активной подписки / сводка (не уезжает при скролле)

        Padding(

          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),

          child: currentSub != null

              ? _buildSubscriptionHeaderCard(context, currentSub)

              : _buildGeneralSummaryCard(context, vpn, displayNodes.length),

        ),



        // 3. Выделенный список серверов: ползунок скроллбара строго зависит от длины списка серверов

        Expanded(

          child: displayNodes.isEmpty

              ? Center(

                  child: Text(

                    'Список серверов пуст',

                    style: TextStyle(color: colorScheme.onSurfaceVariant),

                  ),

                )

              : Scrollbar(

                  controller: _serverScrollController,

                  thumbVisibility: true,

                  interactive: true,

                  child: ListView.builder(
                    controller: _serverScrollController,
                    cacheExtent: 250,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    itemCount: displayNodes.length,

                    itemBuilder: (context, index) {

                      final node = displayNodes[index];

                      final isManual = vpn.manualNodes.any((n) => n.id == node.id);

                      return _buildServerTile(context, node, canDelete: isManual);

                    },

                  ),

                ),

        ),

      ],

    );

  }



  Widget _buildSubscriptionHeaderCard(BuildContext context, SubscriptionModel sub) {
    final vpn = ref.watch(vpnProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;



    final dateStr = '${sub.lastUpdated.day.toString().padLeft(2, '0')}.${sub.lastUpdated.month.toString().padLeft(2, '0')}.${sub.lastUpdated.year} '

        '${sub.lastUpdated.hour.toString().padLeft(2, '0')}:${sub.lastUpdated.minute.toString().padLeft(2, '0')}';



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



    return Container(

      decoration: BoxDecoration(

        color: vpn.settings.hasBackgroundImage
            ? colorScheme.surfaceContainerHigh.withOpacity(0.85)
            : colorScheme.surfaceContainerHigh,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(

          color: sub.isPinned

              ? colorScheme.primary.withOpacity(0.55)

              : colorScheme.outlineVariant.withOpacity(0.25),

          width: sub.isPinned ? 1.5 : 1,

        ),

      ),

      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

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

                          borderRadius: BorderRadius.circular(8),

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

              buildM3IconButton(

                icon: sub.isPinned ? Icons.push_pin : Icons.push_pin_outlined,

                tooltip: sub.isPinned ? 'Открепить подписку' : 'Закрепить сверху',

                color: sub.isPinned ? colorScheme.primary : null,

                onPressed: () => ref.read(vpnProvider.notifier).togglePinSubscription(sub.id),

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

            ],

          ),

          const SizedBox(height: 4),

          Text(

            'Обновлено: $dateStr • Серверов: ${sub.nodes.length}',

            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),

          ),

          const SizedBox(height: 8),

          Row(

            children: [

              Expanded(

                child: Stack(

                  children: [

                    Container(

                      height: 16,

                      decoration: BoxDecoration(

                        color: colorScheme.surfaceContainerHighest,

                        borderRadius: BorderRadius.circular(8),

                        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),

                      ),

                    ),

                    FractionallySizedBox(

                      widthFactor: sub.usedPercentage,

                      child: Container(

                        height: 16,

                        decoration: BoxDecoration(

                          color: colorScheme.primary.withOpacity(0.55),

                          borderRadius: BorderRadius.circular(8),

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

                  'До: ${sub.expireDate!.day}.${sub.expireDate!.month}.${sub.expireDate!.year}',

                  style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),

                ),

              ],

            ],

          ),

        ],

      ),

    );

  }



  Widget _buildGeneralSummaryCard(BuildContext context, dynamic vpn, int totalServers) {

    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;



    return Container(

      decoration: BoxDecoration(

        color: vpn.settings.hasBackgroundImage
            ? colorScheme.surfaceContainerHigh.withOpacity(0.85)
            : colorScheme.surfaceContainerHigh,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(

          color: colorScheme.outlineVariant.withOpacity(0.25),

        ),

      ),

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

      child: Row(

        children: [

          Icon(Icons.dns_rounded, size: 28, color: colorScheme.primary),

          const SizedBox(width: 12),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  'Все серверы',

                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),

                ),

                Text(

                  'Всего узлов: $totalServers • Подписок: ${vpn.subscriptions.length}',

                  style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),

                ),

              ],

            ),

          ),

          FilledButton.tonalIcon(

            icon: const Icon(Icons.speed_rounded, size: 16),

            label: const Text('Пинг всех'),

            onPressed: vpn.isTestingPing

                ? null

                : () => ref.read(vpnProvider.notifier).pingAllNodes(),

          ),

        ],

      ),

    );

  }



  Widget _buildServerPingBadge(int? pingMs, {bool isPinging = false}) {
    if (isPinging) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.blue),
            ),
            SizedBox(width: 5),
            Text(
              'Time (...)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue),
            ),
          ],
        ),
      );
    }

    if (pingMs == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.network_ping_rounded, size: 13, color: Colors.grey),
            SizedBox(width: 4),
            Text(
              'Time (-- ms)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (pingMs <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.warning_amber_rounded, size: 13, color: Colors.redAccent),
            SizedBox(width: 4),
            Text(
              'Time (Timeout)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            'Time ($pingMs ms)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerTile(BuildContext context, VlessNode node, {bool canDelete = false}) {
    final vpn = ref.watch(vpnProvider);
    final isSelected = vpn.selectedNode?.id == node.id;
    final isPinging = _pingingNodeId == node.id || (vpn.isTestingPing && node.pingMs == null);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = isSelected ? BorderRadius.circular(20) : BorderRadius.circular(16);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.secondaryContainer.withOpacity(0.48)
              : (vpn.settings.hasBackgroundImage
                  ? colorScheme.surfaceContainerHighest.withOpacity(0.35)
                  : colorScheme.surfaceContainerHighest.withOpacity(0.2)),
          borderRadius: borderRadius,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.75)
                : colorScheme.outlineVariant.withOpacity(0.22),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: () => ref.read(vpnProvider.notifier).selectNode(node),
            onSecondaryTap: () => _showServerActionModal(context, node, canDelete: canDelete),
            onLongPress: () => _showServerActionModal(context, node, canDelete: canDelete),
            hoverColor: colorScheme.primary.withOpacity(0.08),
            splashColor: colorScheme.primary.withOpacity(0.16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withOpacity(0.16)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CountryFlagWidget(
                      isoCode: CountryFlagHelper.getCountryCode(node.remark),
                      width: 26,
                      height: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CountryFlagHelper.cleanRemark(node.remark),
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 14,
                            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${node.protocol.name.toUpperCase()} / ${node.streamType.toUpperCase()} / ${node.security.toUpperCase()}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildServerPingBadge(node.pingMs, isPinging: isPinging),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      key: ValueKey(isSelected),
                      color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.6),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    tooltip: 'Настройки и действия узла (ПКМ)',
                    onPressed: () => _showServerActionModal(context, node, canDelete: canDelete),
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
            ),
          ),
        ),
      ),
    );
  }

  // ==================== ОКНО ДЕЙСТВИЙ СЕРВЕРА (ПИНГ, JSON, ВЫБОР) ====================

  void _showServerActionModal(BuildContext context, VlessNode node, {bool canDelete = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          bool isPinging = false;
          int? currentPing = node.pingMs;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CountryFlagWidget(isoCode: CountryFlagHelper.getCountryCode(node.remark), width: 32, height: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            CountryFlagHelper.cleanRemark(node.remark),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${node.protocol.name.toUpperCase()} • ${node.address}:${node.port} • ${node.security.toUpperCase()}',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildServerPingBadge(currentPing),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // 1. Замерить пинг выбранного сервера
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.green),
                  ),
                  title: const Text('Замерить пинг', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Режим: ${ref.read(vpnProvider).settings.pingMode}'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    final targetNode = node;
                    Navigator.pop(ctx);

                    // 1. Переключаем на вкладку с данным сервером при необходимости
                    final vpnState = ref.read(vpnProvider);
                    if (vpnState.manualNodes.any((n) => n.id == targetNode.id)) {
                      if (_selectedSubId != 'manual') {
                        setState(() => _selectedSubId = 'manual');
                      }
                    } else {
                      for (final sub in vpnState.subscriptions) {
                        if (sub.nodes.any((n) => n.id == targetNode.id)) {
                          if (_selectedSubId != sub.id) {
                            setState(() => _selectedSubId = sub.id);
                          }
                          break;
                        }
                      }
                    }

                    // 2. Отмечаем пингуемый сервер как выбранный
                    ref.read(vpnProvider.notifier).selectNode(targetNode);

                    // 3. Запускаем замер пинга с отображением индикатора
                    setState(() => _pingingNodeId = targetNode.id);
                    ref.read(vpnProvider.notifier).pingSingleNode(targetNode).whenComplete(() {
                      if (mounted) {
                        setState(() {
                          if (_pingingNodeId == targetNode.id) {
                            _pingingNodeId = null;
                          }
                        });
                      }
                    });
                  },
                ),

                // 2. JSON конфигурация сервера
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.data_object_rounded, color: Colors.blue),
                  ),
                  title: const Text('JSON конфигурация', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Показать Xray outbound формат узла'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showNodeJsonDialog(context, node);
                  },
                ),

                // 3. Выбрать этот сервер
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.power_settings_new_rounded, color: colorScheme.primary),
                  ),
                  title: const Text('Выбрать этот сервер', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Сделать активным для подключения'),
                  trailing: const Icon(Icons.check_rounded, size: 18),
                  onTap: () {
                    ref.read(vpnProvider.notifier).selectNode(node);
                    Navigator.pop(ctx);
                  },
                ),

                // 4. Скопировать ссылку
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.copy_rounded, color: Colors.orange),
                  ),
                  title: const Text('Скопировать ссылку узла'),
                  subtitle: Text(node.rawUri, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.content_copy_rounded, size: 16),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: node.rawUri));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ссылка сервера скопирована в буфер обмена!')),
                    );
                  },
                ),

                if (canDelete)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    ),
                    title: const Text('Удалить узел', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onTap: () {
                      ref.read(vpnProvider.notifier).deleteManualNode(node.id);
                      Navigator.pop(ctx);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showNodeJsonDialog(BuildContext context, VlessNode node) {
    final jsonMap = ConfigGenerator.buildOutboundJson(node);
    final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonMap);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.data_object_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'JSON: ${CountryFlagHelper.cleanRemark(node.remark)}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 420),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                prettyJson,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Скопировать JSON'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: prettyJson));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSON конфигурация скопирована в буфер обмена!')),
              );
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть'),
          ),
        ],
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
          children: [
            const Icon(Icons.add_link_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Добавить подписку или узел',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
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





class _BusyRingPainter extends CustomPainter {

  final Color color;

  final Color secondaryColor;



  _BusyRingPainter({required this.color, required this.secondaryColor});



  @override

  void paint(Canvas canvas, Size size) {

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()

      ..style = PaintingStyle.stroke

      ..strokeWidth = 3.5

      ..strokeCap = StrokeCap.round

      ..shader = SweepGradient(

        colors: [

          color.withOpacity(0.0),

          color,

          secondaryColor,

          color.withOpacity(0.0),

        ],

        stops: const [0.0, 0.45, 0.75, 1.0],

      ).createShader(rect);



    canvas.drawArc(rect.deflate(2), 0, 3.1415926535 * 1.6, false, paint);

  }



  @override

  bool shouldRepaint(covariant _BusyRingPainter oldDelegate) =>

      color != oldDelegate.color || secondaryColor != oldDelegate.secondaryColor;

}

