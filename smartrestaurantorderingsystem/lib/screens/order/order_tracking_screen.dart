import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartrestaurantorderingsystem/providers/menu_provider.dart';
import '../../core/services/api_service.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState
    extends ConsumerState<OrderTrackingScreen> {

  String status = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchStatus();

    // polling every 3 seconds
    Timer.periodic(const Duration(seconds: 3), (_) {
      fetchStatus();
    });
  }

  Future<void> fetchStatus() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getOrder(widget.orderId);

      setState(() {
        status = data["status"];
      });
    } catch (e) {
      setState(() {
        status = "Error";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Tracking")),
      body: Center(
        child: Text(
          "Status: $status",
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}