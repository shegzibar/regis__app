import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  final supabaseUrl = 'https://anajhyletxfzvhugdszy.supabase.co';
  final supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuYWpoeWxldHhmenZodWdkc3p5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2Njc3MzMsImV4cCI6MjA5NTI0MzczM30.AeZbuqF1HIGDiVXxCxlQLuyyQY0YlRB8BzAy4ZC4dUQ';

  final db = SupabaseClient(supabaseUrl, supabaseAnonKey);

  print('Signing in...');
  final auth = await db.auth.signInWithPassword(
    email: 'admin@gmail.com',
    password: '123admin567',
  );
  print('Signed in as: ${auth.user?.email} (ID: ${auth.user?.id})');

  // Check their profile role
  final profile = await db.from('profiles').select('id, name, role').eq('id', auth.user!.id).maybeSingle();
  print('Profile role in DB: ${profile?['role']}');
  print('Full profile: $profile');

  // Now try to update a cyber subscription
  final cyberToUpdate = '37f89008-f814-484a-9805-0a748993a007'; // ahmed cyber
  print('\nAttempting to update cyber subscription_end_date...');
  try {
    await db.from('cybers').update({
      'subscription_end_date': '2026-12-31T00:00:00.000Z',
    }).eq('id', cyberToUpdate);

    // Check if the update actually worked
    final updated = await db.from('cybers').select('subscription_end_date').eq('id', cyberToUpdate).single();
    print('After update - subscription_end_date: ${updated['subscription_end_date']}');
    if (updated['subscription_end_date'] == null) {
      print('❌ UPDATE FAILED SILENTLY — RLS is blocking the update for this user!');
    } else {
      print('✅ UPDATE SUCCEEDED!');
      // Revert it
      await db.from('cybers').update({'subscription_end_date': null}).eq('id', cyberToUpdate);
      print('Reverted back to null.');
    }
  } catch (e) {
    print('❌ Error thrown: $e');
  }

  exit(0);
}
