import 'cyber_profile_input.dart';
import 'room.dart';
import 'station.dart';

/// Room row with nested stations for cyber profile management.
class CyberRoomProfile {
  final Room room;
  final List<Station> stations;

  const CyberRoomProfile({required this.room, required this.stations});

  factory CyberRoomProfile.fromMap(Map<String, dynamic> map) {
    final stationsRaw = map['stations'] as List? ?? [];
    final roomMap = Map<String, dynamic>.from(map)..remove('stations');
    return CyberRoomProfile(
      room: Room.fromMap(roomMap),
      stations: stationsRaw
          .map((s) => Station.fromMap(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Cyber fields for onboarding / setup (maps to `cybers` table).
class OnboardingCyberPayload {
  final String name;
  final String? description;
  final String address;
  final String city;
  final double? lat;
  final double? lng;
  final String workingHoursFrom;
  final String workingHoursTo;
  final String? coverImage;

  const OnboardingCyberPayload({
    required this.name,
    this.description,
    required this.address,
    required this.city,
    this.lat,
    this.lng,
    this.workingHoursFrom = '10:00',
    this.workingHoursTo = '02:00',
    this.coverImage,
  });

  CyberProfileInput toProfileInput() => CyberProfileInput(
        name: name,
        description: description,
        address: address,
        city: city,
        lat: lat,
        lng: lng,
        coverImage: coverImage,
        workingHoursFrom: workingHoursFrom,
        workingHoursTo: workingHoursTo,
      );

  Map<String, dynamic> toInsertMap({required String ownerId}) =>
      toProfileInput().toInsertMap(ownerId: ownerId);
}

/// Payload assembled during owner onboarding (step 2 submit).
class OnboardingSubmitPayload {
  final String cyberName;
  final String? description;
  final String address;
  final String city;
  final double? lat;
  final double? lng;
  final String workingHoursFrom;
  final String workingHoursTo;
  final String? coverImage;
  final String email;
  final String password;
  final List<OnboardingRoomSelection> rooms;

  const OnboardingSubmitPayload({
    required this.cyberName,
    this.description,
    required this.address,
    required this.city,
    this.lat,
    this.lng,
    this.workingHoursFrom = '10:00',
    this.workingHoursTo = '02:00',
    this.coverImage,
    required this.email,
    required this.password,
    required this.rooms,
  });

  Map<String, dynamic> toJson() => {
        'cyber': {
          'name': cyberName,
          'description': description,
          'address': address,
          'city': city,
          'lat': lat,
          'lng': lng,
          'working_hours_from': workingHoursFrom,
          'working_hours_to': workingHoursTo,
          'cover_image': coverImage,
        },
        'rooms': rooms.map((r) => r.toJson()).toList(),
      };
}

class OnboardingRoomSelection {
  final String optionId;
  final String dbType;
  final String displayName;
  final int stationCount;
  final double pricePerHour;

  const OnboardingRoomSelection({
    required this.optionId,
    required this.dbType,
    required this.displayName,
    required this.stationCount,
    required this.pricePerHour,
  });

  Map<String, dynamic> toJson() => {
        'option_id': optionId,
        'type': dbType,
        'name': displayName,
        'station_count': stationCount,
        'price_per_hour': pricePerHour,
      };
}
