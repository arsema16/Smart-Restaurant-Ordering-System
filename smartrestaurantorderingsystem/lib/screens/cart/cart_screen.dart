import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cart_provider.dart';
import '../../providers/session_provider.dart';
import '../../core/services/api_service.dart';
import '../order/order_tracking_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = ref.read(cartProvider.notifier).totalPrice;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Cart"),
      ),
      body: Column(
        children: [
          // 🛒 Cart Items
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Text(
                      "Cart is empty",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView(
                    children: cart.map((item) {
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          "${item.price} x ${item.quantity}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            ref
                                .read(cartProvider.notifier)
                                .removeItem(item.id);
                          },
                        ),
                      );
                    }).toList(),
                  ),
          ),

          // 💰 Bottom Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "Total: ${total.toStringAsFixed(2)} ETB",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: () async {
                    final session = ref.read(sessionProvider).value;

                    if (session == null || cart.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("No session or empty cart"),
                        ),
                      );
                      return;
                    }

                    final items = cart.map((item) {
                      return {
                        "id": item.id,
                        "name": item.name,
                        "price": item.price,
                        "quantity": item.quantity,
                      };
                    }).toList();

                    try {
                      final api = ref.read(apiServiceProvider);

                      final response = await api.createOrder(
                        session.sessionId,
                        items,
                      );

                      // ✅ clear cart
                      ref.read(cartProvider.notifier).state = [];

                      // ✅ go to tracking screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTrackingScreen(
                            orderId: response['order_id'],
                          ),
                        ),
                      );

                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: $e"),
                        ),
                      );
                    }
                  },
                  child: const Text("Place Order"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}