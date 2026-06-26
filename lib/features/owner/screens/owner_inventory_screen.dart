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
        backgroundColor: AppColors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Item', style: TextStyle(color: Colors.white)),
      ),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal)),
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
                    decoration: InputDecoration(labelText: 'Price (${'common.egp'.tr()})'),
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
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: AppColors.teal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('${widget.item.price.toStringAsFixed(2)} ${'common.egp'.tr()}', style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)),
            )
          else
            Switch(
              value: _isActive,
              onChanged: _toggleStatus,
              activeThumbColor: AppColors.teal,
            ),
        ],
      ),
    );
  }
}
