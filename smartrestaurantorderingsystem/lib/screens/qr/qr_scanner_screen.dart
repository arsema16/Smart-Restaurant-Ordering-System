import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../providers/session_provider.dart';
import '../menu/menu_screen.dart';

class QRScannerScreen extends ConsumerWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Table QR")),
      body: MobileScanner(
        onDetect: (barcode, args) async {
          final String? code = barcode.rawValue;

          if (code == null) return;

          try {
            // 👉 Use scanned value as table ID
            await ref
                .read(sessionProvider.notifier)
                .createSession(code);

            // 👉 Go to menu
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const MenuScreen(),
              ),
            );

          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: $e")),
            );
          }
        },
      ),
    );
  }
}

extension on BarcodeCapture {
  String? get rawValue => null;
}