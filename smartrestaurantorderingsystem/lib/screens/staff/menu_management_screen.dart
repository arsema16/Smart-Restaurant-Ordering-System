import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/menu_item_model.dart';
import '../../providers/staff_menu_provider.dart';

/// Staff menu management UI with CRUD operations
/// Validates: Requirements 9.1, 9.2, 9.3, 9.4
class MenuManagementScreen extends ConsumerWidget {
  const MenuManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(staffMenuProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(staffMenuProvider.notifier).loadMenuItems();
            },
          ),
        ],
      ),
      body: menuAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No menu items',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Group items by category
          final itemsByCategory = <String, List<MenuItemResponse>>{};
          for (final item in items) {
            itemsByCategory.putIfAbsent(item.category, () => []).add(item);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: itemsByCategory.length,
            itemBuilder: (context, index) {
              final category = itemsByCategory.keys.elementAt(index);
              final categoryItems = itemsByCategory[category]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      category.toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...categoryItems.map((item) => _MenuItemCard(item: item)),
                  const SizedBox(height: 16),
                ],
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
                  ref.read(staffMenuProvider.notifier).loadMenuItems();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showMenuItemDialog(context, ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  void _showMenuItemDialog(BuildContext context, WidgetRef ref, [MenuItemResponse? item]) {
    showDialog(
      context: context,
      builder: (context) => _MenuItemDialog(item: item),
    );
  }
}

class _MenuItemCard extends ConsumerWidget {
  final MenuItemResponse item;

  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.name),
        subtitle: Text(
          '\$${item.price.toStringAsFixed(2)} • ${item.prepTimeMinutes} min',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Availability toggle
            Switch(
              value: item.isAvailable,
              onChanged: (value) async {
                try {
                  await ref.read(staffMenuProvider.notifier).toggleAvailability(item.id, value);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value ? 'Item marked as available' : 'Item marked as unavailable',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update availability: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            // Edit button
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => _MenuItemDialog(item: item),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemDialog extends ConsumerStatefulWidget {
  final MenuItemResponse? item;

  const _MenuItemDialog({this.item});

  @override
  ConsumerState<_MenuItemDialog> createState() => _MenuItemDialogState();
}

class _MenuItemDialogState extends ConsumerState<_MenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _prepTimeController;
  late bool _isAvailable;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _categoryController = TextEditingController(text: widget.item?.category ?? '');
    _priceController = TextEditingController(
      text: widget.item?.price.toStringAsFixed(2) ?? '',
    );
    _prepTimeController = TextEditingController(
      text: widget.item?.prepTimeMinutes.toString() ?? '',
    );
    _isAvailable = widget.item?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final price = double.parse(_priceController.text);
      final prepTime = int.parse(_prepTimeController.text);

      if (widget.item == null) {
        // Create new item
        await ref.read(staffMenuProvider.notifier).createMenuItem(
              MenuItemCreate(
                name: _nameController.text.trim(),
                category: _categoryController.text.trim(),
                price: price,
                prepTimeMinutes: prepTime,
                isAvailable: _isAvailable,
              ),
            );
      } else {
        // Update existing item
        await ref.read(staffMenuProvider.notifier).updateMenuItem(
              widget.item!.id,
              MenuItemUpdate(
                name: _nameController.text.trim(),
                category: _categoryController.text.trim(),
                price: price,
                prepTimeMinutes: prepTime,
                isAvailable: _isAvailable,
              ),
            );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.item == null ? 'Item created successfully' : 'Item updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add Menu Item' : 'Edit Menu Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter price';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Price must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prepTimeController,
                decoration: const InputDecoration(
                  labelText: 'Prep Time (minutes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter prep time';
                  }
                  final prepTime = int.tryParse(value);
                  if (prepTime == null || prepTime <= 0) {
                    return 'Prep time must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Available'),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() => _isAvailable = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.item == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}
