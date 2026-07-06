import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final locationProvider = AsyncNotifierProvider<LocationNotifier, Position?>(() {
  return LocationNotifier();
});

class LocationNotifier extends AsyncNotifier<Position?> {
  @override
  Future<Position?> build() async {
    // Attempt to get location quietly on startup if permissions already granted
    return await _checkAndGetLocation(requestPermission: false);
  }

  /// Explicitly requests location permission and fetches the current position.
  Future<Position?> requestAndGetLocation() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _checkAndGetLocation(requestPermission: true);
    });
    return state.value;
  }

  Future<Position?> _checkAndGetLocation({required bool requestPermission}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (!requestPermission) return null; // Only prompt when explicitly asked

      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    // Instantly return last known position if available
    Position? position = await Geolocator.getLastKnownPosition();
    if (position != null) {
      return position;
    }

    // If absolutely necessary, fetch with low accuracy for speed (never high)
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      return null;
    }
  }
}
