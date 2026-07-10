import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';

/// Compact EN / عربي toggle for the cyber dashboard header.
class CyberHeaderLangToggle extends StatelessWidget {
  const CyberHeaderLangToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangChip(
            label: 'EN',
            selected: !isAr,
            onTap: () => context.setLocale(const Locale('en')),
          ),
          _LangChip(
            label: 'عربي',
            selected: isAr,
            onTap: () => context.setLocale(const Locale('ar')),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
