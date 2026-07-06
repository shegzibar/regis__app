import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/repositories/cyber_repository.dart';

class AdminCreateCyberScreen extends ConsumerStatefulWidget {
  const AdminCreateCyberScreen({super.key});

  @override
  ConsumerState<AdminCreateCyberScreen> createState() =>
      _AdminCreateCyberScreenState();
}

class _AdminCreateCyberScreenState
    extends ConsumerState<AdminCreateCyberScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ownerNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  
  final _cyberNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  TimeOfDay _workingHoursFrom = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _workingHoursTo = const TimeOfDay(hour: 2, minute: 0);

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _successMessage;

  @override
  void dispose() {
    _ownerNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _cyberNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime(bool isFrom) async {
    final current = isFrom ? _workingHoursFrom : _workingHoursTo;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _workingHoursFrom = picked;
        } else {
          _workingHoursTo = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _successMessage = null;
    });

    try {
      // 1. Create Supabase Auth user + profiles row with role = 'owner'
      final newUser = await ref
          .read(authControllerProvider.notifier)
          .signUpWithEmailAndPassword(
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
            _ownerNameCtrl.text.trim(),
            _phoneCtrl.text.trim(),
            role: 'owner',
          );

      // 2. Create the cybers row for the new owner
      await CyberRepository().createCyber(
        ownerId: newUser.id,
        name: _cyberNameCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        address:
            _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        lat: double.tryParse(_latCtrl.text.trim()),
        lng: double.tryParse(_lngCtrl.text.trim()),
        workingHoursFrom: _formatTimeOfDay(_workingHoursFrom),
        workingHoursTo: _formatTimeOfDay(_workingHoursTo),
      );

      if (mounted) {
        setState(() {
          _successMessage =
              'Account created!\nEmail: ${_emailCtrl.text.trim()}\nPassword: ${_passwordCtrl.text}';
          _isLoading = false;
        });
        _formKey.currentState!.reset();
        _ownerNameCtrl.clear();
        _emailCtrl.clear();
        _passwordCtrl.clear();
        _confirmPasswordCtrl.clear();
        _cyberNameCtrl.clear();
        _descriptionCtrl.clear();
        _phoneCtrl.clear();
        _cityCtrl.clear();
        _addressCtrl.clear();
        _latCtrl.clear();
        _lngCtrl.clear();
        _workingHoursFrom = const TimeOfDay(hour: 10, minute: 0);
        _workingHoursTo = const TimeOfDay(hour: 2, minute: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                const Text(
                  'Create Cyber Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Create a login account for a cyber café owner and set up their café.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),

                const SizedBox(height: 28),

                // ── Success banner ──
                if (_successMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: AppColors.green, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Account Created Successfully!',
                              style: TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _successMessage!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Please share these credentials with the owner securely.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Section: Owner Info ──
                _SectionHeader(
                    icon: Icons.person_outline, title: 'Owner Information'),
                const SizedBox(height: 12),
                _buildField(
                  controller: _ownerNameCtrl,
                  label: 'Owner Name',
                  hint: 'e.g. Ahmed Hassan',
                  icon: Icons.badge_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _phoneCtrl,
                  label: 'Phone Number',
                  hint: 'e.g. 01012345678',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'owner@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildPasswordField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  hint: 'Min. 6 characters',
                  isObscured: _obscurePassword,
                  onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  }
                ),
                const SizedBox(height: 14),
                _buildPasswordField(
                  controller: _confirmPasswordCtrl,
                  label: 'Confirm Password',
                  hint: 'Re-enter password',
                  isObscured: _obscureConfirmPassword,
                  onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v != _passwordCtrl.text) return 'Passwords do not match';
                    return null;
                  }
                ),

                const SizedBox(height: 24),

                // ── Section: Cyber Info ──
                _SectionHeader(
                    icon: Icons.store_outlined, title: 'Cyber Café Details'),
                const SizedBox(height: 12),
                _buildField(
                  controller: _cyberNameCtrl,
                  label: 'Cyber Café Name',
                  hint: 'e.g. Matrix Gaming Lounge',
                  icon: Icons.computer_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _descriptionCtrl,
                  label: 'Description',
                  hint: 'Tell us about the café...',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _addressCtrl,
                  label: 'Address',
                  hint: 'e.g. 5 Tahrir Square, Downtown',
                  icon: Icons.place_outlined,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _cityCtrl,
                  label: 'City',
                  hint: 'e.g. Cairo',
                  icon: Icons.location_city_outlined,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _latCtrl,
                        label: 'Latitude (optional)',
                        hint: 'e.g. 30.0444',
                        icon: Icons.map_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildField(
                        controller: _lngCtrl,
                        label: 'Longitude (optional)',
                        hint: 'e.g. 31.2357',
                        icon: Icons.map_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                
                // Working hours
                Row(
                  children: [
                    Expanded(
                      child: _buildTimePickerField(
                        label: 'Working Hours From',
                        time: _workingHoursFrom,
                        onTap: () => _pickTime(true),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildTimePickerField(
                        label: 'Working Hours To',
                        time: _workingHoursTo,
                        onTap: () => _pickTime(false),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Submit ──
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.green.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                        : const Text(
                            'Create Account & Cyber Café',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerField({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: AppColors.textMuted, size: 18),
                const SizedBox(width: 12),
                Text(
                  time.format(context),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: maxLines == 1 ? Icon(icon, color: AppColors.textMuted, size: 18) : Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: Icon(icon, color: AppColors.textMuted, size: 18),
            ),
            filled: true,
            fillColor: AppColors.darkCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.green),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isObscured,
    required VoidCallback onToggleVisibility,
    required String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isObscured,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.lock_outline,
                color: AppColors.textMuted, size: 18),
            suffixIcon: GestureDetector(
              onTap: onToggleVisibility,
              child: Icon(
                isObscured
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: AppColors.textMuted,
                size: 18,
              ),
            ),
            filled: true,
            fillColor: AppColors.darkCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.green),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.green, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

