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
      painter: _LogoPainter(
        primaryColor: primary,
        accentColor: tertiary,
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  _LogoPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Внешний щит / шестиугольная защитная форма
    final shieldPath = Path()
      ..moveTo(w * 0.5, h * 0.04)
      ..lineTo(w * 0.94, h * 0.26)
      ..lineTo(w * 0.94, h * 0.62)
      ..lineTo(w * 0.5, h * 0.96)
      ..lineTo(w * 0.06, h * 0.62)
      ..lineTo(w * 0.06, h * 0.26)
      ..close();

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor.withOpacity(0.25),
          accentColor.withOpacity(0.08),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryColor, accentColor],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(shieldPath, bgPaint);
    canvas.drawPath(shieldPath, borderPaint);

    // Внутренний символ скоростного туннеля "V"
    final vPath = Path()
      ..moveTo(w * 0.28, h * 0.35)
      ..lineTo(w * 0.5, h * 0.72)
      ..lineTo(w * 0.72, h * 0.35);

    final vPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, accentColor],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(vPath, vPaint);

    // Центральная точка узла связи
    final dotPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.5, h * 0.35), w * 0.07, dotPaint);

    final innerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.5, h * 0.35), w * 0.035, innerDotPaint);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor || oldDelegate.accentColor != accentColor;
  }
}
