import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/owner_dashboard_provider.dart';
import '../../../data/models/inventory_item.dart';

final ownerInventoryProvider = FutureProvider.autoDispose<List<CyberInventoryItem>>((ref) async {
  final cyber = ref.watch(ownerPrimaryCyberProvider);
  if (cyber == null) return [];
  return ref.read(ownerRepositoryProvider).getInventoryItems(cyber.id);
});

class OwnerInventoryScreen extends ConsumerWidget {
  const OwnerInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(ownerInventoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Inventory & Snacks', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Item', style: TextStyle(color: Colors.white)),
      ),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fastfood_outlined, size: 64, color: AppColors.gray),
                  SizedBox(height: 16),
                  Text('No items found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  SizedBox(height: 8),
                  Text('Add snacks, drinks, or extra services\nto offer them during active sessions.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _InventoryItemCard(item: item);
            },
          );
        },
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final costController = TextEditingController();
    final stockController = TextEditingController(text: '0');
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Item'),
              backgroundColor: Colors.white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Item Name (e.g., Pepsi Can)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Selling Price (${'common.egp'.tr()})'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: costController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Cost Price / Buy Price (${'common.egp'.tr()})'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Initial Stock (Quantity)'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final price = double.tryParse(priceController.text) ?? 0;
                          final cost = double.tryParse(costController.text) ?? 0;
                          final stock = int.tryParse(stockController.text) ?? 0;
                          if (name.isEmpty || price <= 0) return;

                          setState(() => isSaving = true);
                          try {
                            final cyber = ref.read(ownerPrimaryCyberProvider);
                            if (cyber != null) {
                              await ref.read(ownerRepositoryProvider).addInventoryItem(
                                    CyberInventoryItem(
                                      id: '',
                                      cyberId: cyber.id,
                                      name: name,
                                      price: price,
                                      costPrice: cost,
                                      stock: stock,
                                      used: 0,
                                    ),
                                  );
                              ref.invalidate(ownerInventoryProvider);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => isSaving = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Item'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _InventoryItemCard extends ConsumerStatefulWidget {
  final CyberInventoryItem item;
  const _InventoryItemCard({required this.item});

  @override
  ConsumerState<_InventoryItemCard> createState() => _InventoryItemCardState();
}

class _InventoryItemCardState extends ConsumerState<_InventoryItemCard> {
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isActive = widget.item.isActive;
  }

  Future<void> _toggleStatus(bool value) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(ownerRepositoryProvider).toggleInventoryItemStatus(widget.item.id, value);
      setState(() => _isActive = value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
      setState(() => _isActive = !_isActive); // revert
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showUpdateDialog(String title, String label, String actionText, Future<void> Function(int value) onSave) async {
    final controller = TextEditingController(text: '1');
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              backgroundColor: Colors.white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Current Stock: ${widget.item.stock}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: label),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final value = int.tryParse(controller.text) ?? 0;
                          if (value <= 0) return;

                          setState(() => isSaving = true);
                          try {
                            await onSave(value);
                            ref.invalidate(ownerInventoryProvider);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => isSaving = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(actionText),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Sell: ${widget.item.price.toStringAsFixed(2)} ${'common.egp'.tr()}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(width: 12),
                        Text('Cost: ${widget.item.costPrice.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(width: 12),
                        Text('Profit: ${(widget.item.price - widget.item.costPrice).toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                )
              else
                Switch(
                  value: _isActive,
                  onChanged: _toggleStatus,
                  activeThumbColor: AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.inventory, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('Stock: ', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  Text('${widget.item.stock}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: widget.item.stock <= 5 ? Colors.red : AppColors.textPrimary)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.shopping_cart, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('Used/Sold: ', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  Text('${widget.item.used}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showUpdateDialog(
                  'Restock ${widget.item.name}', 
                  'Amount to Add', 
                  'Restock', 
                  (value) => ref.read(ownerRepositoryProvider).updateInventoryItemStock(widget.item.id, value)
                );
              },
              icon: const Icon(Icons.add_box_outlined, size: 18),
              label: const Text('Restock'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
