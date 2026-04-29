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
      setState(() {
        _searchResults = [];
        _isLoadingSearch = false;
      });
      return;
    }
    setState(() => _isLoadingSearch = true);
    try {
      final repo = ref.read(menuRepositoryProvider);
      final results = await repo.searchMenu(query);
      setState(() {
        _searchResults = results;
        _isLoadingSearch = false;
      });
    } catch (_) {
      setState(() => _isLoadingSearch = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuProvider);
    final cartAsync = ref.watch(cartProvider);

    final cartCount = cartAsync.when(
      data: (c) => c.items.fold(0, (sum, i) => sum + i.quantity),
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search dishes...',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
                onChanged: _performSearch,
              )
            : const Text(
                'Habesha Bites 🍽️',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, size: 26),
              onPressed: () => setState(() => _isSearching = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close, size: 26),
              onPressed: () => setState(() {
                _isSearching = false;
                _searchController.clear();
                _searchResults = [];
              }),
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, size: 26),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Color(0xFFE65100),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isSearching && _searchController.text.isNotEmpty
          ? _buildSearchResults()
          : menuAsync.when(
              data: (menu) {
                final categories = menu.categories.keys.toList();
                if (selectedCategory == null && categories.isNotEmpty) {
                  selectedCategory = categories.first;
                }
                return _buildMenuBody(menu, categories);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFE65100)),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Could not load menu',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(menuProvider.notifier).loadMenu(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMenuBody(MenuGroupedResponse menu, List<String> categories) {
    final items = menu.categories[selectedCategory] ?? [];
    return Column(
      children: [
        // Recommendations
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: RecommendationWidget(),
        ),

        // Category chips
        Container(
          height: 56,
          color: const Color(0xFFFFF8F5),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = cat == selectedCategory;
              final color = getCategoryColor(cat);
              return GestureDetector(
                onTap: () => setState(() => selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Menu items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildMenuCard(items[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(MenuItemResponse item) {
    final foodIcon = getFoodIcon(item.name);
    final categoryColor = getCategoryColor(item.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Left color bar
            Container(
              width: 6,
              height: 120,
              color: item.isAvailable ? categoryColor : Colors.grey.shade300,
            ),
            // Food icon area
            Container(
              width: 100,
              height: 120,
              color: item.isAvailable
                  ? categoryColor.withOpacity(0.12)
                  : Colors.grey.shade100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    foodIcon,
                    size: 48,
                    color: item.isAvailable
                        ? categoryColor
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.isAvailable
                          ? categoryColor.withOpacity(0.2)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: item.isAvailable
                            ? categoryColor
                            : Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: item.isAvailable
                            ? const Color(0xFF1A1A1A)
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(
                          '${item.prepTimeMinutes} min',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.price.toStringAsFixed(0)} Birr',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: item.isAvailable
                                ? const Color(0xFFE65100)
                                : Colors.grey,
                          ),
                        ),
                        if (!item.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: Colors.red.shade200),
                            ),
                            child: const Text(
                              'Unavailable',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () => _addToCart(item),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE65100),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE65100)
                                        .withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoadingSearch) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE65100)));
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No results for "${_searchController.text}"',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) => _buildMenuCard(_searchResults[index]),
    );
  }

  void _addToCart(MenuItemResponse item) {
    ref.read(cartProvider.notifier).addItem(item.id, 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('${item.name} added to cart'),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
