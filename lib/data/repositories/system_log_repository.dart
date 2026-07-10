import '../models/system_log.dart';
import '../supabase/supabase_client.dart';

class SystemLogRepository {
  final SupabaseService _supabase = SupabaseService();

  Future<List<SystemLog>> getSystemLogs({int limit = 100}) async {
    try {
      final response = await _supabase
          .from('system_logs')
          .select('''
            *,
            profiles(name),
            cybers(name)
          ''')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((log) => SystemLog.fromMap(log as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch system logs: $e');
    }
  }

  Future<void> logEvent({
    required String eventType,
    String? userId,
    String? cyberId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _supabase.from('system_logs').insert({
        'event_type': eventType,
        'user_id': userId,
        'cyber_id': cyberId,
        'details': details,
      });
    } catch (e) {
      print('Failed to log event $eventType: $e');
      throw Exception('Failed to insert log: $e');
    }
  }
}
