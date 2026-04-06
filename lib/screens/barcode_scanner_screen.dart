import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late final MobileScannerController _controller;
  bool _handled = false;
  bool _isTorchOn = false;
  bool _isScanning = true;
  bool _isProcessing = false;

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
        BarcodeFormat.itf14,
        BarcodeFormat.codabar,
      ],
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _looksLikeMallId(String value) {
    return RegExp(r'^\d{8}[A-Za-z]{2}\d{2}$').hasMatch(value.trim());
  }

  Future<void> _triggerScanFeedback() async {
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 200);
      }
    } catch (_) {}

    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}

    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || !_isScanning) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw == null || raw.isEmpty) continue;
      if (_looksLikeMallId(raw)) continue;

      _handled = true;
      _isScanning = false;
      _isProcessing = true;
      _controller.stop();
      _triggerScanFeedback();

      if (mounted) {
        setState(() {});
      }

      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          Navigator.pop(context, raw);
        }
      });
      return;
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) {
        setState(() => _isTorchOn = !_isTorchOn);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Torch error: $error')));
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _controller.switchCamera();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Camera error: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Torch',
          ),
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.cameraswitch_outlined),
            tooltip: 'Switch camera',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.camera_alt_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Unable to access camera',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please check camera permission and try again.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                IgnorePointer(
                  child: Container(
                    width: 280,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isProcessing ? Colors.green : Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isProcessing ? 'Processing barcode...' : 'Scan a product barcode',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hold the barcode inside the box. The scanner will detect it automatically.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _toggleTorch,
                        icon: Icon(
                          _isTorchOn ? Icons.flash_on : Icons.flash_off,
                        ),
                        label: Text(_isTorchOn ? 'Torch On' : 'Torch Off'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _switchCamera,
                        icon: const Icon(Icons.cameraswitch_outlined),
                        label: const Text('Switch Camera'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
