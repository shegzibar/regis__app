import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/config/app_variant.dart';
import 'core/router/root_router.dart';
import 'core/theme/app_theme.dart';

class ForyaApp extends ConsumerWidget {
  const ForyaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(appVariantProvider);
    final router = ref.watch(rootRouterProvider);

    return MaterialApp.router(
      title: variant.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: variant.usesDarkTheme ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
    );
  }
}
