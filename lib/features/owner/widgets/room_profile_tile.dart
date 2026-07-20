import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/owner_dashboard_provider.dart';
import '../../../data/models/cyber_room_profile.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../data/services/cloudinary_service.dart';
import 'name_dialog.dart';

class RoomProfileTile extends ConsumerStatefulWidget {
  final CyberRoomProfile profile;
  final VoidCallback onRefresh;

  const RoomProfileTile({
    super.key,
    required this.profile,
    required this.onRefresh,
  });

  @override
  ConsumerState<RoomProfileTile> createState() => _RoomProfileTileState();
}

class _RoomProfileTileState extends ConsumerState<RoomProfileTile> {
  bool _uploading = false;

  Future<void> _addPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    setState(() => _uploading = true);
    try {
      final room = widget.profile.room;
      final service = CloudinaryService();
      final newUrls = await service.uploadRoomPhotos(room.id, picked);
      if (newUrls.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('owner_profile.upload_failed'.tr())),
          );
        }
        return;
      }
      final updatedImages = [...room.images, ...newUrls];
      await RoomRepository().updateRoom(
        roomId: room.id,
        images: updatedImages,
        // Also set imageUrl to the first photo if not already set
        imageUrl: room.imageUrl ?? newUrls.first,
      );
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deletePhoto(String url) async {
    final room = widget.profile.room;
    final updatedImages = room.images.where((u) => u != url).toList();
    await RoomRepository().updateRoom(
      roomId: room.id,
      images: updatedImages,
      // If deleted photo was the cover, update imageUrl
      imageUrl: (room.imageUrl == url)
          ? (updatedImages.isNotEmpty ? updatedImages.first : null)
          : room.imageUrl,
    );
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.profile.room;

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
          // ── Room header row ──────────────────────────────────────
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
                '${widget.profile.stations.length} ${'owner_cyber_profile.stations'.tr()}',
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
                    widget.onRefresh();
                  }
                },
              ),
            ],
          ),

          // ── Stations chips ────────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...widget.profile.stations.map(
                (s) => Chip(
                  label: Text(s.name),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () async {
                    await ref.read(ownerRepositoryProvider).deleteStation(s.id);
                    widget.onRefresh();
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
                    widget.onRefresh();
                  }
                },
              ),
            ],
          ),

          const Divider(height: 20),

          // ── Room Photos section ───────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'owner_profile.room_photos'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              _uploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton.icon(
                      onPressed: _addPhotos,
                      icon: const Icon(Icons.add_photo_alternate, size: 16),
                      label: Text('cyber.add_photos'.tr()),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 6),

          if (room.images.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'cyber.no_photos_in_gallery'.tr(),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: room.images.length,
              itemBuilder: (context, index) {
                final url = room.images[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('cyber.delete_photo'.tr()),
                              content: Text('cyber.are_you_sure_you'.tr()),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: Text('common.cancel'.tr()),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  child: Text('common.delete'.tr()),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) await _deletePhoto(url);
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                    // Mark first image as cover
                    if (index == 0)
                      Positioned(
                        bottom: 2,
                        left: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'Cover',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
