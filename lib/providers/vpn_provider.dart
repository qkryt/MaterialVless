import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vless_node.dart';
import '../models/subscription_info.dart';
import '../services/xray_service.dart';
import '../services/subscription_service.dart';

class VpnState {
  final CoreState status;
  final NetworkMode mode;
  final VlessNode? selectedNode;
  final List<VlessNode> nodes;
  final SubscriptionInfo? subscriptionInfo;
  final int uploadSpeedBps;
  final int downloadSpeedBps;

  VpnState({
    this.status = CoreState.disconnected,
    this.mode = NetworkMode.tun,
    this.selectedNode,
    this.nodes = const [],
    this.subscriptionInfo,
    this.uploadSpeedBps = 0,
    this.downloadSpeedBps = 0,
  });

  VpnState copyWith({
    CoreState? status,
    NetworkMode? mode,
    VlessNode? selectedNode,
    List<VlessNode>? nodes,
    SubscriptionInfo? subscriptionInfo,
    int? uploadSpeedBps,
    int? downloadSpeedBps,
  }) {
    return VpnState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      selectedNode: selectedNode ?? this.selectedNode,
      nodes: nodes ?? this.nodes,
      subscriptionInfo: subscriptionInfo ?? this.subscriptionInfo,
      uploadSpeedBps: uploadSpeedBps ?? this.uploadSpeedBps,
      downloadSpeedBps: downloadSpeedBps ?? this.downloadSpeedBps,
    );
  }
}

class VpnNotifier extends StateNotifier<VpnState> {
  final XrayService _xrayService;

  VpnNotifier(this._xrayService) : super(VpnState()) {
    _xrayService.stateStream.listen((status) {
      state = state.copyWith(status: status);
    });

    _xrayService.speedStream.listen((speeds) {
      state = state.copyWith(
        uploadSpeedBps: speeds.$1,
        downloadSpeedBps: speeds.$2,
      );
    });
  }

  void setMode(NetworkMode mode) {
    if (state.status == CoreState.disconnected) {
      state = state.copyWith(mode: mode);
    }
  }

  void selectNode(VlessNode node) {
    state = state.copyWith(selectedNode: node);
  }

  Future<void> updateSubscription(String url) async {
    final (nodes, info) = await SubscriptionService.fetchSubscription(url);
    state = state.copyWith(
      nodes: nodes,
      subscriptionInfo: info,
      selectedNode: nodes.isNotEmpty ? nodes.first : null,
    );
  }

  Future<void> pingAllNodes() async {
    final updatedList = <VlessNode>[];
    for (final node in state.nodes) {
      final delay = await SubscriptionService.pingNode(node);
      updatedList.add(node.copyWith(pingMs: delay));
    }
    state = state.copyWith(
      nodes: updatedList,
      selectedNode: state.selectedNode != null
          ? updatedList.firstWhere(
              (n) => n.id == state.selectedNode!.id,
              orElse: () => updatedList.first,
            )
          : null,
    );
  }

  Future<void> toggleConnection() async {
    if (state.status == CoreState.connected) {
      await _xrayService.stop(state.mode);
    } else if (state.status == CoreState.disconnected && state.selectedNode != null) {
      await _xrayService.start(state.selectedNode!, state.mode);
    }
  }
}

final xrayServiceProvider = Provider((ref) => XrayService());

final vpnProvider = StateNotifierProvider<VpnNotifier, VpnState>((ref) {
  return VpnNotifier(ref.watch(xrayServiceProvider));
});