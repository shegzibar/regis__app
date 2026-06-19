import 'package:flutter/material.dart';
import 'bootstrap.dart';
import 'core/config/app_variant.dart';

/// Platform admin app — fee review and oversight.
void main() async {
  await initializeGamingHub();
  runApp(buildGamingHubRoot(variant: AppVariant.admin));
}
