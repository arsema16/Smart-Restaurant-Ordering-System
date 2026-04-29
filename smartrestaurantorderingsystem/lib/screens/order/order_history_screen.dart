import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Separate active and delivered orders
          final activeOrders = orders.where((o) => o.status != OrderStatus.delivered).toList();
          final deliveredOrders = orders.where((o) => o.status == OrderStatus.delivered).toList();

          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              if (activeOrders.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Active Orders',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ...activeOrders.map((order) => _buildOrderCard(order, context)),
                const SizedBox(height: 16),
              ],
              if (deliveredOrders.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Delivered Orders',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ...deliveredOrders.map((order) => _buildOrderCard(order, context)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading orders: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(orderProvider.notifier).loadOrders(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderResponse order, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ExpansionTile(
        leading: _buildStatusIcon(order.status),
        title: Text(
          'Order ${order.orderNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getStatusText(order.status)),
            if (order.status != OrderStatus.delivered)
              Text('Est. wait: ${order.estimatedWaitMinutes} min'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('${item.quantity}x ${item.name}'),
                      ),
                      Text('${(item.unitPrice * item.quantity).toStringAsFixed(2)} Birr'),
                    ],
                  ),
                )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${order.items.fold<double>(0, (sum, item) => sum + (item.unitPrice * item.quantity)).toStringAsFixed(2)} Birr',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ordered: ${_formatDateTime(order.createdAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(OrderStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case OrderStatus.received:
        icon = Icons.receipt;
        color = Colors.blue;
        break;
      case OrderStatus.cooking:
        icon = Icons.restaurant;
        color = Colors.orange;
        break;
      case OrderStatus.ready:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case OrderStatus.delivered:
        icon = Icons.done_all;
        color = Colors.grey;
        break;
    }

    return Icon(icon, color: color, size: 32);
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.received:
        return 'Order Received';
      case OrderStatus.cooking:
        return 'Cooking';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }
}
