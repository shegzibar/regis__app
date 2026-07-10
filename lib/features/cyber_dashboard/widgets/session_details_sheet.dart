import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking.dart';
import '../../../core/providers/owner_dashboard_provider.dart';
import '../../owner/screens/owner_inventory_screen.dart';
import '../constants/cd_colors.dart';
import '../providers/cd_providers.dart';

class SessionDetailsSheet extends ConsumerStatefulWidget {
  final Booking booking;
  final bool isAr;
  final VoidCallback onAdded;

  const SessionDetailsSheet({
    super.key,
    required this.booking,
    required this.isAr,
    required this.onAdded,
  });

  @override
  ConsumerState<SessionDetailsSheet> createState() => _SessionDetailsSheetState();
}

class _SessionDetailsSheetState extends ConsumerState<SessionDetailsSheet> {
  bool _isAddingItem = false;
  
  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final isAr = widget.isAr;
    
    return Container(
      decoration: const BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'cyber.session_details'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const Divider(),
          Text('User: ${b.userName ?? (b.source == 'manual' ? ('cyber.walkin'.tr()) : ('cyber.app_user'.tr()))}'),
          Text('Station: ${b.stationName} (${b.roomName})'),
          Text('Start: ${DateFormat('HH:mm').format(b.startTime)}'),
          Text('End: ${DateFormat('HH:mm').format(b.endTime)}'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: ${b.totalAmount} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal)),
              if (!b.isCancelled && !b.isCompleted)
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          await ref.read(ownerRepositoryProvider).completeBooking(b.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('cyber.session_completed'.tr())),
                            );
                            widget.onAdded();
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check_circle, color: kGreen, size: 18),
                      label: Text(
                        'cyber.complete'.tr(),
                        style: const TextStyle(color: kGreen),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          await ref.read(ownerRepositoryProvider).cancelBooking(b.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('cyber.booking_cancelled'.tr())),
                            );
                            widget.onAdded();
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.cancel, color: kRed, size: 18),
                      label: Text(
                        'cyber.cancel'.tr(),
                        style: const TextStyle(color: kRed),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'cyber.additional_items'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: Text('cyber.add_item'.tr()),
                onPressed: () => setState(() => _isAddingItem = !_isAddingItem),
              )
            ],
          ),
          if (_isAddingItem) AddItemForm(bookingId: b.id, isAr: isAr, onAdded: () {
            setState(() => _isAddingItem = false);
            widget.onAdded();
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }
}

class AddItemForm extends ConsumerStatefulWidget {
  final String bookingId;
  final bool isAr;
  final VoidCallback onAdded;

  const AddItemForm({super.key, required this.bookingId, required this.isAr, required this.onAdded});

  @override
  ConsumerState<AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends ConsumerState<AddItemForm> {
  String? _selectedItemId;
  int _quantity = 1;
  bool _saving = false;

  Future<void> _add() async {
    if (_selectedItemId == null) return;
    setState(() => _saving = true);
    try {
      final items = await ref.read(ownerInventoryProvider.future);
      final item = items.firstWhere((i) => i.id == _selectedItemId);
      await ref.read(ownerRepositoryProvider).addBookingItem(
        bookingId: widget.bookingId,
        item: item,
        quantity: _quantity,
      );
      widget.onAdded();
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(ownerInventoryProvider);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Text('Error loading inventory'),
        data: (items) {
          final activeItems = items.where((i) => i.isActive).toList();
          if (activeItems.isEmpty) return const Text('No active inventory items available.');
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedItemId,
                decoration: const InputDecoration(labelText: 'Select Item', border: OutlineInputBorder()),
                items: activeItems.map((item) => DropdownMenuItem(
                  value: item.id,
                  child: Text('${item.name} - ${item.price} EGP'),
                )).toList(),
                onChanged: (val) => setState(() => _selectedItemId = val),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Quantity:'),
                  IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() { if (_quantity > 1) _quantity--; })),
                  Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _quantity++)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _saving || _selectedItemId == null ? null : _add,
                    style: ElevatedButton.styleFrom(backgroundColor: kTeal, foregroundColor: Colors.white),
                    child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Add'),
                  )
                ],
              )
            ],
          );
        }
      ),
    );
  }
}
