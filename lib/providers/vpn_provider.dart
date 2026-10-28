import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vless_node.dart';
import '../models/subscription_model.dart';
import '../models/app_settings.dart';
import '../services/xray_service.dart';
import '../services/subscription_service.dart';
import '../services/storage_service.dart';

class VpnState {
  final CoreState status;
  final VlessNode? selectedNode;
  final List<SubscriptionModel> subscriptions;
  final List<VlessNode> manualNodes;
  final AppSettings settings;
  final int uploadSpeedBps;
  final int downloadSpeedBps;
  final String searchQuery;
  final bool isTestingPing;
  final int connectedSeconds;
  final int currentPingMs;

  VpnState({
    this.status = CoreState.disconnected,
    this.selectedNode,
    this.subscriptions = const [],
    this.manualNodes = const [],
    required this.settings,
    this.uploadSpeedBps = 0,
    this.downloadSpeedBps = 0,
    this.searchQuery = '',
    this.isTestingPing = false,
    this.connectedSeconds = 0,
    this.currentPingMs = 52,
  });

  String get formattedTimer {
    final hours = connectedSeconds ~/ 3600;
    final minutes = (connectedSeconds % 3600) ~/ 60;
    final seconds = connectedSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  VpnState copyWith({
    CoreState? status,
    VlessNode? selectedNode,
    List<SubscriptionModel>? subscriptions,
    List<VlessNode>? manualNodes,
    AppSettings? settings,
    int? uploadSpeedBps,
    int? downloadSpeedBps,
    String? searchQuery,
    bool? isTestingPing,
    int? connectedSeconds,
    int? currentPingMs,
  }) {
    return VpnState(
      status: status ?? this.status,
      selectedNode: selectedNode ?? this.selectedNode,
      subscriptions: subscriptions ?? this.subscriptions,
      manualNodes: manualNodes ?? this.manualNodes,
      settings: settings ?? this.settings,
      uploadSpeedBps: uploadSpeedBps ?? this.uploadSpeedBps,
      downloadSpeedBps: downloadSpeedBps ?? this.downloadSpeedBps,
      searchQuery: searchQuery ?? this.searchQuery,
      isTestingPing: isTestingPing ?? this.isTestingPing,
      connectedSeconds: connectedSeconds ?? this.connectedSeconds,
      currentPingMs: currentPingMs ?? this.currentPingMs,
    );
  }
}

class VpnNotifier extends StateNotifier<VpnState> {
  final XrayService _xrayService;
  Timer? _sessionTimer;
  Timer? _autoUpdateCheckTimer;

  VpnNotifier(this._xrayService) : super(VpnState(settings: AppSettings())) {
    _init();

    _xrayService.stateStream.listen((status) {
      if (status == CoreState.connected) {
        _startTimer();
      } else {
        _stopTimer();
      }
      state = state.copyWith(status: status);
    });

    _xrayService.speedStream.listen((speeds) {
      state = state.copyWith(
        uploadSpeedBps: speeds.$1,
        downloadSpeedBps: speeds.$2,
      );
    });
  }

  Future<void> _init() async {
    final (savedSubs, savedManual, savedSelectedId, savedSettings) =
        await StorageService.loadData();

    AppSettings currentSettings = savedSettings ?? state.settings;

    VlessNode? restoredSelectedNode;
    if (savedSelectedId != null) {
      for (final s in savedSubs) {
        final match = s.nodes.where((n) => n.id == savedSelectedId);
        if (match.isNotEmpty) {
          restoredSelectedNode = match.first;
          break;
        }
      }
      if (restoredSelectedNode == null) {
        final match = savedManual.where((n) => n.id == savedSelectedId);
        if (match.isNotEmpty) restoredSelectedNode = match.first;
      }
    }

    if (restoredSelectedNode == null && savedSubs.isNotEmpty && savedSubs.first.nodes.isNotEmpty) {
      restoredSelectedNode = savedSubs.first.nodes.first;
    }

    state = state.copyWith(
      subscriptions: savedSubs,
      manualNodes: savedManual,
      settings: currentSettings,
      selectedNode: restoredSelectedNode,
    );

    if (currentSettings.autoUpdateRulesOnStart) {
      SubscriptionService.updateGeoDatabases(
        targetDir: '.',
        geoipUrl: currentSettings.geoipUrl,
        geositeUrl: currentSettings.geositeUrl,
      );
    }

    _checkSubscriptionsAutoUpdate();
    _autoUpdateCheckTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _checkSubscriptionsAutoUpdate();
    });
  }

  void _checkSubscriptionsAutoUpdate() {
    final now = DateTime.now();
    for (final sub in state.subscriptions) {
      if (sub.autoUpdate) {
        final diff = now.difference(sub.lastUpdated).inHours;
        if (diff >= sub.autoUpdateIntervalHours) {
          refreshSubscription(sub.id);
        }
      }
    }
  }

  Future<void> _persist() async {
    await StorageService.saveData(
      subscriptions: state.subscriptions,
      manualNodes: state.manualNodes,
      selectedNodeId: state.selectedNode?.id,
      settings: state.settings,
    );
  }

  void _startTimer() {
    _sessionTimer?.cancel();
    state = state.copyWith(connectedSeconds: 0);
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(connectedSeconds: state.connectedSeconds + 1);
    });
  }

  void _stopTimer() {
    _sessionTimer?.cancel();
    state = state.copyWith(connectedSeconds: 0);
  }

  void toggleSubscriptionExpanded(String subId) {
    final updated = state.subscriptions.map((s) {
      if (s.id == subId) {
        return s.copyWith(isExpanded: !s.isExpanded);
      }
      return s;
    }).toList();
    state = state.copyWith(subscriptions: updated);
    _persist();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Выбор сервера: если VPN уже подключен, автоматически отключается, меняет узел и переподключается на лету
  Future<void> selectNode(VlessNode node) async {
    final wasConnected = state.status == CoreState.connected;
    final isDifferentNode = state.selectedNode?.id != node.id;

    state = state.copyWith(selectedNode: node);
    await _persist();

    if (wasConnected && isDifferentNode) {
      await _xrayService.stop();
      await Future.delayed(const Duration(milliseconds: 300));
      await _xrayService.start(node, state.settings);
    }
  }

  void updateSettings(AppSettings newSettings) {
    state = state.copyWith(settings: newSettings);
    _persist();
  }

  Future<void> addSubscription(String source, {String? customName}) async {
    final cleanSource = source.trim();
    if (cleanSource.isEmpty) return;

    final isSingleNode = cleanSource.startsWith('vless://') ||
        cleanSource.startsWith('vmess://') ||
        cleanSource.startsWith('trojan://') ||
        cleanSource.startsWith('ss://') ||
        cleanSource.startsWith('hysteria://') ||
        cleanSource.startsWith('hysteria2://') ||
        cleanSource.startsWith('hy2://');

    if (isSingleNode) {
      try {
        final node = VlessNode.fromUri(
          cleanSource,
          subscriptionId: 'manual',
          index: state.manualNodes.length,
        );
        final updatedManual = List<VlessNode>.from(state.manualNodes)..add(node);
        state = state.copyWith(
          manualNodes: updatedManual,
          selectedNode: state.selectedNode ?? node,
        );
        await _persist();
        return;
      } catch (_) {}
    }

    final (nodes, meta) = await SubscriptionService.loadSubscription(
      source: cleanSource,
      settings: state.settings,
      customName: customName,
    );

    final isUrl = cleanSource.startsWith('http://') || cleanSource.startsWith('https://');
    final name = customName ?? (isUrl ? Uri.parse(cleanSource).host : 'Импортированные узлы');

    final newSub = SubscriptionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      url: cleanSource,
      lastUpdated: DateTime.now(),
      uploadBytes: meta['upload'] ?? 0,
      downloadBytes: meta['download'] ?? 0,
      totalBytes: meta['total'] ?? 0,
      expireDate: meta['expire'],
      nodes: nodes,
      isExpanded: true,
      autoUpdate: true,
      autoUpdateIntervalHours: 2,
    );

    final updatedSubs = List<SubscriptionModel>.from(state.subscriptions)..add(newSub);

    state = state.copyWith(
      subscriptions: updatedSubs,
      selectedNode: state.selectedNode ?? (nodes.isNotEmpty ? nodes.first : null),
    );
    await _persist();
  }

  Future<void> refreshSubscription(String id) async {
    final index = state.subscriptions.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final target = state.subscriptions[index];
    try {
      final (nodes, meta) = await SubscriptionService.loadSubscription(
        source: target.url,
        settings: state.settings,
        customName: target.name,
      );

      final updatedSub = target.copyWith(
        lastUpdated: DateTime.now(),
        uploadBytes: meta['upload'] ?? target.uploadBytes,
        downloadBytes: meta['download'] ?? target.downloadBytes,
        totalBytes: meta['total'] ?? target.totalBytes,
        expireDate: meta['expire'] ?? target.expireDate,
        nodes: nodes,
      );

      final updatedSubs = List<SubscriptionModel>.from(state.subscriptions);
      updatedSubs[index] = updatedSub;

      VlessNode? newSelected = state.selectedNode;
      if (state.selectedNode?.subscriptionId == id) {
        final match = nodes.where((n) => n.id == state.selectedNode!.id);
        if (match.isNotEmpty) {
          newSelected = match.first;
        } else if (nodes.isNotEmpty) {
          newSelected = nodes.first;
        }
      }

      state = state.copyWith(
        subscriptions: updatedSubs,
        selectedNode: newSelected,
      );
      await _persist();
    } catch (_) {}
  }

  void updateSubscriptionOptions(String id, {
    required int intervalHours,
    required bool autoUpdate,
    String? customName,
  }) {
    final index = state.subscriptions.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final target = state.subscriptions[index];
    final updatedSub = target.copyWith(
      autoUpdateIntervalHours: intervalHours,
      autoUpdate: autoUpdate,
      name: customName ?? target.name,
    );

    final updatedSubs = List<SubscriptionModel>.from(state.subscriptions);
    updatedSubs[index] = updatedSub;

    state = state.copyWith(subscriptions: updatedSubs);
    _persist();
  }

  void deleteSubscription(String id) {
    final updatedSubs = state.subscriptions.where((s) => s.id != id).toList();
    VlessNode? newSelected = state.selectedNode;
    if (state.selectedNode?.subscriptionId == id) {
      newSelected = updatedSubs.isNotEmpty && updatedSubs.first.nodes.isNotEmpty
          ? updatedSubs.first.nodes.first
          : (state.manualNodes.isNotEmpty ? state.manualNodes.first : null);
    }

    state = state.copyWith(
      subscriptions: updatedSubs,
      selectedNode: newSelected,
    );
    _persist();
  }

  void deleteManualNode(String id) {
    final updatedManual = state.manualNodes.where((n) => n.id != id).toList();
    VlessNode? newSelected = state.selectedNode;
    if (state.selectedNode?.id == id) {
      newSelected = updatedManual.isNotEmpty
          ? updatedManual.first
          : (state.subscriptions.isNotEmpty && state.subscriptions.first.nodes.isNotEmpty
              ? state.subscriptions.first.nodes.first
              : null);
    }

    state = state.copyWith(
      manualNodes: updatedManual,
      selectedNode: newSelected,
    );
    _persist();
  }

  Future<void> pingAllNodes() async {
    if (state.status == CoreState.connected) {
      await _xrayService.stop();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    state = state.copyWith(isTestingPing: true);

    final updatedSubs = <SubscriptionModel>[];
    for (final sub in state.subscriptions) {
      final updatedNodes = <VlessNode>[];
      for (final node in sub.nodes) {
        final ping = await SubscriptionService.pingNode(
          node,
          pingUrl: state.settings.pingUrl,
          timeoutMs: state.settings.pingTimeoutMs,
        );
        updatedNodes.add(node.copyWith(pingMs: ping));
      }
      updatedSubs.add(sub.copyWith(nodes: updatedNodes));
    }

    final updatedManual = <VlessNode>[];
    for (final node in state.manualNodes) {
      final ping = await SubscriptionService.pingNode(
        node,
        pingUrl: state.settings.pingUrl,
        timeoutMs: state.settings.pingTimeoutMs,
      );
      updatedManual.add(node.copyWith(pingMs: ping));
    }

    state = state.copyWith(
      subscriptions: updatedSubs,
      manualNodes: updatedManual,
      isTestingPing: false,
    );
    await _persist();
  }

  Future<void> toggleConnection() async {
    if (state.status == CoreState.connected) {
      await _xrayService.stop();
    } else if (state.selectedNode != null && state.status != CoreState.connecting) {
      await _xrayService.start(state.selectedNode!, state.settings);
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _autoUpdateCheckTimer?.cancel();
    super.dispose();
  }
}

final xrayServiceProvider = Provider((ref) => XrayService());

final vpnProvider = StateNotifierProvider<VpnNotifier, VpnState>((ref) {
  return VpnNotifier(ref.watch(xrayServiceProvider));
});
