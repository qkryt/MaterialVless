import 'package:flutter/material.dart';

class CountryFlagWidget extends StatelessWidget {
  final String isoCode;
  final double width;
  final double height;

  const CountryFlagWidget({
    super.key,
    required this.isoCode,
    this.width = 28,
    this.height = 19,
  });

  @override
  Widget build(BuildContext context) {
    final code = isoCode.toUpperCase().trim();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        size: Size(width, height),
        painter: _CountryFlagPainter(code),
      ),
    );
  }
}

class _CountryFlagPainter extends CustomPainter {
  final String code;

  _CountryFlagPainter(this.code);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    switch (code) {
      // 🇩🇪 Германия: Чёрный, Красный, Золотой
      case 'DE':
        _drawHStripes(canvas, w, h, [
          const Color(0xFF000000),
          const Color(0xFFDD0000),
          const Color(0xFFFFCE00),
        ]);
        break;

      // 🇷🇺 Россия: Белый, Синий, Красный
      case 'RU':
        _drawHStripes(canvas, w, h, [
          const Color(0xFFFFFFFF),
          const Color(0xFF0039A6),
          const Color(0xFFD52B1E),
        ]);
        break;

      // 🇳🇱 Нидерланды: Красный, Белый, Синий
      case 'NL':
        _drawHStripes(canvas, w, h, [
          const Color(0xFFAE1C28),
          const Color(0xFFFFFFFF),
          const Color(0xFF21468B),
        ]);
        break;

      // 🇦🇹 Австрия: Красный, Белый, Красный
      case 'AT':
        _drawHStripes(canvas, w, h, [
          const Color(0xFFED2939),
          const Color(0xFFFFFFFF),
          const Color(0xFFED2939),
        ]);
        break;

      // 🇵🇱 Польша: Белый, Красный
      case 'PL':
        _drawHStripes(canvas, w, h, [
          const Color(0xFFFFFFFF),
          const Color(0xFFDC143C),
        ]);
        break;

      // 🇺🇦 Украина: Синий, Жёлтый
      case 'UA':
        _drawHStripes(canvas, w, h, [
          const Color(0xFF0057B7),
          const Color(0xFFFFDD00),
        ]);
        break;

      // 🇫🇮 Финляндия: Белый фон, Синий скандинавский крест
      case 'FI':
        canvas.drawRect(rect, Paint()..color = Colors.white);
        final crossPaint = Paint()..color = const Color(0xFF002F6C);
        final crossThick = h * 0.28;
        final vX = w * 0.35;
        canvas.drawRect(Rect.fromLTWH(0, (h - crossThick) / 2, w, crossThick), crossPaint);
        canvas.drawRect(Rect.fromLTWH(vX - crossThick / 2, 0, crossThick, h), crossPaint);
        break;

      // 🇸🇪 Швеция: Синий фон, Жёлтый скандинавский крест
      case 'SE':
        canvas.drawRect(rect, Paint()..color = const Color(0xFF005293));
        final crossPaint = Paint()..color = const Color(0xFFFECC00);
        final crossThick = h * 0.26;
        final vX = w * 0.36;
        canvas.drawRect(Rect.fromLTWH(0, (h - crossThick) / 2, w, crossThick), crossPaint);
        canvas.drawRect(Rect.fromLTWH(vX - crossThick / 2, 0, crossThick, h), crossPaint);
        break;

      // 🇫🇷 Франция: Синий, Белый, Красный
      case 'FR':
        _drawVStripes(canvas, w, h, [
          const Color(0xFF002654),
          const Color(0xFFFFFFFF),
          const Color(0xFFED2939),
        ]);
        break;

      // 🇮🇹 Италия: Зеленый, Белый, Красный
      case 'IT':
        _drawVStripes(canvas, w, h, [
          const Color(0xFF009246),
          const Color(0xFFFFFFFF),
          const Color(0xFFCE2B37),
        ]);
        break;

      // 🇪🇪 Эстония: Синий, Черный, Белый
      case 'EE':
        _drawHStripes(canvas, w, h, [
          const Color(0xFF0072CE),
          const Color(0xFF000000),
          const Color(0xFFFFFFFF),
        ]);
        break;

      // 🇱🇹 Литва: Желтый, Зеленый, Красный
      case 'LT':
        _drawHStripes(canvas, w, h, [
          const Color(0xFFFDB913),
          const Color(0xFF006A44),
          const Color(0xFFC1272D),
        ]);
        break;

      // 🇱🇻 Латвия: Кармин, Белый, Кармин
      case 'LV':
        canvas.drawRect(rect, Paint()..color = const Color(0xFF9E3039));
        canvas.drawRect(Rect.fromLTWH(0, h * 0.4, w, h * 0.2), Paint()..color = Colors.white);
        break;

      // 🇺🇸 США: Красно-белые полосы + Синий кантон со звездой
      case 'US':
        for (int i = 0; i < 7; i++) {
          final color = (i % 2 == 0) ? const Color(0xFFB22234) : Colors.white;
          canvas.drawRect(Rect.fromLTWH(0, i * (h / 7), w, h / 7), Paint()..color = color);
        }
        final cantonRect = Rect.fromLTWH(0, 0, w * 0.44, h * 0.58);
        canvas.drawRect(cantonRect, Paint()..color = const Color(0xFF3C3B6E));
        canvas.drawCircle(cantonRect.center, 2.5, Paint()..color = Colors.white);
        break;

      // 🇬🇧 Великобритания (UK / GB)
      case 'GB':
      case 'UK':
        canvas.drawRect(rect, Paint()..color = const Color(0xFF012169));
        final whitePaint = Paint()..color = Colors.white;
        final redPaint = Paint()..color = const Color(0xFFC8102E);
        canvas.drawLine(Offset.zero, Offset(w, h), whitePaint..strokeWidth = 3.5);
        canvas.drawLine(Offset(0, h), Offset(w, 0), whitePaint..strokeWidth = 3.5);
        canvas.drawLine(Offset.zero, Offset(w, h), redPaint..strokeWidth = 1.5);
        canvas.drawLine(Offset(0, h), Offset(w, 0), redPaint..strokeWidth = 1.5);
        canvas.drawRect(Rect.fromLTWH(0, h * 0.35, w, h * 0.3), whitePaint);
        canvas.drawRect(Rect.fromLTWH(w * 0.4, 0, w * 0.2, h), whitePaint);
        canvas.drawRect(Rect.fromLTWH(0, h * 0.4, w, h * 0.2), redPaint);
        canvas.drawRect(Rect.fromLTWH(w * 0.43, 0, w * 0.14, h), redPaint);
        break;

      // 🇨🇭 Швейцария
      case 'CH':
        canvas.drawRect(rect, Paint()..color = const Color(0xFFD52B1E));
        final cross = Paint()..color = Colors.white;
        canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * 0.6, height: h * 0.24), cross);
        canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * 0.24, height: h * 0.6), cross);
        break;

      // 🇯🇵 Япония
      case 'JP':
        canvas.drawRect(rect, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(w / 2, h / 2), h * 0.3, Paint()..color = const Color(0xFFBC002D));
        break;

      // 🇹🇷 Турция
      case 'TR':
        canvas.drawRect(rect, Paint()..color = const Color(0xFFE30A17));
        canvas.drawCircle(Offset(w * 0.42, h / 2), h * 0.28, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(w * 0.47, h / 2), h * 0.23, Paint()..color = const Color(0xFFE30A17));
        break;

      // 🇰🇿 Казахстан
      case 'KZ':
        canvas.drawRect(rect, Paint()..color = const Color(0xFF00AFCA));
        canvas.drawCircle(Offset(w / 2, h / 2), h * 0.25, Paint()..color = const Color(0xFFFEC50C));
        break;

      // 🇨🇦 Канада
      case 'CA':
        _drawVStripes(canvas, w, h, [
          const Color(0xFFFF0000),
          const Color(0xFFFFFFFF),
          const Color(0xFFFF0000),
        ]);
        canvas.drawCircle(Offset(w / 2, h / 2), h * 0.2, Paint()..color = const Color(0xFFFF0000));
        break;

      // Фолбэк на дефолтную плашку с кодом страны
      default:
        canvas.drawRect(rect, Paint()..color = const Color(0xFF2C313E));
        final textPainter = TextPainter(
          text: TextSpan(
            text: code.length <= 3 ? code : 'VPN',
            style: TextStyle(
              color: Colors.white,
              fontSize: h * 0.52,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset((w - textPainter.width) / 2, (h - textPainter.height) / 2),
        );
        break;
    }
  }

  void _drawHStripes(Canvas canvas, double w, double h, List<Color> colors) {
    final stripeH = h / colors.length;
    for (int i = 0; i < colors.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeH, w, stripeH),
        Paint()..color = colors[i],
      );
    }
  }

  void _drawVStripes(Canvas canvas, double w, double h, List<Color> colors) {
    final stripeW = w / colors.length;
    for (int i = 0; i < colors.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * stripeW, 0, stripeW, h),
        Paint()..color = colors[i],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CountryFlagPainter oldDelegate) => oldDelegate.code != code;
}
