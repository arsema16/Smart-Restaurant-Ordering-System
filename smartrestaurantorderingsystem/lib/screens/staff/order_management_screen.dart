import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order_model.dart';
import '../../providers/staff_order_provider.dart';
import '../../services/websocket_service.dart';
import '../../core/constants/api_constants.dart';

/// Staff order management dashboard with real-time updates
/// Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5
class OrderManagementScreen extends ConsumerStatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  ConsumerState<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends ConsumerState<OrderManagementScreen> {
  late WebSocketService _wsService;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initWebSocket();
  }

  Future<void> _initWebSocket() async {
    _wsService = WebSocketService(baseUrl: ApiConstants.baseUrl);
    
    try {
      await _wsService.connectStaff();
      setState(() => _isConnected = true);
      
      // Listen to WebSocket events
      _wsService.eventStream.listen((event) {
        if (event.event == WebSocketEventType.orderCreated) {
          // Add new order to list
          final order = OrderResponse.fromJson(event.payload);
          ref.read(staffOrderProvider.notifier).addOrder(order);
        } else if (event.event == WebSocketEventType.orderStatusUpdated) {
          // Update order status
          final orderId = event.payload['order_id'] as String;
          final newStatus = OrderStatus.fromJson(event.payload['new_status'] as String);
          ref.read(staffOrderProvider.notifier).updateOrderFromWebSocket(orderId, newStatus);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WebSocket connection failed: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _wsService.disconnect();
    super.dispose();
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await ref.read(staffOrderProvider.notifier).updateOrderStatus(orderId, newStatus);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  OrderStatus? _getNextStatus(OrderStatus currentStatus) {
    switch (currentStatus) {
      case OrderStatus.received:
        return OrderStatus.cooking;
      case OrderStatus.cooking:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.delivered;
      case OrderStatus.delivered:
        return null;
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.received:
        return 'Received';
      case OrderStatus.cooking:
        return 'Cooking';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.received:
        return Colors.blue;
      case OrderStatus.cooking:
        return Colors.orange;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(staffOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        actions: [
          // WebSocket connection indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(staffOrderProvider.notifier).loadOrders();
            },
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No active orders',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final nextStatus = _getNextStatus(order.status);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.orderNumber,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Chip(
                            label: Text(_getStatusLabel(order.status)),
                            backgroundColor: _getStatusColor(order.status),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Order items
                      const Text(
                        'Items:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.only(left: 16, top: 4),
                            child: Text('${item.quantity}x ${item.name}'),
                          )),
                      const SizedBox(height: 16),

                      // Status update button
                      if (nextStatus != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _updateOrderStatus(order.id, nextStatus),
                            icon: const Icon(Icons.arrow_forward),
                            label: Text('Mark as ${_getStatusLabel(nextStatus)}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getStatusColor(nextStatus),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(staffOrderProvider.notifier).loadOrders();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
