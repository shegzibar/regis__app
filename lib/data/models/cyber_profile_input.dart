import '../../core/utils/cyber_time_format.dart';

/// Fields owners can set on the `cybers` table (signup + profile).
class CyberProfileInput {
  final String name;
  final String? description;
  final String? address;
  final String? city;
  final double? lat;
  final double? lng;
  final List<String>? images;
  final String? coverImage;
  final String? workingHoursFrom;
  final String? workingHoursTo;
  final bool? isActive;

  const CyberProfileInput({
    required this.name,
    this.description,
    this.address,
    this.city,
    this.lat,
    this.lng,
    this.images,
    this.coverImage,
    this.workingHoursFrom,
    this.workingHoursTo,
    this.isActive,
  });

  Map<String, dynamic> toInsertMap({required String ownerId}) {
    return {
      'owner_id': ownerId,
      'name': name,
      if (description != null) 'description': description,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      'images': images ?? [],
      if (coverImage != null && coverImage!.isNotEmpty) 'cover_image': coverImage,
      if (workingHoursFrom != null)
        'working_hours_from': CyberTimeFormat.toDb(workingHoursFrom!),
      if (workingHoursTo != null)
        'working_hours_to': CyberTimeFormat.toDb(workingHoursTo!),
      'is_active': isActive ?? true,
      'is_featured': false,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'lat': lat,
      'lng': lng,
      if (images != null) 'images': images,
      'cover_image': coverImage,
      if (workingHoursFrom != null)
        'working_hours_from': CyberTimeFormat.toDb(workingHoursFrom!),
      if (workingHoursTo != null)
        'working_hours_to': CyberTimeFormat.toDb(workingHoursTo!),
      if (isActive != null) 'is_active': isActive,
    };
    map.removeWhere((_, v) => v == null);
    return map;
  }
}
