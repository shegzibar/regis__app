import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  final supabaseUrl = 'https://anajhyletxfzvhugdszy.supabase.co';
  final supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuYWpoeWxldHhmenZodWdkc3p5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2Njc3MzMsImV4cCI6MjA5NTI0MzczM30.AeZbuqF1HIGDiVXxCxlQLuyyQY0YlRB8BzAy4ZC4dUQ';
  
  final _db = SupabaseClient(supabaseUrl, supabaseAnonKey);
  
  print('Running query...');
  
  try {
    final data = await _db.from('bookings').select('''
        *,
        stations ( id, name, rooms ( id, name, type, cyber_id ) )
      ''').order('start_time');
        
    print('Query succeeded! Found \${data.length} bookings.');
    for (var b in data) {
      print("- Booking ID: \${b['id']} | Start: \${b['start_time']} | Station ID: \${b['station_id']} | Status: \${b['status']}");
    }
  } catch (e, stacktrace) {
    print('Query failed with error: \$e');
    print(stacktrace);
  }
  
  exit(0);
}
