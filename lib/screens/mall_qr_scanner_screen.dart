import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';

class MallQrScannerScreen extends StatefulWidget {
  const MallQrScannerScreen({super.key});

  @override
  State<MallQrScannerScreen> createState() => _MallQrScannerScreenState();
}

class _MallQrScannerScreenState extends State<MallQrScannerScreen> {
  late MobileScannerController _controller;
  bool _handled = false;
  bool _isTorchOn = false;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _extractMallId(String raw) {
    final s = raw.trim();

    final direct = RegExp(r'^\d{8}[A-Za-z]{2}\d{2}$');
    if (direct.hasMatch(s)) return s.toUpperCase();

    final match = RegExp(r'(\d{8}[A-Za-z]{2}\d{2})').firstMatch(s);
    if (match != null) return match.group(1)!.toUpperCase();

    return null;
  }

  Future<void> _triggerScanFeedback() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 150);
      }
    } catch (_) {}

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || !_isScanning) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    final mallId = _extractMallId(raw);
    if (mallId == null) return;

    _handled = true;
    _isScanning = false;
    _controller.stop();

    _triggerScanFeedback();

    Navigator.pop(context, mallId);
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Torch error: $e')),
      );
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _controller.switchCamera();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Mall QR Code"),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Toggle Torch',
          ),
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.camera_front_outlined),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      size: 48,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Camera Error',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Unable to access camera. Please check permissions.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Animated scanning frame
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  width: 3,
                  color: Colors.white.withOpacity(_isScanning ? 0.9 : 0.7),
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (_isScanning)
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                ],
              ),
            ),
          ),
          // Animated corner brackets
          if (_isScanning)
            Positioned(
              top: 50,
              left: 60,
              child: _buildCornerBracket(
                color: Colors.blue[400]!,
                isTopLeft: true,
              ),
            ),
          if (_isScanning)
            Positioned(
              top: 50,
              right: 60,
              child: _buildCornerBracket(
                color: Colors.blue[400]!,
                isTopLeft: false,
              ),
            ),
          // Bottom instruction panel
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Position QR Code inside the frame",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isScanning ? "Ready to scan..." : "Processing...",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isScanning ? Colors.blue[300] : Colors.orange[300],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerBracket({
    required Color color,
    required bool isTopLeft,
  }) {
    return SizedBox(
      width: 30,
      height: 30,
      child: CustomPaint(
        painter: _CornerBracketPainter(color: color, isTopLeft: isTopLeft),
      ),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final bool isTopLeft;

  _CornerBracketPainter({required this.color, required this.isTopLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    if (isTopLeft) {
      canvas.drawLine(const Offset(0, 10), const Offset(0, 0), paint);
      canvas.drawLine(const Offset(0, 0), const Offset(10, 0), paint);
    } else {
      canvas.drawLine(Offset(size.width, 10), Offset(size.width, 0), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width - 10, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerBracketPainter oldDelegate) => false;
}
