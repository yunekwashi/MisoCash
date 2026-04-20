import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController controller;
  bool _isProcessing = false;
  final bool _isWindows = Platform.isWindows;

  @override
  void initState() {
    super.initState();
    if (!_isWindows) {
      controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    }
  }

  @override
  void dispose() {
    if (!_isWindows) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      _processCode(barcodes.first.rawValue!);
    }
  }

  void _processCode(String code) {
    setState(() {
      _isProcessing = true;
    });
    if (!_isWindows) {
      controller.stop();
    }
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Merchant QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          if (!_isWindows)
            MobileScanner(
              controller: controller,
              onDetect: _onDetect,
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off, color: Colors.grey, size: 80),
                  const SizedBox(height: 16),
                  const Text(
                    'Camera simulated on Windows.\nWill use real camera on Android/iOS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => _processCode('Windows Simulated QR Data'),
                    child: const Text('Simulate Scan Detected'),
                  ),
                ],
              ),
            ),
          
          if (!_isWindows)
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryBlue, width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(21),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          if (!_isWindows)
            const Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                'Align the QR code within the frame to process payment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  backgroundColor: Colors.black45,
                ),
              ),
            ),
          
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryBlue),
                    SizedBox(height: 16),
                    Text('Processing Code...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}

