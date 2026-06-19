/// Maps Postgres `time` values (e.g. `10:00:00`) to UI `HH:mm` and back.
class CyberTimeFormat {
  CyberTimeFormat._();

  static String toDisplay(dynamic value) {
    if (value == null) return '10:00';
    final raw = value.toString().trim();
    if (raw.isEmpty) return '10:00';
    final parts = raw.split(':');
    if (parts.length >= 2) {
      final h = parts[0].padLeft(2, '0');
      final m = parts[1].padLeft(2, '0');
      return '$h:$m';
    }
    return raw;
  }

  /// Supabase/Postgres `time` column (HH:mm:ss).
  static String toDb(String display) {
    final trimmed = display.trim();
    if (RegExp(r'^\d{1,2}:\d{2}:\d{2}$').hasMatch(trimmed)) {
      final parts = trimmed.split(':');
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:${parts[2].padLeft(2, '0')}';
    }
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(trimmed)) {
      final parts = trimmed.split(':');
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:00';
    }
    return '10:00:00';
  }
}
