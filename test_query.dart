import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  final supabaseUrl = 'https://anajhyletxfzvhugdszy.supabase.co';
  final supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuYWpoeWxldHhmenZodWdkc3p5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2Njc3MzMsImV4cCI6MjA5NTI0MzczM30.AeZbuqF1HIGDiVXxCxlQLuyyQY0YlRB8BzAy4ZC4dUQ';
  
  final _db = SupabaseClient(supabaseUrl, supabaseAnonKey);
  
  print('Running query...');
  
  try {
    final data = await _db.from('cybers').select().order('created_at');
        
    print('Query succeeded! Found ${data.length} cybers.');
    for (var c in data) {
      print("- Cyber ID: ${c['id']} | Name: ${c['name']} | End Date: ${c['subscription_end_date']}");
      print("  Raw data: $c");
    }
  } catch (e, stacktrace) {
    print('Query failed with error: $e');
    print(stacktrace);
  }
  
  exit(0);
}
