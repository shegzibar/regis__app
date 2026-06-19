import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/cyber_profile_provider.dart';
import '../../../core/providers/owner_dashboard_provider.dart';
import '../../../data/models/cyber_room_profile.dart';
import '../widgets/cyber_header_lang_toggle.dart';

class _RoomOptionDef {
  final String id;
  final String dbType;
  final String labelKey;
  final IconData icon;
  final double defaultPrice;

  const _RoomOptionDef({
    required this.id,
    required this.dbType,
    required this.labelKey,
    required this.icon,
    required this.defaultPrice,
  });
}

const _roomOptions = [
  _RoomOptionDef(
    id: 'ps5',
    dbType: 'ps5',
    labelKey: 'owner_onboarding.room_ps5',
    icon: Icons.sports_esports,
    defaultPrice: 80,
  ),
  _RoomOptionDef(
    id: 'ps4',
    dbType: 'ps5',
    labelKey: 'owner_onboarding.room_ps4',
    icon: Icons.videogame_asset,
    defaultPrice: 60,
  ),
  _RoomOptionDef(
    id: 'pc',
    dbType: 'pc',
    labelKey: 'owner_onboarding.room_pc',
    icon: Icons.computer,
    defaultPrice: 50,
  ),
  _RoomOptionDef(
    id: 'vip',
    dbType: 'vip',
    labelKey: 'owner_onboarding.room_vip',
    icon: Icons.star,
    defaultPrice: 120,
  ),
];

class OwnerOnboardingScreen extends ConsumerStatefulWidget {
  /// When true, user is already signed in — only create cyber + rooms (profile setup).
  final bool completeSetupOnly;

  const OwnerOnboardingScreen({
    super.key,
    this.completeSetupOnly = false,
  });

  @override
  ConsumerState<OwnerOnboardingScreen> createState() =>
      _OwnerOnboardingScreenState();
}

class _OwnerOnboardingScreenState extends ConsumerState<OwnerOnboardingScreen> {
  final _pageController = PageController();
  int _step = 0;

  final _cyberNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _coverImageController = TextEditingController();
  final _openTimeController = TextEditingController(text: '10:00');
  final _closeTimeController = TextEditingController(text: '02:00');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKeyStep1 = GlobalKey<FormState>();

  final Map<String, bool> _selected = {};
  final Map<String, int> _stationCounts = {};
  bool _obscurePassword = true;
  bool _submitting = false;
  bool _prefilledName = false;

  @override
  void initState() {
    super.initState();
    for (final o in _roomOptions) {
      _selected[o.id] = false;
      _stationCounts[o.id] = 2;
    }
  }

  void _prefillFromSession() {
    if (_prefilledName || !widget.completeSetupOnly) return;
    final name = ref.read(authStateProvider)?.name;
    if (name != null && name.isNotEmpty && _cyberNameController.text.isEmpty) {
      _cyberNameController.text = name;
    }
    _prefilledName = true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cyberNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _coverImageController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0 && _formKeyStep1.currentState?.validate() != true) return;
    if (_step < 1) {
      setState(() => _step = 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step = 0);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  List<OnboardingRoomSelection> _buildRoomSelections() {
    final list = <OnboardingRoomSelection>[];
    for (final opt in _roomOptions) {
      if (_selected[opt.id] != true) continue;
      list.add(OnboardingRoomSelection(
        optionId: opt.id,
        dbType: opt.dbType,
        displayName: opt.labelKey.tr(),
        stationCount: _stationCounts[opt.id] ?? 1,
        pricePerHour: opt.defaultPrice,
      ));
    }
    return list;
  }

  Future<void> _submit() async {
    if (_formKeyStep1.currentState?.validate() != true) {
      setState(() => _step = 0);
      _pageController.jumpToPage(0);
      return;
    }
    final rooms = _buildRoomSelections();
    if (rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('owner_onboarding.select_room'.tr())),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final cyber = OnboardingCyberPayload(
        name: _cyberNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        lat: double.tryParse(_latController.text.trim()),
        lng: double.tryParse(_lngController.text.trim()),
        workingHoursFrom: _openTimeController.text.trim(),
        workingHoursTo: _closeTimeController.text.trim(),
        coverImage: _coverImageController.text.trim().isEmpty
            ? null
            : _coverImageController.text.trim(),
      );

      if (widget.completeSetupOnly) {
        final user = ref.read(authStateProvider);
        if (user == null) {
          throw Exception('Not signed in');
        }
        await ref
            .read(ownerRepositoryProvider)
            .completeCyberSetupForExistingOwner(
              ownerUserId: user.id,
              cyber: cyber,
              rooms: rooms,
            );
      } else {
        final payload = OnboardingSubmitPayload(
          cyberName: cyber.name,
          description: cyber.description,
          address: cyber.address,
          city: cyber.city,
          lat: cyber.lat,
          lng: cyber.lng,
          workingHoursFrom: cyber.workingHoursFrom,
          workingHoursTo: cyber.workingHoursTo,
          coverImage: cyber.coverImage,
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rooms: rooms,
        );

        await ref
            .read(ownerRepositoryProvider)
            .completeOwnerOnboarding(payload);

        final signedIn = await ref
            .read(authControllerProvider.notifier)
            .signInWithEmailAndPassword(
              _emailController.text.trim(),
              _passwordController.text,
            );

        ref.read(authStateProvider.notifier).setUser(signedIn);
      }

      ref.invalidate(ownerCybersProvider);
      ref.invalidate(cyberProfileCyberListProvider);
      ref.invalidate(ownerDashboardStatsProvider);

      if (mounted) {
        context.go('/cyber');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _prefillFromSession();
    final isRtl = context.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    const CyberHeaderLangToggle(),
                    const Spacer(),
                    if (_step > 0)
                      TextButton(
                        onPressed: _prevStep,
                        child: Text('common.back'.tr()),
                      ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Text(
                      'owner_onboarding.title'.tr(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.purple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _StepIndicator(
                            label: '1',
                            title: 'owner_onboarding.step_basic'.tr(),
                            active: _step == 0,
                            done: _step > 0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StepIndicator(
                            label: '2',
                            title: 'owner_onboarding.step_rooms'.tr(),
                            active: _step == 1,
                            done: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _Step1Form(
                      formKey: _formKeyStep1,
                      cyberName: _cyberNameController,
                      description: _descriptionController,
                      address: _addressController,
                      city: _cityController,
                      lat: _latController,
                      lng: _lngController,
                      coverImage: _coverImageController,
                      openTime: _openTimeController,
                      closeTime: _closeTimeController,
                      email: _emailController,
                      password: _passwordController,
                      obscurePassword: _obscurePassword,
                      onTogglePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      hideAccountFields: widget.completeSetupOnly,
                    ),
                    _Step2Rooms(
                      selected: _selected,
                      stationCounts: _stationCounts,
                      onToggle: (id, v) => setState(() => _selected[id] = v),
                      onCountChanged: (id, count) =>
                          setState(() => _stationCounts[id] = count),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        _submitting ? null : (_step == 0 ? _nextStep : _submit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _step == 0
                                ? 'common.next'.tr()
                                : (widget.completeSetupOnly
                                    ? 'owner_profile.finish_setup'.tr()
                                    : 'owner_onboarding.submit'.tr()),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
              if (widget.completeSetupOnly)
                TextButton(
                  onPressed: () => context.go('/owner/profile'),
                  child: Text('common.back'.tr()),
                )
              else
                TextButton(
                  onPressed: () => context.go('/auth'),
                  child: Text('owner_onboarding.have_account'.tr()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final String label;
  final String title;
  final bool active;
  final bool done;

  const _StepIndicator({
    required this.label,
    required this.title,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppColors.teal
        : active
            ? AppColors.purple
            : const Color(0xFFE2E8F0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: active || done ? color.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active || done
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step1Form extends StatelessWidget {
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

  const _Step1Form({
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

class _Step2Rooms extends StatelessWidget {
  final Map<String, bool> selected;
  final Map<String, int> stationCounts;
  final void Function(String id, bool value) onToggle;
  final void Function(String id, int count) onCountChanged;

  const _Step2Rooms({
    required this.selected,
    required this.stationCounts,
    required this.onToggle,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          'owner_onboarding.rooms_hint'.tr(),
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: _roomOptions.map((opt) {
            final isOn = selected[opt.id] == true;
            return _RoomCard(
              option: opt,
              selected: isOn,
              count: stationCounts[opt.id] ?? 1,
              onTap: () => onToggle(opt.id, !isOn),
              onCountChanged: (c) => onCountChanged(opt.id, c),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  final _RoomOptionDef option;
  final bool selected;
  final int count;
  final VoidCallback onTap;
  final ValueChanged<int> onCountChanged;

  const _RoomCard({
    required this.option,
    required this.selected,
    required this.count,
    required this.onTap,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.purpleLight : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.purple : const Color(0xFFE2E8F0),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(option.icon,
                      color: selected ? AppColors.purple : AppColors.textMuted),
                  const Spacer(),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? AppColors.purple : AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                option.labelKey.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? AppColors.purple : AppColors.textPrimary,
                ),
              ),
              if (selected) ...[
                const Spacer(),
                Text(
                  'owner_onboarding.station_count'.tr(),
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CountBtn(
                      icon: Icons.remove,
                      onTap: count > 1 ? () => onCountChanged(count - 1) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _CountBtn(
                      icon: Icons.add,
                      onTap:
                          count < 30 ? () => onCountChanged(count + 1) : null,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CountBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.purple.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: AppColors.purple),
        ),
      ),
    );
  }
}
