import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  final supabase = SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_ANON_KEY']!,
  );
  try {
    final data = await supabase.from('bookings').select('''
        id, status, start_time, end_time, total_amount, booking_fee,
        created_at, notes, user_id,
        stations!inner(
          id, name,
          rooms!inner(
            id, name, type,
            cybers!inner(id, name, city)
          )
        )
      ''').order('created_at', ascending: false);
    print('Success: \${data.length} records');
  } catch (e) {
    print('Error: \$e');
  }
}
