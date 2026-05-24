import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._();
  
  factory SupabaseService() {
    return _instance;
  }
  
  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;
  
  // Auth
  GoTrueClient get auth => client.auth;
  
  // Database
  SupabaseQueryBuilder from(String table) => client.from(table);
  
  // Storage
  SupabaseStorageClient get storage => client.storage;
  
  // Realtime
  RealtimeClient get realtime => client.realtime;
  
  // Current user
  User? get currentUser => auth.currentUser;
  
  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;
  
  // Get current session
  Session? get currentSession => auth.currentSession;
}
