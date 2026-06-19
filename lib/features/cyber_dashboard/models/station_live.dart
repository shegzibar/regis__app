/// A station enriched with live booking status — used by the Cyber Dashboard.
class StationLive {
  final String id;
  final String roomId;
  final String name;
  final String status; // 'active' | 'maintenance' | 'blocked'
  final bool isBusy;
  final String? currentUser; // name of customer currently using it
  final DateTime? busyUntil;
  final String? source; // 'app' | 'manual'

  const StationLive({
    required this.id,
    required this.roomId,
    required this.name,
    required this.status,
    this.isBusy = false,
    this.currentUser,
    this.busyUntil,
    this.source,
  });

  factory StationLive.fromMap(Map<String, dynamic> map) {
    return StationLive(
      id: map['id'] as String,
      roomId: map['room_id'] as String,
      name: map['name'] as String,
      status: map['status'] as String? ?? 'active',
      isBusy: map['is_busy'] as bool? ?? false,
      currentUser: map['current_user'] as String?,
      busyUntil: map['busy_until'] != null
          ? DateTime.tryParse(map['busy_until'] as String)
          : null,
      source: map['source'] as String?,
    );
  }

  bool get isActive => status == 'active';
  bool get isMaintenance => status == 'maintenance';
  bool get isBlocked => status == 'blocked';
  bool get isAvailableNow => isActive && !isBusy;

  String statusLabel({bool arabic = true}) {
    if (isMaintenance) return arabic ? 'صيانة' : 'Maintenance';
    if (isBlocked) return arabic ? 'محجوبة' : 'Blocked';
    if (isBusy) return currentUser ?? (arabic ? 'مشغولة' : 'Busy');
    return arabic ? 'متاحة' : 'Free';
  }
}
