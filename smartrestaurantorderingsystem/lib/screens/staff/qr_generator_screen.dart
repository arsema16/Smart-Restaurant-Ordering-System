import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _tableController = TextEditingController();
  String? _generatedUrl;
  late TabController _tabController;

  static const String baseUrl = 'https://smart-restaurant-app-2024.web.app';
  static const String staffLoginUrl =
      'https://smart-restaurant-app-2024.web.app/staff-login';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tableController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _generateQRCode() {
    final tableId = _tableController.text.trim();
    if (tableId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a table identifier'),
          backgroundColor: Colors.red,
        ),
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
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        title: const Text(
          'QR Code Manager',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.table_restaurant), text: 'Table QR'),
            Tab(icon: Icon(Icons.admin_panel_settings), text: 'Staff QR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTableQRTab(),
          _buildStaffQRTab(),
        ],
      ),
    );
  }

  Widget _buildTableQRTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Generate a QR code for each table. Print and place it on the table. Customers scan it to see the menu.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Input
          TextField(
            controller: _tableController,
            decoration: InputDecoration(
              labelText: 'Table Identifier',
              hintText: 'e.g., table-1, table-2',
              prefixIcon: const Icon(Icons.table_restaurant,
                  color: Color(0xFFE65100)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFE65100), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _generateQRCode,
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Generate QR Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          if (_generatedUrl != null) ...[
            const SizedBox(height: 32),
            _buildQRCard(
              title: _tableController.text,
              subtitle: 'Customer Table QR Code',
              url: _generatedUrl!,
              color: const Color(0xFFE65100),
              icon: Icons.table_restaurant,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStaffQRTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Staff scan this QR code to open the staff login page directly on their phone.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildQRCard(
            title: 'Staff Login',
            subtitle: 'Scan to access staff dashboard',
            url: staffLoginUrl,
            color: const Color(0xFF1565C0),
            icon: Icons.admin_panel_settings,
          ),

          const SizedBox(height: 24),

          // Credentials reminder
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Staff Credentials',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _credentialRow('Admin', 'admin', 'admin123'),
                const SizedBox(height: 8),
                _credentialRow('Staff', 'staff', 'staff123'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _credentialRow(String role, String username, String password) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE65100).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            role,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFE65100),
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('$username / $password',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
      ],
    );
  }

  Widget _buildQRCard({
    required String title,
    required String subtitle,
    required String url,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: QrImageView(
              data: url,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: color,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // URL display
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              url,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
