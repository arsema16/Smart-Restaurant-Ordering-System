import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/order_provider.dart';
import '../../providers/websocket_provider.dart';
import '../../models/order_model.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  @override
  void initState() {
    super.initState();
    // Connect to WebSocket for real-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(websocketProvider.notifier).connectGuest();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
      ),
      body: ordersAsync.when(
        data: (orders) {
          final order = orders.where((o) => o.id == widget.orderId).firstOrNull;

          if (order == null) {
            return const Center(
              child: Text('Order not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order number
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Order Number',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Status timeline
                _buildStatusTimeline(order.status),
                const SizedBox(height: 32),

                // Estimated wait time
                if (order.status != OrderStatus.delivered)
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.blue),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estimated Wait Time',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${order.estimatedWaitMinutes} minutes',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Order items
                const Text(
                  'Order Items',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...order.items.map((item) => Card(
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text('Quantity: ${item.quantity}'),
                    trailing: Text(
                      '${(item.unitPrice * item.quantity).toStringAsFixed(2)} Birr',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )),
                const SizedBox(height: 16),

                // Total
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${order.items.fold<double>(0, (sum, item) => sum + (item.unitPrice * item.quantity)).toStringAsFixed(2)} Birr',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(OrderStatus currentStatus) {
    final statuses = [
      OrderStatus.received,
      OrderStatus.cooking,
      OrderStatus.ready,
      OrderStatus.delivered,
    ];

    final currentIndex = statuses.indexOf(currentStatus);

    return Column(
      children: List.generate(statuses.length, (index) {
        final status = statuses[index];
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                    border: Border.all(
                      color: isCurrent ? Colors.green : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: isCompleted ? Colors.white : Colors.grey,
                  ),
                ),
                if (index < statuses.length - 1)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? Colors.black : Colors.grey,
                    ),
                  ),
                  if (isCurrent)
                    const Text(
                      'Current Status',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.received:
        return Icons.receipt;
      case OrderStatus.cooking:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.check_circle;
      case OrderStatus.delivered:
        return Icons.done_all;
    }
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
}