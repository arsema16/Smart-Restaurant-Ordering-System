import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/recommendation_widget.dart';
import '../order/order_tracking_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Reload cart when screen is displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('CartScreen: Reloading cart...');
      ref.read(cartProvider.notifier).loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Cart"),
      ),
      body: cartAsync.when(
        data: (cart) {
          if (cart.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Your cart is empty",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Recommendations section
              const RecommendationWidget(),
              const Divider(),

              // Cart Items
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${item.price.toStringAsFixed(2)} Birr each'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Decrease quantity
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                ref.read(cartProvider.notifier).updateQuantity(
                                  item.menuItemId,
                                  item.quantity - 1,
                                );
                              },
                            ),
                            // Quantity
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.quantity.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Increase quantity
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                ref.read(cartProvider.notifier).updateQuantity(
                                  item.menuItemId,
                                  item.quantity + 1,
                                );
                              },
                            ),
                            // Remove item
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                ref.read(cartProvider.notifier).removeItem(item.menuItemId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item.name} removed from cart'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Total and Place Order button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${cart.totalPrice.toStringAsFixed(2)} Birr',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: cart.items.isEmpty
                            ? null
                            : () => _placeOrder(context, ref),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: const Text(
                          'Place Order',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
              Text('Error loading cart: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(cartProvider.notifier).loadCart(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Place order
      final order = await ref.read(orderProvider.notifier).placeOrder();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to order tracking
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(orderId: order.id),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}