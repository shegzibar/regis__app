import 'package:flutter/material.dart';
import 'bootstrap.dart';
import 'core/config/app_variant.dart';

/// Consumer app — discover and book gaming centers.
void main() async {
  await initializeGamingHub();
  runApp(buildGamingHubRoot(variant: AppVariant.user));
}
