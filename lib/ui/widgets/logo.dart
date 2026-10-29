import 'package:flutter/material.dart';

class MaterialVlessLogo extends StatelessWidget {
  final double size;
  final bool animate;

  const MaterialVlessLogo({
    super.key,
    this.size = 32,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final tertiary = theme.colorScheme.tertiary;

    return CustomPaint(
      size: Size(size, size),
      painter: _MaterialYouLogoPainter(
        primaryColor: primary,
        accentColor: tertiary,
      ),
    );
  }
}

class _MaterialYouLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  _MaterialYouLogoPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Скругленный плавный Squircle в стиле Material You
    final r = w * 0.28;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(r),
    );

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor,
          accentColor,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, bgPaint);

    // 2. Мягкие пастельные блики
    final blobPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.75, h * 0.25), w * 0.35, blobPaint);

    // 3. Центральное ядро / точка соединения
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.50, h * 0.40), w * 0.12, corePaint);

    final innerCorePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.50, h * 0.40), w * 0.06, innerCorePaint);

    // 4. Плавная лента Material You "M" и "V"
    final ribbonPath = Path()
      ..moveTo(w * 0.22, h * 0.36)
      ..cubicTo(w * 0.26, h * 0.56, w * 0.38, h * 0.76, w * 0.50, h * 0.76)
      ..cubicTo(w * 0.62, h * 0.76, w * 0.74, h * 0.56, w * 0.78, h * 0.36);

    final ribbonShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.20)
      ..strokeWidth = w * 0.13
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(ribbonPath, ribbonShadowPaint);

    final ribbonPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.105
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(ribbonPath, ribbonPaint);
  }

  @override
  bool shouldRepaint(covariant _MaterialYouLogoPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor || oldDelegate.accentColor != accentColor;
  }
}
