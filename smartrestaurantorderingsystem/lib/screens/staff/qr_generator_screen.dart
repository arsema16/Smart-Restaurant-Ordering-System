import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Staff screen to generate QR codes for tables
class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  final TextEditingController _tableController = TextEditingController();
  String? _generatedUrl;

  // Base URL of your web app (update with actual domain)
  static const String baseUrl = 'https://restaurant.com';

  void _generateQRCode() {
    final tableId = _tableController.text.trim();
    if (tableId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a table identifier')),
      );
      return;
    }

    setState(() {
      _generatedUrl = '$baseUrl/?table=$tableId';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Table QR Codes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Generate QR Code for Table',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _tableController,
              decoration: const InputDecoration(
                labelText: 'Table Identifier',
                hintText: 'e.g., table-1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _generateQRCode,
              child: const Text('Generate QR Code'),
            ),
            const SizedBox(height: 32),

            if (_generatedUrl != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      QrImageView(
                        data: _generatedUrl!,
                        version: QrVersions.auto,
                        size: 300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _tableController.text,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
