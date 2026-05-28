import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/room.dart';
import '../../data/models/station.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/repositories/station_repository.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository();
});

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  return StationRepository();
});

// Rooms for a given cyber
final cyberRoomsProvider =
    FutureProvider.family<List<Room>, String>((ref, cyberId) async {
  return ref.read(roomRepositoryProvider).getCyberRooms(cyberId);
});

// Room by ID (needed before booking)
final roomByIdProvider =
    FutureProvider.family<Room?, String>((ref, roomId) async {
  return ref.read(roomRepositoryProvider).getRoomById(roomId);
});

// Stations for a given room
final roomStationsProvider =
    FutureProvider.family<List<Station>, String>((ref, roomId) async {
  return ref.read(stationRepositoryProvider).getRoomStations(roomId);
});
