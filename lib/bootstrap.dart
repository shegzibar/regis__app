import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'app.dart';
import 'core/config/app_variant.dart';
import 'core/router/root_router.dart';
import 'core/constants/app_constants.dart';
import 'core/localization/app_localization.dart';

/// Shared Supabase + localization setup for every app entry point.
Future<void> initializeGamingHub() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  await AppLocalization.init();
}

/// Root widget tree for a given app variant (user / admin / cyber dashboard).
Widget buildGamingHubRoot({required AppVariant variant}) {
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
      child: const GamingHubApp(),
    ),
  );
}
