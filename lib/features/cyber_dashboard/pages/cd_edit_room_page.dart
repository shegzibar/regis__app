import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/room.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../data/services/cloudinary_service.dart';
import '../constants/cd_colors.dart';
import '../providers/cd_providers.dart';

class CdEditRoomPage extends ConsumerStatefulWidget {
  final String roomId;

  const CdEditRoomPage({super.key, required this.roomId});

  @override
  ConsumerState<CdEditRoomPage> createState() => _CdEditRoomPageState();
}

class _CdEditRoomPageState extends ConsumerState<CdEditRoomPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _descCtrl;
  String? _selectedType;
  
  bool _isSaving = false;
  bool _isUploadingPhotos = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _priceCtrl = TextEditingController();
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _initControllers(Room room) {
    if (_isInitialized) return;
    _nameCtrl.text = room.name;
    _priceCtrl.text = room.pricePerHour.toString();
    _descCtrl.text = room.description ?? '';
    _selectedType = room.type;
    _isInitialized = true;
  }

  Future<void> _addPhotos(Room room) async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    setState(() => _isUploadingPhotos = true);
    try {
      final service = CloudinaryService();
      final newUrls = await service.uploadRoomPhotos(room.id, picked);
      if (newUrls.isEmpty) throw Exception('Upload failed');
      
      final updatedImages = [...room.images, ...newUrls];
      await RoomRepository().updateRoom(
        roomId: room.id,
        images: updatedImages,
        imageUrl: room.imageUrl ?? newUrls.first,
      );
      
      ref.invalidate(cyberRoomsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('cyber.image_uploaded'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhotos = false);
    }
  }

  Future<void> _deletePhoto(Room room, String url) async {
    final updatedImages = room.images.where((u) => u != url).toList();
    await RoomRepository().updateRoom(
      roomId: room.id,
      images: updatedImages,
      imageUrl: (room.imageUrl == url)
          ? (updatedImages.isNotEmpty ? updatedImages.first : null)
          : room.imageUrl,
    );
    ref.invalidate(cyberRoomsProvider);
  }

  Future<void> _saveChanges(Room room) async {
    final price = double.tryParse(_priceCtrl.text.trim());
    final name = _nameCtrl.text.trim();
    if (price == null || name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await RoomRepository().updateRoom(
        roomId: room.id,
        name: name,
        type: _selectedType,
        pricePerHour: price,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      ref.invalidate(cyberRoomsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('cyber.save'.tr())),
        );
        ref.read(cdSelectedPageProvider.notifier).state = 'profile';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(cyberRoomsProvider);

    return Scaffold(
      backgroundColor: kBg,
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rooms) {
          final roomIdx = rooms.indexWhere((r) => r.id == widget.roomId);
          if (roomIdx == -1) {
            return Center(child: Text('cyber.no_rooms'.tr()));
          }
          final room = rooms[roomIdx];
          
          // Only initialize controllers once
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _initControllers(room));
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header area
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        ref.read(cdSelectedPageProvider.notifier).state = 'profile';
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'cyber.edit_room'.tr(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kSidebarText),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : () => _saveChanges(room),
                      icon: _isSaving 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save, size: 20),
                      label: Text('cyber.save'.tr()),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Basic Info
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'cyber.basic_info'.tr(),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 24),
                              TextField(
                                controller: _nameCtrl,
                                decoration: InputDecoration(
                                  labelText: 'cyber.room_name'.tr(),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedType,
                                decoration: InputDecoration(
                                  labelText: 'cyber.type'.tr(),
                                  border: const OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'ps5', child: Text('PS5')),
                                  DropdownMenuItem(value: 'pc', child: Text('PC Gaming')),
                                  DropdownMenuItem(value: 'vip', child: Text('VIP')),
                                ],
                                onChanged: (v) => setState(() => _selectedType = v!),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _priceCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'cyber.price_per_hr'.tr(),
                                  suffixText: 'EGP',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _descCtrl,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: 'cyber.amenities_eg_netflix'.tr(),
                                  alignLabelWithHint: true,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      
                      // Right Column: Photos
                      Expanded(
                        flex: 4,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'owner_profile.room_photos'.tr(),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  _isUploadingPhotos
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : ElevatedButton.icon(
                                          onPressed: () => _addPhotos(room),
                                          icon: const Icon(Icons.add_photo_alternate, size: 18),
                                          label: Text('cyber.add_photos'.tr()),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kPurple.withValues(alpha: 0.1),
                                            foregroundColor: kPurple,
                                            elevation: 0,
                                          ),
                                        ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              if (room.images.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(40),
                                  decoration: BoxDecoration(
                                    color: kBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: kBorder, style: BorderStyle.solid),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.image_not_supported, size: 48, color: kGray),
                                      const SizedBox(height: 16),
                                      Text(
                                        'cyber.no_photos_in_gallery'.tr(),
                                        style: const TextStyle(color: kGray, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: room.images.length,
                                  itemBuilder: (context, index) {
                                    final url = room.images[index];
                                    return Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(url, fit: BoxFit.cover),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () async {
                                              final ok = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: Text('cyber.delete_photo'.tr()),
                                                  content: Text('cyber.are_you_sure_you'.tr()),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(ctx, false),
                                                      child: Text('cyber.cancel'.tr()),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white),
                                                      onPressed: () => Navigator.pop(ctx, true),
                                                      child: Text('cyber.delete'.tr()),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (ok == true) await _deletePhoto(room, url);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: Colors.black87,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.delete, color: Colors.white, size: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
