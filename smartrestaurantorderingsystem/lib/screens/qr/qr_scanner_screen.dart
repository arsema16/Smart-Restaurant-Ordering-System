import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../providers/session_provider.dart';
import '../menu/menu_screen.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() =>
      _QRScannerScreenState();
}

class _QRScannerScreenState
    extends ConsumerState<QRScannerScreen> {

  bool isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Table QR")),
      body: Stack(
        children: [

          // 📷 CAMERA
          MobileScanner(
            onDetect: (BarcodeCapture capture) async {
              if (isScanned) return;

              final barcodes = capture.barcodes;

              if (barcodes.isEmpty) return;

              final String? code = barcodes.first.rawValue;

              if (code == null) return;

              setState(() {
                isScanned = true;
              });

              try {
                await ref
                    .read(sessionProvider.notifier)
                    .createSession(code);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MenuScreen(),
                  ),
                );

              } catch (e) {
                setState(() {
                  isScanned = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
          ),

          // 🔲 DARK OVERLAY
          Container(
            color: Colors.black.withOpacity(0.4),
          ),

          // 📦 SCAN BOX
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // 📝 TEXT
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              "Scan QR on your table",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}