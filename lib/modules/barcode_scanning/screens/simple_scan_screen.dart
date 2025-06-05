import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SimpleScanScreen extends StatefulWidget {
  final Function(String) onDetect;

  const SimpleScanScreen({super.key, required this.onDetect});

  @override
  State<SimpleScanScreen> createState() => _SimpleScanScreenState();
}

class _SimpleScanScreenState extends State<SimpleScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () => _controller.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: (barcodeCapture) {
          if (_hasScanned) return;
          final code = barcodeCapture.barcodes.first.rawValue;
          if (code != null && code.isNotEmpty) {
            _hasScanned = true;
            widget.onDetect(code); // Trigger action
          }
        },
      ),
    );
  }
}
