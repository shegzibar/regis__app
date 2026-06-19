import 'package:supabase_flutter/supabase_flutter.dart';

String supabaseErrorMessage(Object error) {
  if (error is PostgrestException) {
    final msg = error.message.trim();
    final details = error.details?.toString();
    if (details != null && details.isNotEmpty) {
      return '$msg ($details)';
    }
    return msg.isNotEmpty ? msg : 'Database request failed';
  }
  return error.toString().replaceAll('Exception: ', '');
}
