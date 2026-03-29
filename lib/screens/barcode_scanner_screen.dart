import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _handled = false;
  bool _isTorchOn = false;
  bool _isScanning = true;
  bool _isFrameGlowing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.itf,
        BarcodeFormat.codabar,
      ],
      facing: CameraFacing.back,
    );

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool _looksLikeMallId(String s) {
    return RegExp(r'^\d{8}[A-Za-z]{2}\d{2}$').hasMatch(s.trim());
  }

  Future<void> _triggerScanFeedback() async {
    // Haptic feedback
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 200);
      }
    } catch (_) {}

    // System haptic feedback
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}

    // Optional audio
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || !_isScanning) return;

    for (final b in capture.barcodes) {
      final raw = b.rawValue?.trim();
      if (raw == null || raw.isEmpty) continue;

      // Ignore anything that looks like a mall QR payload.
      if (_looksLikeMallId(raw)) continue;

      _handled = true;
      _isScanning = false;
      _controller.stop();
      
      _triggerScanFeedback();
      _showSuccessAnimation();

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pop(context, raw);
        }
      });
      return;
    }
  }

  void _showSuccessAnimation() {
    setState(() => _isFrameGlowing = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isFrameGlowing = false);
      }
    });
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      setState(() => _isTorchOn = !_isTorchOn);
      HapticFeedback.lightImpact();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Torch error: $e')),
      );
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _controller.switchCamera();
      HapticFeedback.lightImpact();
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
        title: const Text("Scan Product Barcode"),
        elevation: 0,
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Icon(
                  _isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: _isTorchOn ? Colors.amber : Colors.white,
                );
              },
            ),
            tooltip: 'Toggle Torch',
          ),
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.cameraswitch),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera feed
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
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
          // Animated scanning frame with corner highlights
          Center(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
              },
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 320,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 3,
                        color: _isFrameGlowing
                            ? Colors.green
                            : Colors.white.withOpacity(0.8),
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (_isScanning && !_isFrameGlowing)
                          BoxShadow(
                            color: Colors.green.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        if (_isFrameGlowing)
                          BoxShadow(
                            color: Colors.green.withOpacity(0.8),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Corner highlights
          if (_isScanning) ..._buildCornerHighlights(),
          // Animated scanning line
          if (_isScanning && !_isFrameGlowing)
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: -80.0, end: 80.0),
                duration: const Duration(milliseconds: 1200),
                onEnd: () {},
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, value),
                    child: Container(
                      width: 320,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.green.withOpacity(0),
                            Colors.green,
                            Colors.green.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          // Success animation overlay
          if (_isFrameGlowing)
            Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.2).animate(
                  CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
                ),
                child: Container(
                  width: 320,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.green.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                ),
              ),
            ),
          // Bottom instruction panel
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isFrameGlowing
                    ? Colors.green.withOpacity(0.9)
                    : Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isFrameGlowing ? Colors.green : Colors.grey[700]!,
                  width: 2,
                ),
                boxShadow: [
                  if (_isFrameGlowing)
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isScanning && !_isFrameGlowing)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        )
                      else if (_isFrameGlowing)
                        const Icon(Icons.check_circle, color: Colors.white)
                      else
                        const Icon(Icons.hourglass_empty, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        _isFrameGlowing
                            ? "Barcode detected!"
                            : _isScanning
                                ? "Ready to scan..."
                                : "Processing...",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Position barcode inside the frame",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
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

  List<Widget> _buildCornerHighlights() {
    const size = 24.0;
    const thickness = 3.0;
    
    return [
      // Top-left corner
      Positioned(
        left: 160 - 160,
        top: 240 - 80,
        child: _CornerHighlight(
          size: size,
          thickness: thickness,
          isGlowing: _isFrameGlowing,
          topLeft: true,
        ),
      ),
      // Top-right corner
      Positioned(
        right: 160 - 160,
        top: 240 - 80,
        child: _CornerHighlight(
          size: size,
          thickness: thickness,
          isGlowing: _isFrameGlowing,
          topRight: true,
        ),
      ),
      // Bottom-left corner
      Positioned(
        left: 160 - 160,
        bottom: 200 - 80,
        child: _CornerHighlight(
          size: size,
          thickness: thickness,
          isGlowing: _isFrameGlowing,
          bottomLeft: true,
        ),
      ),
      // Bottom-right corner
      Positioned(
        right: 160 - 160,
        bottom: 200 - 80,
        child: _CornerHighlight(
          size: size,
          thickness: thickness,
          isGlowing: _isFrameGlowing,
          bottomRight: true,
        ),
      ),
    ];
  }
}

class _CornerHighlight extends StatelessWidget {
  final double size;
  final double thickness;
  final bool isGlowing;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  const _CornerHighlight({
    required this.size,
    required this.thickness,
    required this.isGlowing,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isGlowing ? Colors.green : Colors.white;
    final opacity = isGlowing ? 1.0 : 0.7;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        boxShadow: [
          if (isGlowing)
            BoxShadow(
              color: Colors.green.withOpacity(0.6),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          opacity: opacity,
          thickness: thickness,
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double thickness;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  _CornerPainter({
    required this.color,
    required this.opacity,
    required this.thickness,
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    const cornerLength = 8.0;

    if (topLeft) {
      canvas.drawLine(
        const Offset(0, cornerLength),
        Offset.zero,
        paint,
      );
      canvas.drawLine(
        Offset.zero,
        const Offset(cornerLength, 0),
        paint,
      );
    }

    if (topRight) {
      canvas.drawLine(
        Offset(size.width, cornerLength),
        Offset(size.width, 0),
        paint,
      );
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width - cornerLength, 0),
        paint,
      );
    }

    if (bottomLeft) {
      canvas.drawLine(
        Offset(0, size.height - cornerLength),
        Offset(0, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, size.height),
        Offset(cornerLength, size.height),
        paint,
      );
    }

    if (bottomRight) {
      canvas.drawLine(
        Offset(size.width, size.height - cornerLength),
        Offset(size.width, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(size.width, size.height),
        Offset(size.width - cornerLength, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) {
    return oldDelegate.opacity != opacity || oldDelegate.isGlowing != isGlowing;
  }

  bool get isGlowing => opacity > 0.7;
}
