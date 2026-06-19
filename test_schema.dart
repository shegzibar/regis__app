import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  final supabase = SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_ANON_KEY']!,
  );
  try {
    final res = await supabase.from('profiles').select().limit(1);
    print(res);
  } catch (e) {
    print('Error: $e');
  }
}
