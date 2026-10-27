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
  });

  List<VlessNode> get allNodes {
    final list = <VlessNode>[];
    for (final sub in subscriptions) {
      list.addAll(sub.nodes);
    }
    list.addAll(manualNodes);
    return list;
  }

  List<VlessNode> get filteredNodes {
    if (searchQuery.trim().isEmpty) return allNodes;
    final q = searchQuery.toLowerCase();
    return allNodes.where((n) {
      return n.remark.toLowerCase().contains(q) ||
          n.address.toLowerCase().contains(q) ||
          n.sni.toLowerCase().contains(q);
    }).toList();
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
    );
  }
}

class VpnNotifier extends StateNotifier<VpnState> {
  final XrayService _xrayService;

  VpnNotifier(this._xrayService) : super(VpnState(settings: AppSettings())) {
    _xrayService.stateStream.listen((status) {
      state = state.copyWith(status: status);
    });

    _xrayService.speedStream.listen((speeds) {
      state = state.copyWith(
        uploadSpeedBps: speeds.$1,
        downloadSpeedBps: speeds.$2,
      );
    });

    // Автообновление баз GeoIP / GeoSite на старте
    if (state.settings.autoUpdateRulesOnStart) {
      SubscriptionService.updateGeoDatabases(
        targetDir: '.',
        geoipUrl: state.settings.geoipUrl,
        geositeUrl: state.settings.geositeUrl,
      );
    }
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

  /// Добавление подписки из URL, .txt файла или прямой ссылки
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
    );

    final updatedSubs = List<SubscriptionModel>.from(state.subscriptions)..add(newSub);

    state = state.copyWith(
      subscriptions: updatedSubs,
      selectedNode: state.selectedNode ?? (nodes.isNotEmpty ? nodes.first : null),
    );
  }

  /// Обновление конкретной подписки
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

  /// Тестирование пинга всех серверов
  /// Требование: прежде чем пинговать все сервера в подписке нужно отключить VPN!
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

  /// Тест скорости для выбранного узла
  Future<void> testCurrentNodeSpeed() async {
    if (state.selectedNode == null) return;
    final (down, up) = await SubscriptionService.testSpeed(
      speedtestUrl: state.settings.speedtestUrl,
      timeoutMs: state.settings.pingTimeoutMs,
    );
    final updated = state.selectedNode!.copyWith(
      downloadSpeedMs: down,
      uploadSpeedMs: up,
    );
    state = state.copyWith(selectedNode: updated);
  }

  /// Подключение / Отключение (единый режим TUN + системный прокси)
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
