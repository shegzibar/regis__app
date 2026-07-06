import 'package:flutter/material.dart';
import 'bootstrap.dart';
import 'core/config/app_variant.dart';

/// Cyber café owner dashboard — stations, schedule, and booking requests.
void main() async {
  await initializeForya();
  runApp(buildForyaRoot(variant: AppVariant.owner));
}
