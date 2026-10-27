import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vless_node.dart';
import '../models/subscription_model.dart';
import '../models/app_settings.dart';
import '../services/xray_service.dart';
import '../services/subscription_service.dart';

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
  final bool hideEverything;

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
    this.currentPingMs = 356,
    this.hideEverything = false,
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
    bool? hideEverything,
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
      hideEverything: hideEverything ?? this.hideEverything,
    );
  }
}

class VpnNotifier extends StateNotifier<VpnState> {
  final XrayService _xrayService;
  Timer? _sessionTimer;

  VpnNotifier(this._xrayService) : super(VpnState(settings: AppSettings())) {
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

    if (state.settings.autoUpdateRulesOnStart) {
      SubscriptionService.updateGeoDatabases(
        targetDir: '.',
        geoipUrl: state.settings.geoipUrl,
        geositeUrl: state.settings.geositeUrl,
      );
    }
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

  void toggleHideEverything() {
    state = state.copyWith(hideEverything: !state.hideEverything);
  }

  void toggleSubscriptionExpanded(String subId) {
    final updated = state.subscriptions.map((s) {
      if (s.id == subId) {
        return s.copyWith(isExpanded: !s.isExpanded);
      }
      return s;
    }).toList();
    state = state.copyWith(subscriptions: updated);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectNode(VlessNode node) {
    state = state.copyWith(selectedNode: node);
  }

  void updateSettings(AppSettings newSettings) {
    state = state.copyWith(settings: newSettings);
  }

  Future<void> addSubscription(String source, {String? customName}) async {
    final (nodes, meta) = await SubscriptionService.loadSubscription(
      source: source,
      settings: state.settings,
      customName: customName,
    );

    final isUrl = source.startsWith('http://') || source.startsWith('https://');
    final name = customName ?? (isUrl ? Uri.parse(source).host : 'Импортированные узлы');

    final newSub = SubscriptionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      url: source,
      lastUpdated: DateTime.now(),
      uploadBytes: meta['upload'] ?? 0,
      downloadBytes: meta['download'] ?? 0,
      totalBytes: meta['total'] ?? 0,
      expireDate: meta['expire'],
      nodes: nodes,
      isExpanded: true,
      announcements: const [
        'Подключим Вас к миру',
        'Не используйте LTE сервера на WiFi',
      ],
    );

    final updatedSubs = List<SubscriptionModel>.from(state.subscriptions)..add(newSub);

    state = state.copyWith(
      subscriptions: updatedSubs,
      selectedNode: state.selectedNode ?? (nodes.isNotEmpty ? nodes.first : null),
    );
  }

  Future<void> refreshSubscription(String id) async {
    final index = state.subscriptions.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final target = state.subscriptions[index];
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

    state = state.copyWith(subscriptions: updatedSubs);
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
  }

  Future<void> toggleConnection() async {
    if (state.status == CoreState.connected) {
      await _xrayService.stop();
    } else if (state.status == CoreState.disconnected && state.selectedNode != null) {
      await _xrayService.start(state.selectedNode!, state.settings);
    }
  }
}

final xrayServiceProvider = Provider((ref) => XrayService());

final vpnProvider = StateNotifierProvider<VpnNotifier, VpnState>((ref) {
  return VpnNotifier(ref.watch(xrayServiceProvider));
});
