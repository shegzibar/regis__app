import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatLocalizedNumber(num value, BuildContext context) {
  final locale = context.locale.languageCode;
  if (locale == 'ar') {
    const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final s = value is int || value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
  return s.split('').map((c) {
      if (c == '.') return '٫';
      if (c == '-') return '-';
      final i = int.tryParse(c);
      return i != null ? eastern[i] : c;
    }).join();
  }
  return NumberFormat.decimalPattern(locale).format(value);
}

String formatHourLabel(DateTime time, BuildContext context) {
  final locale = context.locale.languageCode;
  if (locale == 'ar') {
    final h = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'م' : 'ص';
    return '${formatLocalizedNumber(h, context)} $period';
  }
  return DateFormat('h a').format(time);
}
