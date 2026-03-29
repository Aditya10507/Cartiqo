import 'package:flutter/material.dart';

class SwiftCartLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final Color? primaryColor;
  final Color? accentColor;
  final Color? backgroundColor;
  final Color? wordmarkColor;

  const SwiftCartLogo({
    super.key,
    this.size = 88,
    this.showWordmark = true,
    this.primaryColor,
    this.accentColor,
    this.backgroundColor,
    this.wordmarkColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? const Color(0xFF0B5ED7);
    final accent = accentColor ?? const Color(0xFF12B886);
    final background = backgroundColor ?? Colors.white;
    final textColor = wordmarkColor ?? Colors.white;

    final mark = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SwiftCartLogoPainter(
          primary: primary,
          accent: accent,
          background: background,
        ),
      ),
    );

    if (!showWordmark) {
      return mark;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(height: size * 0.18),
        Text(
          'Cartiqo',
          style: TextStyle(
            fontSize: size * 0.30,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _SwiftCartLogoPainter extends CustomPainter {
  final Color primary;
  final Color accent;
  final Color background;

  const _SwiftCartLogoPainter({
    required this.primary,
    required this.accent,
    required this.background,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.width * 0.28);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(Offset(0, size.height * 0.04)),
        radius,
      ),
      shadowPaint,
    );

    final shellPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, accent],
      ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      shellPaint,
    );

    final whitePaint = Paint()..color = background;
    final cartBody = RRect.fromLTRBR(
      size.width * 0.19,
      size.height * 0.28,
      size.width * 0.76,
      size.height * 0.58,
      Radius.circular(size.width * 0.08),
    );
    canvas.drawRRect(cartBody, whitePaint);

    final handlePaint = Paint()
      ..color = background
      ..strokeWidth = size.width * 0.08
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final handlePath = Path()
      ..moveTo(size.width * 0.23, size.height * 0.30)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.16,
        size.width * 0.42,
        size.height * 0.18,
      );
    canvas.drawPath(handlePath, handlePaint);

    final wheelPaint = Paint()..color = background;
    canvas.drawCircle(
      Offset(size.width * 0.33, size.height * 0.72),
      size.width * 0.075,
      wheelPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.72),
      size.width * 0.075,
      wheelPaint,
    );

    final boltPaint = Paint()..color = const Color(0xFFFFC83D);
    final bolt = Path()
      ..moveTo(size.width * 0.53, size.height * 0.18)
      ..lineTo(size.width * 0.41, size.height * 0.43)
      ..lineTo(size.width * 0.53, size.height * 0.43)
      ..lineTo(size.width * 0.45, size.height * 0.66)
      ..lineTo(size.width * 0.67, size.height * 0.36)
      ..lineTo(size.width * 0.54, size.height * 0.36)
      ..close();
    canvas.drawPath(bolt, boltPaint);
  }

  @override
  bool shouldRepaint(covariant _SwiftCartLogoPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.accent != accent ||
        oldDelegate.background != background;
  }
}
