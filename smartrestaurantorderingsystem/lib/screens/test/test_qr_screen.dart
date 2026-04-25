import 'package:flutter/material.dart';

/// Test screen to simulate scanning a QR code
/// This helps test the flow without needing to actually scan a QR code
class TestQRScreen extends StatefulWidget {
  const TestQRScreen({super.key});

  @override
  State<TestQRScreen> createState() => _TestQRScreenState();
}

class _TestQRScreenState extends State<TestQRScreen> {
  final TextEditingController _tableController = TextEditingController(text: 'table-1');

  void _simulateScan() {
    final tableId = _tableController.text.trim();
    if (tableId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a table ID')),
      );
      return;
    }

    // Navigate to splash screen with table ID (simulating QR scan)
    Navigator.pushReplacementNamed(
      context,
      '/',
      arguments: {'table': tableId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test QR Scan'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.bug_report,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Test Mode',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Simulate scanning a QR code',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            TextField(
              controller: _tableController,
              decoration: const InputDecoration(
                labelText: 'Table ID',
                hintText: 'e.g., table-1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.table_restaurant),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _simulateScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Simulate QR Scan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange,
              ),
            ),
            const SizedBox(height: 48),
            const Card(
              color: Colors.orange,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'This simulates what happens when a guest scans a QR code with their phone camera',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
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
