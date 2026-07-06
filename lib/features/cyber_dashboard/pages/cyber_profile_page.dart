import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/cyber.dart';
import '../../../data/models/room.dart';
import '../constants/cd_colors.dart';
import '../providers/cd_providers.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/owner_dashboard_provider.dart';
import '../providers/photo_providers.dart';

class CyberProfilePage extends ConsumerStatefulWidget {
  const CyberProfilePage({super.key});

  @override
  ConsumerState<CyberProfilePage> createState() => _CyberProfilePageState();
}

class _CyberProfilePageState extends ConsumerState<CyberProfilePage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  void _populate(Cyber c) {
    _nameCtrl.text = c.name;
    _descCtrl.text = c.description ?? '';
    _addressCtrl.text = c.address ?? '';
  }

  Future<void> _saveProfile(Cyber c) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(cdCyberRepoProvider).updateCyber(c.id, {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      });
      ref.invalidate(currentCyberProvider);
      setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(cdLangProvider);
    final isAr = lang == 'ar';
    final cyberAsync = ref.watch(currentCyberProvider);
    final roomsAsync = ref.watch(cyberRoomsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(kPadding),
      child: cyberAsync.when(
        loading: () => const Center(
            child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        )),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cyber) {
          if (cyber == null) return const Center(child: Text('No Cyber found'));
          if (!_isEditing && _nameCtrl.text.isEmpty) _populate(cyber);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title
              Text(
                isAr ? 'ملف الكافيه' : 'Cyber Profile',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kSidebarText),
              ),
              const SizedBox(height: 20),

              // Two columns
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Info Form
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(kRadius),
                        border: Border.all(color: kBorder, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isAr ? 'البيانات الأساسية' : 'Basic Info',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              if (!_isEditing)
                                TextButton.icon(
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: Text(isAr ? 'تعديل' : 'Edit'),
                                  onPressed: () =>
                                      setState(() => _isEditing = true),
                                )
                            ],
                          ),
                          const Divider(height: 24, thickness: 0.5),

                          _buildTextField(isAr ? 'اسم الكافيه' : 'Cyber Name',
                              _nameCtrl, _isEditing),
                          const SizedBox(height: 16),
                          _buildTextField(isAr ? 'الوصف' : 'Description',
                              _descCtrl, _isEditing,
                              maxLines: 3),
                          const SizedBox(height: 16),
                          _buildTextField(isAr ? 'العنوان' : 'Address',
                              _addressCtrl, _isEditing),

                          if (_isEditing) ...[
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _populate(cyber);
                                    setState(() => _isEditing = false);
                                  },
                                  child: Text(isAr ? 'إلغاء' : 'Cancel'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPurple,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _isSaving
                                      ? null
                                      : () => _saveProfile(cyber),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2))
                                      : Text(isAr ? 'حفظ' : 'Save'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: kGap),

                  // Right: Rooms & Pricing
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(kRadius),
                        border: Border.all(color: kBorder, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isAr ? 'الغرف والأسعار' : 'Rooms & Pricing',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: kPurple),
                                onPressed: () {
                                  _showAddRoomDialog(context, ref, cyber.id, isAr);
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 24, thickness: 0.5),
                          roomsAsync.when(
                            loading: () => const CircularProgressIndicator(),
                            error: (e, _) => Text('Error: $e'),
                            data: (rooms) {
                              if (rooms.isEmpty) {
                                return Text(isAr ? 'لا توجد غرف' : 'No rooms');
                              }
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: rooms.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                  final r = rooms[i];
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: kBg,
                                      borderRadius:
                                          BorderRadius.circular(kRadiusSm),
                                      border:
                                          Border.all(color: kBorder, width: 0.5),
                                    ),
                                    child: Row(
                                      children: [
                                        if (r.imageUrl != null && r.imageUrl!.isNotEmpty)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(kRadiusSm),
                                            child: Image.network(r.imageUrl!, width: 40, height: 40, fit: BoxFit.cover),
                                          )
                                        else
                                          Text(r.typeIcon,
                                              style: const TextStyle(fontSize: 20)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(r.name,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              Text(
                                                  '${r.pricePerHour.toInt()} EGP/hr',
                                                  style: const TextStyle(
                                                      color: kTeal,
                                                      fontSize: 12)),
                                              if (r.description != null && r.description!.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2),
                                                  child: Text(
                                                    r.description!,
                                                    style: const TextStyle(
                                                        color: kGray,
                                                        fontSize: 10),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                          IconButton(
                                            icon: const Icon(Icons.image, size: 16, color: kPurple),
                                            onPressed: () async {
                                              final picker = ImagePicker();
                                              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                                              if (image != null) {
                                                try {
                                                  await ref.read(uploadRoomImageProvider({'roomId': r.id, 'file': image}).future);
                                                  ref.invalidate(cyberRoomsProvider);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'تم رفع الصورة' : 'Image uploaded')));
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                                                }
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                size: 16, color: kGray),
                                            onPressed: () => _showEditPriceDialog(
                                                context, ref, r, isAr),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                size: 16, color: kRed),
                                            onPressed: () => _showDeleteRoomDialog(
                                                context, ref, r, isAr),
                                          ),
                                        ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Photos Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(color: kBorder, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'الصور' : 'Photos',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24, thickness: 0.5),
                    const SizedBox(height: 8),

                    // Cover Photo
                    Text(isAr ? 'صورة الغلاف' : 'Cover Photo', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          try {
                            await ref.read(uploadCoverImageProvider({'cyberId': cyber.id, 'file': image}).future);
                            ref.invalidate(currentCyberProvider);
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                          }
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(kRadiusSm),
                          border: Border.all(color: kBorder, width: 1, style: BorderStyle.solid),
                          image: cyber.coverImage != null
                              ? DecorationImage(image: NetworkImage(cyber.coverImage!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: cyber.coverImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo, color: kGray, size: 40),
                                  const SizedBox(height: 8),
                                  Text(isAr ? 'اضغط لإضافة صورة غلاف' : 'Tap to add cover photo', style: const TextStyle(color: kGray)),
                                ],
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Gallery
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isAr ? 'معرض الصور' : 'Gallery', style: const TextStyle(fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          icon: const Icon(Icons.add_photo_alternate, size: 16),
                          label: Text(isAr ? 'إضافة صور' : 'Add photos'),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final List<XFile> images = await picker.pickMultiImage();
                            if (images.isNotEmpty) {
                              try {
                                await ref.read(addGalleryImageProvider({'cyberId': cyber.id, 'files': images}).future);
                                ref.invalidate(currentCyberProvider);
                              } catch (e) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (cyber.images.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(kRadiusSm)),
                        child: Text(isAr ? 'لا توجد صور في المعرض' : 'No photos in gallery', textAlign: TextAlign.center, style: const TextStyle(color: kGray)),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: cyber.images.length,
                        itemBuilder: (context, index) {
                          final url = cyber.images[index];
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(kRadiusSm),
                                child: Image.network(url, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(isAr ? 'حذف الصورة' : 'Delete Photo'),
                                        content: Text(isAr ? 'هل أنت متأكد من حذف هذه الصورة؟' : 'Are you sure you want to delete this photo?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isAr ? 'إلغاء' : 'Cancel')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: Text(isAr ? 'حذف' : 'Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      try {
                                        await ref.read(removeGalleryImageProvider({'cyberId': cyber.id, 'url': url}).future);
                                        ref.invalidate(currentCyberProvider);
                                      } catch (e) {
                                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      bool enabled, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: kGray)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: !enabled,
            fillColor: enabled ? kWhite : kBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadiusSm),
              borderSide: const BorderSide(color: kBorder, width: 0.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadiusSm),
              borderSide: const BorderSide(color: kBorder, width: 0.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _showEditPriceDialog(
      BuildContext context, WidgetRef ref, Room r, bool isAr) {
    final priceCtrl = TextEditingController(text: r.pricePerHour.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'تعديل السعر' : 'Edit Price'),
        content: TextField(
          controller: priceCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: 'EGP/hr',
            border: const OutlineInputBorder(),
            labelText: isAr ? 'السعر' : 'Price',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(priceCtrl.text.trim());
              if (val != null) {
                Navigator.pop(ctx);
                await ref
                    .read(cdCyberRepoProvider)
                    .updateRoomPrice(r.id, val);
                ref.invalidate(cyberRoomsProvider);
              }
            },
            child: Text(isAr ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showAddRoomDialog(
      BuildContext context, WidgetRef ref, String cyberId, bool isAr) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedType = 'ps5';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) => AlertDialog(
          title: Text(isAr ? 'إضافة غرفة' : 'Add Room'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: isAr ? 'اسم الغرفة' : 'Room Name',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: isAr ? 'النوع' : 'Type',
                  border: const OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ps5', child: Text('PS5')),
                  DropdownMenuItem(value: 'pc', child: Text('PC Gaming')),
                  DropdownMenuItem(value: 'vip', child: Text('VIP')),
                ],
                onChanged: (v) => setStateSB(() => selectedType = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'السعر (ساعة)' : 'Price (per hr)',
                  suffixText: 'EGP',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: isAr ? 'المميزات (مثل: نتفليكس)' : 'Amenities (e.g., Netflix)',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final price = double.tryParse(priceCtrl.text.trim());
                final name = nameCtrl.text.trim();
                if (price != null && name.isNotEmpty) {
                  Navigator.pop(ctx);
                  await ref.read(cdCyberRepoProvider).addRoom(
                        cyberId: cyberId,
                        name: name,
                        type: selectedType,
                        pricePerHour: price,
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      );
                  ref.invalidate(cyberRoomsProvider);
                }
              },
              child: Text(isAr ? 'إضافة' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteRoomDialog(
      BuildContext context, WidgetRef ref, Room r, bool isAr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'حذف الغرفة' : 'Delete Room'),
        content: Text(isAr ? 'هل أنت متأكد من حذف الغرفة "${r.name}" وجميع الأجهزة التابعة لها؟' : 'Are you sure you want to delete "${r.name}" and all its stations?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(ownerRepositoryProvider).deleteRoomCascade(r.id);
                ref.invalidate(cyberRoomsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isAr ? 'تم الحذف بنجاح' : 'Deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(isAr ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
  }
}
