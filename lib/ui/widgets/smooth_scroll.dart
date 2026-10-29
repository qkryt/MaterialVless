import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Кастомный ScrollController с плавной интерполяцией прокрутки колесиком мыши (Smooth Scrolling)
class SmoothScrollController extends ScrollController {
  SmoothScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    this.duration = const Duration(milliseconds: 240),
    this.curve = Curves.easeOutCubic,
  });

  final Duration duration;
  final Curve curve;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _SmoothScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      debugLabel: debugLabel,
      duration: duration,
      curve: curve,
    );
  }
}

class _SmoothScrollPosition extends ScrollPositionWithSingleContext {
  _SmoothScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    super.initialPixels,
    super.keepScrollOffset,
    super.debugLabel,
    required this.duration,
    required this.curve,
  });

  final Duration duration;
  final Curve curve;
  double? _targetPixels;

  @override
  void pointerScroll(double delta) {
    if (delta == 0.0) {
      goBallistic(0.0);
      return;
    }

    final double base = _targetPixels ?? pixels;
    final double target = (base + delta).clamp(minScrollExtent, maxScrollExtent);
    if (target == pixels) {
      _targetPixels = null;
      return;
    }

    _targetPixels = target;

    animateTo(
      target,
      duration: duration,
      curve: curve,
    ).whenComplete(() {
      if (_targetPixels == target) {
        _targetPixels = null;
      }
    });
  }

  @override
  void jumpTo(double value) {
    _targetPixels = null;
    super.jumpTo(value);
  }
}

/// Поведение прокрутки для Desktop с поддержкой жестов мыши и мягкой физики
class SmoothScrollBehavior extends MaterialScrollBehavior {
  const SmoothScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

/// Обертка для горизонтальной прокрутки: транслирует вертикальное колесо мыши в горизонтальную плавную прокрутку
class HorizontalSmoothScroll extends StatelessWidget {
  final Widget child;
  final ScrollController controller;

  const HorizontalSmoothScroll({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final delta = pointerSignal.scrollDelta.dy != 0
              ? pointerSignal.scrollDelta.dy
              : pointerSignal.scrollDelta.dx;
          if (delta != 0 && controller.hasClients) {
            controller.position.pointerScroll(delta);
          }
        }
      },
      child: child,
    );
  }
}
