import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../staff/qr_generator_screen.dart';

/// Welcome screen shown when no session exists
/// Provides options to scan QR code or access staff features
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // Default table for demo/testing
  static const String defaultTable = 'table-1';
  // Use your computer's IP address so phones on the same network can access it
  static const String baseUrl = 'http://10.163.23.62:8080';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Icon
              Icon(
                Icons.restaurant_menu,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Smart Restaurant',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Order from your table',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Guest Instructions with QR Code
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'For Guests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                        ),
                        child: QrImageView(
                          data: '$baseUrl/?table=$defaultTable',
                          version: QrVersions.auto,
                          size: 150,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      const Text(
                        'Scan this QR code with your phone camera to start ordering',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Table: $defaultTable',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Staff Button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QRGeneratorScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Staff: Generate QR Codes'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 8),

              // Test Button (for development)
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/test-qr');
                },
                icon: const Icon(Icons.bug_report, size: 16),
                label: const Text('Test Mode (Simulate QR Scan)'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
