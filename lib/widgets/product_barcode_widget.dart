import 'package:flutter/material.dart';

class ProductBarcodeWidget extends StatelessWidget {
  final String barcode;
  final double height;
  final bool showText;

  const ProductBarcodeWidget({
    super.key,
    required this.barcode,
    this.height = 120,
    this.showText = true,
  });

  bool get _isEan13 => RegExp(r'^\d{13}$').hasMatch(barcode);

  @override
  Widget build(BuildContext context) {
    if (!_isEan13) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.view_stream, size: 36),
            const SizedBox(height: 8),
            Text(
              barcode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Barcode preview is available for 13-digit EAN codes.',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _Ean13BarcodePainter(barcode),
            child: const SizedBox.expand(),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            _formatForDisplay(barcode),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }

  String _formatForDisplay(String value) {
    return '${value[0]} ${value.substring(1, 7)} ${value.substring(7)}';
  }
}

class _Ean13BarcodePainter extends CustomPainter {
  final String barcode;

  _Ean13BarcodePainter(this.barcode);

  static const List<String> _lPatterns = [
    '0001101',
    '0011001',
    '0010011',
    '0111101',
    '0100011',
    '0110001',
    '0101111',
    '0111011',
    '0110111',
    '0001011',
  ];

  static const List<String> _gPatterns = [
    '0100111',
    '0110011',
    '0011011',
    '0100001',
    '0011101',
    '0111001',
    '0000101',
    '0010001',
    '0001001',
    '0010111',
  ];

  static const List<String> _rPatterns = [
    '1110010',
    '1100110',
    '1101100',
    '1000010',
    '1011100',
    '1001110',
    '1010000',
    '1000100',
    '1001000',
    '1110100',
  ];

  static const List<String> _parityPatterns = [
    'LLLLLL',
    'LLGLGG',
    'LLGGLG',
    'LLGGGL',
    'LGLLGG',
    'LGGLLG',
    'LGGGLL',
    'LGLGLG',
    'LGLGGL',
    'LGGLGL',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final background = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, background);

    final pattern = _buildPattern(barcode);
    const quietModules = 9;
    final totalModules = pattern.length + (quietModules * 2);
    final moduleWidth = size.width / totalModules;
    final normalBarHeight = size.height * 0.82;
    final guardBarHeight = size.height * 0.92;

    double x = quietModules * moduleWidth;
    for (int i = 0; i < pattern.length; i++) {
      if (pattern[i] == '1') {
        final isGuard = i < 3 || (i >= 45 && i < 50) || i >= pattern.length - 3;
        canvas.drawRect(
          Rect.fromLTWH(
            x,
            0,
            moduleWidth,
            isGuard ? guardBarHeight : normalBarHeight,
          ),
          paint,
        );
      }
      x += moduleWidth;
    }
  }

  String _buildPattern(String value) {
    final firstDigit = int.parse(value[0]);
    final parity = _parityPatterns[firstDigit];

    final buffer = StringBuffer('101');

    for (int i = 1; i <= 6; i++) {
      final digit = int.parse(value[i]);
      buffer.write(parity[i - 1] == 'L' ? _lPatterns[digit] : _gPatterns[digit]);
    }

    buffer.write('01010');

    for (int i = 7; i <= 12; i++) {
      final digit = int.parse(value[i]);
      buffer.write(_rPatterns[digit]);
    }

    buffer.write('101');
    return buffer.toString();
  }

  @override
  bool shouldRepaint(covariant _Ean13BarcodePainter oldDelegate) {
    return oldDelegate.barcode != barcode;
  }
}
