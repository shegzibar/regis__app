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
        return 'Forya';
      case AppVariant.admin:
        return 'Forya Admin';
      case AppVariant.owner:
        return 'Forya Cyber';
    }
  }

  bool get usesDarkTheme => this == AppVariant.user;
}
