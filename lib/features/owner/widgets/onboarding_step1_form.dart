import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';

class OnboardingStep1Form extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController cyberName;
  final TextEditingController description;
  final TextEditingController address;
  final TextEditingController city;
  final TextEditingController lat;
  final TextEditingController lng;
  final TextEditingController coverImage;
  final TextEditingController openTime;
  final TextEditingController closeTime;
  final TextEditingController email;
  final TextEditingController password;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final bool hideAccountFields;

  const OnboardingStep1Form({
    super.key,
    required this.formKey,
    required this.cyberName,
    required this.description,
    required this.address,
    required this.city,
    required this.lat,
    required this.lng,
    required this.coverImage,
    required this.openTime,
    required this.closeTime,
    required this.email,
    required this.password,
    required this.obscurePassword,
    required this.onTogglePassword,
    this.hideAccountFields = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            _Field(
              label: 'owner_onboarding.cyber_name'.tr(),
              controller: cyberName,
              validator: (v) => v == null || v.isEmpty
                  ? 'owner_onboarding.required'.tr()
                  : null,
            ),
            _Field(
              label: 'owner_profile.description'.tr(),
              controller: description,
              maxLines: 3,
            ),
            _Field(
              label: 'owner_profile.address'.tr(),
              controller: address,
              validator: (v) => v == null || v.isEmpty
                  ? 'owner_onboarding.required'.tr()
                  : null,
            ),
            _Field(
              label: 'owner_profile.city'.tr(),
              controller: city,
              validator: (v) => v == null || v.isEmpty
                  ? 'owner_onboarding.required'.tr()
                  : null,
            ),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    label: 'Latitude (optional)',
                    controller: lat,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Field(
                    label: 'Longitude (optional)',
                    controller: lng,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            _Field(
              label: 'owner_profile.cover_image'.tr(),
              controller: coverImage,
              keyboardType: TextInputType.url,
            ),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    label: 'owner_profile.open_time'.tr(),
                    controller: openTime,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Field(
                    label: 'owner_profile.close_time'.tr(),
                    controller: closeTime,
                  ),
                ),
              ],
            ),
            if (!hideAccountFields) ...[
              _Field(
                label: 'owner_onboarding.email'.tr(),
                controller: email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'owner_onboarding.required'.tr();
                  }
                  if (!v.contains('@')) {
                    return 'owner_onboarding.email_invalid'.tr();
                  }
                  return null;
                },
              ),
              _Field(
                label: 'owner_onboarding.password'.tr(),
                controller: password,
                obscure: obscurePassword,
                onToggleObscure: onTogglePassword,
                validator: (v) {
                  if (v == null || v.length < 6) {
                    return 'owner_onboarding.password_short'.tr();
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final int maxLines;

  const _Field({
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.obscure = false,
    this.onToggleObscure,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            obscureText: obscure,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.purple, width: 1.5),
              ),
              suffixIcon: onToggleObscure != null
                  ? IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: onToggleObscure,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
