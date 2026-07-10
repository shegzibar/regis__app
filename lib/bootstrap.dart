import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/config/app_variant.dart';
import 'core/router/root_router.dart';
import 'core/constants/app_constants.dart';
import 'core/localization/app_localization.dart';
import 'firebase_options.dart';

/// Whether Firebase was successfully initialized at app startup.
bool _firebaseReady = false;
bool get firebaseIsReady => _firebaseReady;

/// Riverpod provider that exposes Firebase readiness state.
final firebaseReadyProvider = Provider<bool>((_) => _firebaseReady);

/// Shared Supabase + Firebase + localization setup for every app entry point.
Future<void> initializeForya() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialize Firebase (used for CX support Firestore chat)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _firebaseReady = true;
  } catch (e) {
    _firebaseReady = false;
    debugPrint('Firebase initialization failed (Firebase not configured for this platform): $e');
  }

  await dotenv.load(fileName: ".env");

  await AppLocalization.init();
}

/// Root widget tree for a given app variant (user / admin / cyber dashboard).
Widget buildForyaRoot({required AppVariant variant}) {
  return ProviderScope(
    overrides: [
      appVariantProvider.overrideWithValue(variant),
    ],
    child: EasyLocalization(
      supportedLocales: AppLocalization.supportedLocales,
      fallbackLocale: AppLocalization.fallbackLocale,
      startLocale: variant == AppVariant.owner
          ? const Locale('ar')
          : AppLocalization.fallbackLocale,
      path: 'assets/translations',
      child: const ForyaApp(),
    ),
  );
}
