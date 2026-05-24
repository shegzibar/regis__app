class Station {
  final String id;
  final String roomId;
  final String name;
  final String status;
  final DateTime createdAt;

  const Station({
    required this.id,
    required this.roomId,
    required this.name,
    this.status = 'active',
    required this.createdAt,
  });

  factory Station.fromMap(Map<String, dynamic> map) {
    return Station(
      id: map['id'] as String,
      roomId: map['room_id'] as String,
      name: map['name'] as String,
      status: map['status'] as String? ?? 'active',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_id': roomId,
      'name': name,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Station copyWith({
    String? id,
    String? roomId,
    String? name,
    String? status,
    DateTime? createdAt,
  }) {
    return Station(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isActive => status == 'active';
  bool get isMaintenance => status == 'maintenance';
  bool get isBlocked => status == 'blocked';
  bool get isAvailable => isActive;

  String get statusDisplay {
    switch (status) {
      case 'active':
        return 'Available';
      case 'maintenance':
        return 'Maintenance';
      case 'blocked':
        return 'Blocked';
      default:
        return status;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Station && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Station(id: $id, name: $name, status: $status)';
  }
}
