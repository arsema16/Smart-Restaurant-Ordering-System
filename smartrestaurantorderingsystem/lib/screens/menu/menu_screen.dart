import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/menu_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/websocket_provider.dart';
import '../../models/menu_item_model.dart';
import '../../repositories/menu_repository.dart';
import '../../utils/food_icons.dart';
import '../cart/cart_screen.dart';
import '../../widgets/recommendation_widget.dart';
import '../../providers/api_provider.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String? selectedCategory;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<MenuItemResponse> _searchResults = [];
  bool _isLoadingSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(websocketProvider.notifier).connectGuest();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() { _searchResults = []; _isLoadingSearch = false; });
      return;
    }
    setState(() => _isLoadingSearch = true);
    try {
      final repo = ref.read(menuRepositoryProvider);
      final results = await repo.searchMenu(query);
      setState(() { _searchResults = results; _isLoadingSearch = false; });
    } catch (_) {
      setState(() => _isLoadingSearch = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuProvider);
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search food...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: _performSearch,
              )
            : const Text("Menu", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          // Search toggle
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchResults = [];
                }
              });
            },
          ),
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
      body: _isSearching && _searchController.text.isNotEmpty
          ? _buildSearchResults()
          : menuAsync.when(
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
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category == selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ChoiceChip(
                          label: Text(
                            category,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.green,
                          backgroundColor: Colors.white,
                          elevation: isSelected ? 4 : 2,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    final foodIcon = getFoodIcon(item.name);
    final categoryColor = getCategoryColor(item.category);
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: item.isAvailable 
                ? [Colors.white, categoryColor.withOpacity(0.1)]
                : [Colors.grey.shade200, Colors.grey.shade300],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Item icon with colored background
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: item.isAvailable ? categoryColor.withOpacity(0.2) : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.isAvailable ? categoryColor : Colors.grey.shade500,
                    width: 2,
                  ),
                ),
                child: Icon(
                  foodIcon,
                  size: 40,
                  color: item.isAvailable ? categoryColor : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16),
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: item.isAvailable ? Colors.black87 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: categoryColor, width: 1),
                      ),
                      child: Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: categoryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${item.price.toStringAsFixed(2)} Birr',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${item.prepTimeMinutes} min',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (!item.isAvailable)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Currently unavailable',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Add button
              ElevatedButton(
                onPressed: item.isAvailable ? () => _addToCart(item) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: item.isAvailable ? categoryColor : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: item.isAvailable ? 4 : 0,
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_shopping_cart, size: 24),
                    SizedBox(height: 4),
                    Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
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
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoadingSearch) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No results for "${_searchController.text}"',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) => _buildMenuItem(_searchResults[index]),
    );
  }
}