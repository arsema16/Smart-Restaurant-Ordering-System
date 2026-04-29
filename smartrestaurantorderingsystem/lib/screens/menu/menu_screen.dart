import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/menu_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/recommendation_provider.dart';
import '../../providers/websocket_provider.dart';
import '../../models/menu_item_model.dart';
import '../cart/cart_screen.dart';
import '../../widgets/recommendation_widget.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String? selectedCategory;

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
    final menuAsync = ref.watch(menuProvider);
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu"),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CartScreen(),
                    ),
                  );
                },
              ),
              // Cart badge
              cartAsync.when(
                data: (cart) {
                  if (cart.items.isEmpty) return const SizedBox();
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        cart.items.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ],
          )
        ],
      ),
      body: menuAsync.when(
        data: (menu) {
          final categories = menu.categories.keys.toList();
          
          // Set initial category if not set
          if (selectedCategory == null && categories.isNotEmpty) {
            selectedCategory = categories.first;
          }

          return Column(
            children: [
              // Recommendations section
              const RecommendationWidget(),
              
              const Divider(),

              // Category tabs
              if (categories.isNotEmpty)
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category == selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

              // Menu items for selected category
              Expanded(
                child: selectedCategory == null
                    ? const Center(child: Text('No categories available'))
                    : _buildMenuItems(menu.categories[selectedCategory] ?? []),
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
              Text('Error loading menu: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(menuProvider.notifier).loadMenu(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItems(List<MenuItemResponse> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No items in this category'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildMenuItem(item);
      },
    );
  }

  Widget _buildMenuItem(MenuItemResponse item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: item.isAvailable ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.price.toStringAsFixed(2)} Birr'),
            Text('Prep time: ${item.prepTimeMinutes} min'),
            if (!item.isAvailable)
              const Text(
                'Currently unavailable',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: ElevatedButton.icon(
          onPressed: item.isAvailable
              ? () => _addToCart(item)
              : null,
          icon: const Icon(Icons.add_shopping_cart, size: 18),
          label: const Text('Add'),
          style: ElevatedButton.styleFrom(
            backgroundColor: item.isAvailable ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  void _addToCart(MenuItemResponse item) {
    ref.read(cartProvider.notifier).addItem(item.id, 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}