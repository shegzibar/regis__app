import '../../data/models/user.dart';
import '../constants/app_constants.dart';

bool resolvesAccess(AppUser user, bool Function(AppUser user) canAccess) {
  if (AppConstants.bypassRoleChecksForTesting) return true;
  return canAccess(user);
}

/// Shared auth redirect logic for standalone admin / owner apps.
String? standaloneAuthRedirect({
  required AppUser? user,
  required bool isInitializing,
  required String location,
  required String homeRoute,
  required bool Function(AppUser user) canAccess,
}) {
  if (isInitializing) {
    return location == '/splash' ? null : '/splash';
  }

  final isAuthRoute = location.startsWith('/auth') ||
      location.startsWith('/signup') ||
      location == '/splash';
  final isDeniedRoute = location == '/access-denied';

  if (user == null) {
    if (!isAuthRoute) return '/auth';
    if (location == '/splash') return '/auth';
    return null;
  }

  if (isAuthRoute) {
    return resolvesAccess(user, canAccess) ? homeRoute : '/access-denied';
  }

  if (isDeniedRoute) return null;

  if (!resolvesAccess(user, canAccess)) return '/access-denied';

  return null;
}
