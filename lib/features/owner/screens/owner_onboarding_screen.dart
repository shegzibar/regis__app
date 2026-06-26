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
import '../models/room_option_def.dart';
import '../widgets/cyber_header_lang_toggle.dart';
import '../widgets/onboarding_step_indicator.dart';
import '../widgets/onboarding_step1_form.dart';
import '../widgets/onboarding_step2_rooms.dart';

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
    for (final o in roomOptions) {
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
    for (final opt in roomOptions) {
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
                          child: OnboardingStepIndicator(
                            label: '1',
                            title: 'owner_onboarding.step_basic'.tr(),
                            active: _step == 0,
                            done: _step > 0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OnboardingStepIndicator(
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
                    OnboardingStep1Form(
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
                    OnboardingStep2Rooms(
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
