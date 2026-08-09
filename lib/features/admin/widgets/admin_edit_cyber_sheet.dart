import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/cyber.dart';
import '../../../data/repositories/cyber_repository.dart';
import '../providers/admin_accounts_providers.dart';

class AdminEditCyberSheet extends ConsumerStatefulWidget {
  final Cyber cyber;

  const AdminEditCyberSheet({super.key, required this.cyber});

  @override
  ConsumerState<AdminEditCyberSheet> createState() => _AdminEditCyberSheetState();
}

class _AdminEditCyberSheetState extends ConsumerState<AdminEditCyberSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.cyber.name);
    _descCtrl = TextEditingController(text: widget.cyber.description ?? '');
    _cityCtrl = TextEditingController(text: widget.cyber.city ?? '');
    _addressCtrl = TextEditingController(text: widget.cyber.address ?? '');
    _latCtrl = TextEditingController(text: widget.cyber.lat?.toString() ?? '');
    _lngCtrl = TextEditingController(text: widget.cyber.lng?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      await CyberRepository().updateCyber(
        cyberId: widget.cyber.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        lat: double.tryParse(_latCtrl.text.trim()),
        lng: double.tryParse(_lngCtrl.text.trim()),
      );

      ref.invalidate(allCybersProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cyber profile updated successfully'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textMuted),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.green),
          ),
          filled: true,
          fillColor: AppColors.darkBg,
        ),
        validator: (v) => v == null || v.trim().isEmpty && label == 'Name' ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Cyber Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildTextField('Name', _nameCtrl),
                _buildTextField('Description', _descCtrl, maxLines: 2),
                _buildTextField('City', _cityCtrl),
                _buildTextField('Address', _addressCtrl),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Latitude', _latCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Longitude', _lngCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
