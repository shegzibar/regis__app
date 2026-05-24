import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/app_colors.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Language', // This will be localized later
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // English Option
          _buildLanguageOption(
            context: context,
            language: 'English',
            locale: const Locale('en', 'US'),
            flag: '🇺🇸',
          ),
          
          const SizedBox(height: 12),
          
          // Arabic Option
          _buildLanguageOption(
            context: context,
            language: 'العربية',
            locale: const Locale('ar', 'EG'),
            flag: '🇪🇬',
          ),
        ],
      ),
    );
  }
  
  Widget _buildLanguageOption({
    required BuildContext context,
    required String language,
    required Locale locale,
    required String flag,
  }) {
    final isSelected = context.locale == locale;
    
    return GestureDetector(
      onTap: () async {
        await context.setLocale(locale);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.green.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.green : AppColors.darkBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 24),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Text(
                language,
                style: TextStyle(
                  color: isSelected ? AppColors.green : Colors.white,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            
            if (isSelected)
              const Icon(
                Icons.check,
                color: AppColors.green,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.darkCard,
            title: Text(
              'Select Language', // This will be localized later
              style: const TextStyle(color: Colors.white),
            ),
            content: const LanguageSwitcher(),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close', // This will be localized later
                  style: const TextStyle(color: AppColors.teal),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'English',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
