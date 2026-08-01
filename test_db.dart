import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/core/constants/supabase_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );
  
  final res = await Supabase.instance.client
      .from('bookings')
      .select('id, start_time, end_time, created_at, source')
      .order('created_at', ascending: false)
      .limit(5);
      
  print("LATEST BOOKINGS RAW DATA:");
  for (var b in res) {
    print(b);
  }
}
