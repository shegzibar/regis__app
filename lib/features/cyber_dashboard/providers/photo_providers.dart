import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/cyber.dart';
import '../../../data/repositories/cyber_repository.dart';
import '../../../data/services/cloudinary_service.dart';
import '../repositories/cd_cyber_repository.dart';

enum PhotoUploadState { idle, uploading, success, error }

final cloudinaryServiceProvider = Provider((ref) => CloudinaryService());
final cyberRepositoryProvider = Provider((ref) => CyberRepository());

final photoUploadStateProvider = StateProvider<PhotoUploadState>((ref) => PhotoUploadState.idle);

final uploadCoverImageProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final cyberId = params['cyberId'] as String;
  final file = params['file'] as XFile;

  Future.microtask(() => ref.read(photoUploadStateProvider.notifier).state = PhotoUploadState.uploading);
  try {
    final cloudinaryService = ref.read(cloudinaryServiceProvider);
    final cyberRepo = ref.read(cyberRepositoryProvider);

    final url = await cloudinaryService.uploadCyberPhoto(cyberId, file);
    if (url != null) {
      await cyberRepo.updateCoverImage(cyberId, url);
      Future.microtask(() => ref.read(photoUploadStateProvider.notifier).state = PhotoUploadState.success);
    } else {
      Future.microtask(() => ref.read(photoUploadStateProvider.notifier).state = PhotoUploadState.error);
      throw Exception('Failed to upload cover image.');
    }
  } catch (e) {
    Future.microtask(() => ref.read(photoUploadStateProvider.notifier).state = PhotoUploadState.error);
    throw e;
  }
});

final addGalleryImageProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final cyberId = params['cyberId'] as String;
  final files = params['files'] as List<XFile>;

  Future.microtask(() => ref.read(photoUploadStateProvider.notifier).state = PhotoUploadState.uploading);
  try {
    final cloudinaryService = ref.read(cloudinaryServiceProvider);
    final cyberRepo = ref.read(cyberRepositoryProvider);

    final urls = await cloudinaryService.uploadGalleryPhotos(cyberId, files);
    if (urls.isNotEmpty) {
      for (final url in urls) {
         await cyberRepo.addGalleryImage(cyberId, url);
      }
      Future.microtask(() => ref.read(photoUploadStateProvider.notifier).state = PhotoUploadState.success);
    } else {
      Future.microtask(() => ref.read(photoUploadStateProvider.notifier).state = PhotoUploadState.error);
      throw Exception('Failed to upload gallery images.');
    }
  } catch (e) {
    Future.microtask(() => ref.read(photoUploadStateProvider.notifier).state = PhotoUploadState.error);
    throw e;
  }
});

final removeGalleryImageProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final cyberId = params['cyberId'] as String;
  final url = params['url'] as String;

  try {
    final cyberRepo = ref.read(cyberRepositoryProvider);
    await cyberRepo.removeGalleryImage(cyberId, url);
  } catch (e) {
    throw e;
  }
});

final cdCyberRepositoryProvider = Provider((ref) => CdCyberRepository());

final uploadRoomImageProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final roomId = params['roomId'] as String;
  final file = params['file'] as XFile;

  Future.microtask(() => ref.read(photoUploadStateProvider.notifier).state = PhotoUploadState.uploading);
  try {
    final cloudinaryService = ref.read(cloudinaryServiceProvider);
    final cyberRepo = ref.read(cdCyberRepositoryProvider);

    final url = await cloudinaryService.uploadRoomPhoto(roomId, file);
    if (url != null) {
      await cyberRepo.updateRoomImage(roomId, url);
      Future.microtask(() => ref.read(photoUploadStateProvider.notifier).state = PhotoUploadState.success);
    } else {
      Future.microtask(() => ref.read(photoUploadStateProvider.notifier).state = PhotoUploadState.error);
      throw Exception('Failed to upload room image.');
    }
  } catch (e) {
    Future.microtask(() => ref.read(photoUploadStateProvider.notifier).state = PhotoUploadState.error);
    throw e;
  }
});
