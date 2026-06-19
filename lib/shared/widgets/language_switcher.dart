import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/app_colors.dart';

class LanguageButton extends StatefulWidget {
  const LanguageButton({super.key});

  @override
  State<LanguageButton> createState() => _LanguageButtonState();
}

class _LanguageButtonState extends State<LanguageButton> {
  String _getCurrentLanguageFlag() {
    final currentLocale = context.locale.languageCode;
    return currentLocale == 'ar' ? '🇪🇬' : '🇺🇸';
  }

  void _changeLanguage(Locale locale) async {
    await context.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Locale>(
      position: PopupMenuPosition.under,
      onSelected: _changeLanguage,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
        PopupMenuItem<Locale>(
          value: const Locale('en'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🇺🇸',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'common.english'.tr(),
                style: TextStyle(
                  color: context.locale.languageCode == 'en'
                      ? AppColors.green
                      : Colors.white,
                  fontWeight: context.locale.languageCode == 'en'
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (context.locale.languageCode == 'en')
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(
                    Icons.check,
                    color: AppColors.green,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
        PopupMenuItem<Locale>(
          value: const Locale('ar'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🇪🇬',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'common.arabic'.tr(),
                style: TextStyle(
                  color: context.locale.languageCode == 'ar'
                      ? AppColors.green
                      : Colors.white,
                  fontWeight: context.locale.languageCode == 'ar'
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (context.locale.languageCode == 'ar')
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(
                    Icons.check,
                    color: AppColors.green,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getCurrentLanguageFlag(),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              context.locale.languageCode == 'ar' ? 'العربية' : 'English',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
