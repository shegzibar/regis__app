import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/localization/app_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
