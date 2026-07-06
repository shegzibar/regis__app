import 'package:flutter/material.dart';
import 'bootstrap.dart';
import 'core/config/app_variant.dart';

/// Consumer app — discover and book gaming centers.
void main() async {
  await initializeForya();
  runApp(buildForyaRoot(variant: AppVariant.user));
}
