import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io' show Platform;
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/localization/app_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (mobile only - web doesn't need it)
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  await AppLocalization.init();

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: AppLocalization.supportedLocales,
        fallbackLocale: AppLocalization.fallbackLocale,
        path: 'assets/translations',
        child: const GamingHubApp(),
      ),
    ),
  );
}
