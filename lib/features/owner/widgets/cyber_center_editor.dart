import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/cyber_profile_provider.dart';
import '../../../core/providers/owner_dashboard_provider.dart';
import '../../../core/utils/supabase_error_message.dart';
import '../../../data/models/cyber.dart';
import '../../../data/models/cyber_profile_input.dart';
import '../../../data/models/cyber_room_profile.dart';
import '../../cyber_dashboard/providers/cd_providers.dart';
import 'owner_rooms_quick_add.dart';
import 'package:geolocator/geolocator.dart';

/// Editable cyber center block: info + rooms/stations (used on profile page).
class CyberCenterEditorSection extends ConsumerStatefulWidget {
  final Cyber cyber;

  const CyberCenterEditorSection({super.key, required this.cyber});

  @override
  ConsumerState<CyberCenterEditorSection> createState() =>
      _CyberCenterEditorSectionState();
}

class _CyberCenterEditorSectionState
    extends ConsumerState<CyberCenterEditorSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _coverImageController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _openController;
  late final TextEditingController _closeController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _bindCyber(widget.cyber);
  }

  void _bindCyber(Cyber cyber) {
    _nameController = TextEditingController(text: cyber.name);
    _descriptionController =
        TextEditingController(text: cyber.description ?? '');
    _addressController = TextEditingController(text: cyber.address ?? '');
    _cityController = TextEditingController(text: cyber.city ?? '');
    _coverImageController = TextEditingController(text: cyber.coverImage ?? '');
    _latController = TextEditingController(
      text: cyber.lat?.toString() ?? '',
    );
    _lngController = TextEditingController(
      text: cyber.lng?.toString() ?? '',
    );
    _openController = TextEditingController(text: cyber.workingHoursFrom);
    _closeController = TextEditingController(text: cyber.workingHoursTo);
    _isActive = cyber.isActive;
  }

  void _syncControllersFromCyber(Cyber cyber) {
    _nameController.text = cyber.name;
    _descriptionController.text = cyber.description ?? '';
    _addressController.text = cyber.address ?? '';
    _cityController.text = cyber.city ?? '';
    _coverImageController.text = cyber.coverImage ?? '';
    _latController.text = cyber.lat?.toString() ?? '';
    _lngController.text = cyber.lng?.toString() ?? '';
    _openController.text = cyber.workingHoursFrom;
    _closeController.text = cyber.workingHoursTo;
    _isActive = cyber.isActive;
  }

  double? _parseCoord(TextEditingController c) {
    final v = c.text.trim();
    if (v.isEmpty) return null;
    return double.tryParse(v);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _coverImageController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _openController.dispose();
    _closeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CyberCenterEditorSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cyber.id != widget.cyber.id) {
      _syncControllersFromCyber(widget.cyber);
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return;
    } 

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Getting location...')));
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location updated! Don't forget to save.")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    }
  }

  Future<void> _saveCyber() async {
    if (!_formKey.currentState!.validate()) return;

    final ownerId = ref.read(authStateProvider)?.id;
    if (ownerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('owner_profile.not_signed_in'.tr())),
        );
      }
      return;
    }

    setState(() => _saving = true);
    try {
      final input = CyberProfileInput(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        lat: _parseCoord(_latController),
        lng: _parseCoord(_lngController),
        images: widget.cyber.images,
        coverImage: _coverImageController.text.trim().isEmpty
            ? null
            : _coverImageController.text.trim(),
        workingHoursFrom: _openController.text.trim(),
        workingHoursTo: _closeController.text.trim(),
        isActive: _isActive,
      );

      final updated =
          await ref.read(ownerRepositoryProvider).updateCyberProfile(
                cyberId: widget.cyber.id,
                ownerId: ownerId,
                input: input,
              );

      _syncControllersFromCyber(updated);

      ref.invalidate(ownerCybersProvider);
      ref.invalidate(cyberProfileCyberListProvider);
      ref.invalidate(cyberProfileRoomsProvider(widget.cyber.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('owner_profile.saved_to_supabase'.tr()),
            backgroundColor: AppColors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(supabaseErrorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addRoom() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const AddRoomDialog(),
    );
    if (result == null) return;

    try {
      await ref.read(ownerRepositoryProvider).addRoomWithStations(
            cyberId: widget.cyber.id,
            name: result['name'] as String,
            type: result['type'] as String,
            pricePerHour: result['price'] as double,
            bookingFee: result['bookingFee'] as double?,
            stationCount: result['stations'] as int,
          );
      ref.invalidate(cyberProfileRoomsProvider(widget.cyber.id));
      ref.invalidate(ownerCybersProvider);
      ref.invalidate(cyberRoomsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(cyberProfileRoomsProvider(widget.cyber.id));

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileSectionCard(
            title: 'owner_cyber_profile.general'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileLabeledField(
                  label: 'owner_onboarding.cyber_name'.tr(),
                  controller: _nameController,
                  validator: (v) => v == null || v.isEmpty
                      ? 'owner_onboarding.required'.tr()
                      : null,
                ),
                ProfileLabeledField(
                  label: 'owner_profile.description'.tr(),
                  controller: _descriptionController,
                  maxLines: 3,
                ),
                ProfileLabeledField(
                  label: 'owner_profile.cover_image'.tr(),
                  controller: _coverImageController,
                  keyboardType: TextInputType.url,
                ),
                Row(
                  children: [
                    Expanded(
                      child: ProfileLabeledField(
                        label: 'owner_profile.open_time'.tr(),
                        controller: _openController,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ProfileLabeledField(
                        label: 'owner_profile.close_time'.tr(),
                        controller: _closeController,
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('owner_profile.center_active'.tr()),
                  value: _isActive,
                  activeThumbColor: AppColors.teal,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _saveCyber,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: Text('owner_profile.save_center'.tr()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ProfileSectionCard(
            title: 'owner_profile.location_section'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'owner_profile.location_hint'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                ProfileLabeledField(
                  label: 'owner_profile.address'.tr(),
                  controller: _addressController,
                  validator: (v) => v == null || v.isEmpty
                      ? 'owner_onboarding.required'.tr()
                      : null,
                ),
                ProfileLabeledField(
                  label: 'owner_profile.city'.tr(),
                  controller: _cityController,
                  validator: (v) => v == null || v.isEmpty
                      ? 'owner_onboarding.required'.tr()
                      : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: ProfileLabeledField(
                        label: 'owner_profile.latitude'.tr(),
                        controller: _latController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ProfileLabeledField(
                        label: 'owner_profile.longitude'.tr(),
                        controller: _lngController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location, size: 18),
                    label: const Text('Get Current Location'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.purple,
                      side: const BorderSide(color: AppColors.purple),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveCyber,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text('owner_profile.save_to_supabase'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ProfileSectionCard(
            title: 'owner_profile.add_rooms'.tr(),
            child: OwnerRoomsQuickAddPanel(
              cyberId: widget.cyber.id,
              onAdded: () =>
                  ref.invalidate(cyberProfileRoomsProvider(widget.cyber.id)),
            ),
          ),
          const SizedBox(height: 12),
          ProfileSectionCard(
            title: 'owner_profile.rooms_stations_section'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'owner_profile.stations_hint'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: _addRoom,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('owner_cyber_profile.add_room'.tr()),
                    ),
                  ],
                ),
                roomsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                        child:
                            CircularProgressIndicator(color: AppColors.purple)),
                  ),
                  error: (e, _) => Text('$e'),
                  data: (rooms) {
                    if (rooms.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('owner_profile.no_rooms_yet'.tr()),
                      );
                    }
                    return Column(
                      children: rooms
                          .map(
                            (r) => RoomProfileTile(
                              profile: r,
                              onRefresh: () => ref.invalidate(
                                  cyberProfileRoomsProvider(widget.cyber.id)),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.purple,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class ProfileLabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool readOnly;
  final TextInputType? keyboardType;
  final int maxLines;

  const ProfileLabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.readOnly = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        validator: validator,
        readOnly: readOnly,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor:
              readOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class RoomProfileTile extends ConsumerWidget {
  final CyberRoomProfile profile;
  final VoidCallback onRefresh;

  const RoomProfileTile({
    super.key,
    required this.profile,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = profile.room;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${room.type.toUpperCase()} • ${room.pricePerHour.round()} ${'common.egp'.tr()}/${'common.per_hour'.tr()}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${profile.stations.length} ${'owner_cyber_profile.stations'.tr()}',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('owner_cyber_profile.delete_room'.tr()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('common.cancel'.tr()),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('common.delete'.tr()),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await ref
                        .read(ownerRepositoryProvider)
                        .deleteRoomCascade(room.id);
                    onRefresh();
                  }
                },
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...profile.stations.map(
                (s) => Chip(
                  label: Text(s.name),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () async {
                    await ref.read(ownerRepositoryProvider).deleteStation(s.id);
                    onRefresh();
                  },
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: Text('owner_cyber_profile.add_station'.tr()),
                onPressed: () async {
                  final name = await showDialog<String>(
                    context: context,
                    builder: (_) => NameDialog(
                      title: 'owner_cyber_profile.add_station'.tr(),
                    ),
                  );
                  if (name != null && name.isNotEmpty) {
                    await ref.read(ownerRepositoryProvider).addStation(
                          roomId: room.id,
                          name: name,
                        );
                    onRefresh();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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

class NameDialog extends StatefulWidget {
  final String title;
  const NameDialog({super.key, required this.title});

  @override
  State<NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<NameDialog> {
  final _c = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _c,
        decoration:
            InputDecoration(labelText: 'owner_profile.station_name'.tr()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('common.cancel'.tr()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _c.text.trim()),
          child: Text('common.confirm'.tr()),
        ),
      ],
    );
  }
}
