class OwnerBookingItem {
  final String id;
  final String status;
  final DateTime startTime;
  final DateTime endTime;
  final double durationHours;
  final double totalAmount;
  final String? notes;
  final String stationName;
  final String roomName;
  final String roomType;
  final String cyberName;

  const OwnerBookingItem({
    required this.id,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.totalAmount,
    this.notes,
    required this.stationName,
    required this.roomName,
    required this.roomType,
    required this.cyberName,
  });

  bool get isManual =>
      (notes ?? '').toLowerCase().contains('manual') ||
      (notes ?? '').contains('حضور');

  factory OwnerBookingItem.fromMap(Map<String, dynamic> map) {
    final stations = map['stations'] as Map<String, dynamic>?;
    final rooms = stations?['rooms'] as Map<String, dynamic>?;
    final cybers = rooms?['cybers'] as Map<String, dynamic>?;

    return OwnerBookingItem(
      id: map['id'] as String,
      status: map['status'] as String? ?? 'pending_payment',
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      durationHours: (map['duration_hours'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      notes: map['notes'] as String?,
      stationName: stations?['name'] as String? ?? '—',
      roomName: rooms?['name'] as String? ?? '—',
      roomType: rooms?['type'] as String? ?? '',
      cyberName: cybers?['name'] as String? ?? '—',
    );
  }
}

class OwnerDashboardStats {
  final double todayRevenue;
  final double revenueChangePercent;
  final int todayBookings;
  final int confirmedToday;
  final int pendingToday;
  final int activeStations;
  final int totalStations;
  final int manualBookingsToday;
  final int pendingReceipts;

  const OwnerDashboardStats({
    this.todayRevenue = 0,
    this.revenueChangePercent = 0,
    this.todayBookings = 0,
    this.confirmedToday = 0,
    this.pendingToday = 0,
    this.activeStations = 0,
    this.totalStations = 0,
    this.manualBookingsToday = 0,
    this.pendingReceipts = 0,
  });
}

class OwnerStationItem {
  final String id;
  final String name;
  final String status;
  final String roomName;
  final String roomId;
  final String cyberId;

  const OwnerStationItem({
    required this.id,
    required this.name,
    required this.status,
    required this.roomName,
    required this.roomId,
    required this.cyberId,
  });

  factory OwnerStationItem.fromMap(Map<String, dynamic> map) {
    final rooms = map['rooms'] as Map<String, dynamic>?;
    return OwnerStationItem(
      id: map['id'] as String,
      name: map['name'] as String,
      status: map['status'] as String? ?? 'active',
      roomName: rooms?['name'] as String? ?? '—',
      roomId: rooms?['id'] as String? ?? '',
      cyberId: rooms?['cyber_id'] as String? ?? '',
    );
  }
}
