import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_variant.dart';
import 'admin_router.dart';
import 'app_router.dart';
import 'owner_router.dart';

final appVariantProvider = Provider<AppVariant>((ref) => AppVariant.user);

final rootRouterProvider = Provider<GoRouter>((ref) {
  switch (ref.watch(appVariantProvider)) {
    case AppVariant.admin:
      return ref.watch(adminRouterProvider);
    case AppVariant.owner:
      return ref.watch(ownerRouterProvider);
    case AppVariant.user:
      return ref.watch(appRouterProvider);
  }
});
