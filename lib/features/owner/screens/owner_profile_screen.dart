import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/cyber_profile_provider.dart';
import '../../../data/models/cyber.dart';
import '../../../data/models/user.dart';
import '../../../core/utils/supabase_error_message.dart';
import '../../../data/supabase/supabase_client.dart';
import '../widgets/cyber_center_editor.dart';
import '../widgets/profile_section_card.dart';
import '../widgets/profile_labeled_field.dart';

/// Owner dashboard profile: account settings + cyber center setup.
class OwnerProfileScreen extends ConsumerStatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  ConsumerState<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends ConsumerState<OwnerProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _accountFormKey = GlobalKey<FormState>();
  bool _savingAccount = false;
  bool _savingPassword = false;
  bool _userBound = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  void _bindUser(AppUser? user) {
    _nameController.text = user?.name ?? '';
    _emailController.text = _displayEmail(user);
  }

  static String _displayEmail(AppUser? user) {
    return user?.email ??
        SupabaseService().currentUser?.email ??
        '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (!_accountFormKey.currentState!.validate()) return;
    setState(() => _savingAccount = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            name: _nameController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('owner_profile.account_saved'.tr()),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(supabaseErrorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingAccount = false);
    }
  }

  Future<void> _changePassword() async {
    final pwd = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    if (pwd.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('owner_onboarding.password_short'.tr())),
      );
      return;
    }
    if (pwd != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('owner_profile.password_mismatch'.tr())),
      );
      return;
    }
    setState(() => _savingPassword = true);
    try {
      await ref.read(authControllerProvider.notifier).updatePassword(pwd);
      _passwordController.clear();
      _confirmPasswordController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('owner_profile.password_saved'.tr()),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    if (!_userBound && user != null) {
      _userBound = true;
      _bindUser(user);
    }

    final cybersAsync = ref.watch(cyberProfileCyberListProvider);
    final selectedId = ref.watch(selectedCyberProfileIdProvider);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: cybersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.purple),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (cybers) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'owner_profile.title'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D21),
                  ),
                ),
                const SizedBox(height: 12),
                _AccountSection(
                  formKey: _accountFormKey,
                  nameController: _nameController,
                  emailController: _emailController,
                  saving: _savingAccount,
                  onSave: _saveAccount,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                  savingPassword: _savingPassword,
                  onChangePassword: _changePassword,
                ),
                const SizedBox(height: 16),
                Text(
                  'owner_profile.center_section'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(height: 8),
                if (cybers.isEmpty)
                  _NoCyberCard(
                    onSetup: () => context.go('/owner/setup'),
                  )
                else ...[
                  if (cybers.length > 1)
                    _CyberPicker(
                      cybers: cybers,
                      selectedId: selectedId ?? cybers.first.id,
                      onChanged: (id) => ref
                          .read(selectedCyberProfileIdProvider.notifier)
                          .state = id,
                    ),
                  CyberCenterEditorSection(
                    cyber: cybers.firstWhere(
                      (c) => c.id == (selectedId ?? cybers.first.id),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final bool saving;
  final VoidCallback onSave;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool savingPassword;
  final VoidCallback onChangePassword;

  const _AccountSection({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.saving,
    required this.onSave,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.savingPassword,
    required this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      title: 'owner_profile.account'.tr(),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            ProfileLabeledField(
              label: 'owner_profile.name'.tr(),
              controller: nameController,
              validator: (v) =>
                  v == null || v.isEmpty ? 'owner_onboarding.required'.tr() : null,
            ),
            ProfileLabeledField(
              label: 'owner_onboarding.email'.tr(),
              controller: emailController,
              readOnly: true,
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('owner_profile.save_account'.tr()),
              ),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'owner_profile.change_password'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              children: [
                ProfileLabeledField(
                  label: 'owner_onboarding.password'.tr(),
                  controller: passwordController,
                  keyboardType: TextInputType.visiblePassword,
                ),
                ProfileLabeledField(
                  label: 'owner_profile.confirm_password'.tr(),
                  controller: confirmPasswordController,
                  keyboardType: TextInputType.visiblePassword,
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: savingPassword ? null : onChangePassword,
                    child: savingPassword
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('owner_profile.update_password'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoCyberCard extends StatelessWidget {
  final VoidCallback onSetup;

  const _NoCyberCard({required this.onSetup});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text('owner_profile.no_center'.tr()),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onSetup,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
            ),
            child: Text('owner_profile.setup_center'.tr()),
          ),
        ],
      ),
    );
  }
}

class _CyberPicker extends StatelessWidget {
  final List<Cyber> cybers;
  final String selectedId;
  final ValueChanged<String> onChanged;

  const _CyberPicker({
    required this.cybers,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        value: selectedId,
        decoration: InputDecoration(
          labelText: 'owner_cyber_profile.select_cyber'.tr(),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: cybers
            .map(
              (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
            )
            .toList(),
        onChanged: (id) {
          if (id != null) onChanged(id);
        },
      ),
    );
  }
}
