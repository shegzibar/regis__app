import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AddRoomDialog extends StatefulWidget {
  const AddRoomDialog({super.key});

  @override
  State<AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<AddRoomDialog> {
  final _nameController = TextEditingController();
  String _type = 'ps5';
  int _stations = 2;
  final _priceController = TextEditingController(text: '60');
  final _bookingFeeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('owner_cyber_profile.add_room'.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'owner_profile.room_name'.tr(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: InputDecoration(
                labelText: 'owner_profile.room_type'.tr(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'ps5',
                  child: Text('owner_onboarding.room_ps5'.tr()),
                ),
                DropdownMenuItem(
                  value: 'ps4',
                  child: Text('owner_onboarding.room_ps4'.tr()),
                ),
                DropdownMenuItem(
                  value: 'pc',
                  child: Text('owner_onboarding.room_pc'.tr()),
                ),
                DropdownMenuItem(
                  value: 'vip',
                  child: Text('owner_onboarding.room_vip'.tr()),
                ),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'ps5'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'owner_cyber_profile.price_hour'.tr(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bookingFeeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Booking / Registration Fee (EGP)',
                hintText: 'Leave empty for default (5 for PS5, 8 for VIP)',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('owner_onboarding.station_count'.tr()),
                const Spacer(),
                IconButton(
                  onPressed:
                      _stations > 1 ? () => setState(() => _stations--) : null,
                  icon: const Icon(Icons.remove),
                ),
                Text('$_stations'),
                IconButton(
                  onPressed: () => setState(() => _stations++),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('common.cancel'.tr()),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) return;
            final dbType = _type == 'ps4' ? 'ps5' : _type;
            
            final parsedFee = double.tryParse(_bookingFeeController.text);
            
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'type': dbType,
              'price': double.tryParse(_priceController.text) ?? 50,
              'bookingFee': parsedFee,
              'stations': _stations,
            });
          },
          child: Text('common.confirm'.tr()),
        ),
      ],
    );
  }
}
