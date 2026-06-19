/// Which standalone app build is running.
enum AppVariant {
  /// Consumer app — discover and book gaming centers.
  user,

  /// Platform admin — fee review, oversight.
  admin,

  /// Cyber café owner dashboard — stations, schedule, requests.
  owner,
}

extension AppVariantX on AppVariant {
  String get appTitle {
    switch (this) {
      case AppVariant.user:
        return 'GamingHub';
      case AppVariant.admin:
        return 'GamingHub Admin';
      case AppVariant.owner:
        return 'GamingHub Cyber';
    }
  }

  bool get usesDarkTheme => this == AppVariant.user;
}
