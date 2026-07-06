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
import '../../cyber_dashboard/providers/cd_providers.dart';
import 'owner_rooms_quick_add.dart';
import 'package:geolocator/geolocator.dart';
import 'profile_section_card.dart';
import 'profile_labeled_field.dart';
import 'room_profile_tile.dart';
import 'add_room_dialog.dart';

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
      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      if (position == null) return;
      final pos = position; // non-nullable local for safe closure access
      setState(() {
        _latController.text = pos.latitude.toString();
        _lngController.text = pos.longitude.toString();
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
