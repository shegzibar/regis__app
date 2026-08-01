import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../constants/cd_colors.dart';
import '../providers/cd_providers.dart';

class WorkersPage extends ConsumerWidget {
  const WorkersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workersAsync = ref.watch(cyberWorkersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'cyber.workers'.tr(),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kSidebarText),
                  ),
                  Text(
                    'cyber.manage_staff_accounts_allowed'.tr(),
                    style: const TextStyle(fontSize: 12, color: kGray),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const _AddWorkerDialog(),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: Text('cyber.add_worker'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          workersAsync.when(
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (workers) {
              if (workers.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(kRadius),
                    border: Border.all(color: kBorder, width: 0.5),
                  ),
                  child: Center(
                    child: Text(
                        'cyber.no_workers_found'.tr()),
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(color: kBorder, width: 0.5),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: workers.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 0.5, thickness: 0.5),
                  itemBuilder: (context, i) {
                    final w = workers[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: kPurpleLight,
                        child: Text(
                          (w.name?.isNotEmpty == true
                                  ? w.name![0]
                                  : w.phone?.substring(0, 1) ?? '?')
                              .toUpperCase(),
                          style: const TextStyle(
                              color: kPurple, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        w.name ?? 'No Name',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.phone?.isNotEmpty == true ? w.phone! : 'No contact info',
                              style: const TextStyle(
                                  fontSize: 12, color: kGray)),
                          const SizedBox(height: 4),
                          Text(
                            'Joined: ${DateFormat('MMM yyyy').format(w.createdAt)}',
                            style: const TextStyle(
                                fontSize: 11, color: kGray),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: kBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: kBorder),
                            ),
                            child: Text(
                              w.role == 'manager' 
                                  ? 'cyber.manager_role'.tr()
                                  : 'cyber.worker_role'.tr(),
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: kSidebarText),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20, color: kGray),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => _EditWorkerDialog(worker: w),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            onPressed: () => _confirmRemove(context, ref, w),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref, dynamic worker) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('cyber.remove_worker'.tr()),
        content: Text('cyber.confirm_remove'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cyber.cancel'.tr(), style: const TextStyle(color: kGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: Text('cyber.remove_worker'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(cdCyberRepoProvider).removeWorker(userId: worker.id);
        ref.invalidate(cyberWorkersProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('cyber.worker_removed'.tr())),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

class _AddWorkerDialog extends ConsumerStatefulWidget {
  const _AddWorkerDialog();

  @override
  ConsumerState<_AddWorkerDialog> createState() => _AddWorkerDialogState();
}

class _AddWorkerDialogState extends ConsumerState<_AddWorkerDialog> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedRole = 'worker';
  bool _isLoading = false;

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('cyber.fill_all_fields'.tr())),
      );
      return;
    }

    final cyber = await ref.read(currentCyberProvider.future);
    if (cyber == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(cdCyberRepoProvider).addWorker(
            cyberId: cyber.id,
            name: name,
            email: email,
            password: pass,
            role: _selectedRole,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ref.invalidate(cyberWorkersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('cyber.worker_added'.tr())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('cyber.add_worker'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'cyber.name'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: 'cyber.email'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'cyber.password'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: 'cyber.role'.tr(),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'worker', child: Text('cyber.worker_role'.tr())),
                DropdownMenuItem(value: 'manager', child: Text('cyber.manager_role'.tr())),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedRole = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('cyber.cancel'.tr(), style: const TextStyle(color: kGray)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPurple,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text('cyber.add'.tr()),
        ),
      ],
    );
  }
}

class _EditWorkerDialog extends ConsumerStatefulWidget {
  final dynamic worker;
  const _EditWorkerDialog({required this.worker});

  @override
  ConsumerState<_EditWorkerDialog> createState() => _EditWorkerDialogState();
}

class _EditWorkerDialogState extends ConsumerState<_EditWorkerDialog> {
  late TextEditingController _nameCtrl;
  late String _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.worker.name ?? '');
    _selectedRole = widget.worker.role == 'manager' ? 'manager' : 'worker';
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('cyber.fill_all_fields'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(cdCyberRepoProvider).updateWorker(
            userId: widget.worker.id,
            name: name,
            role: _selectedRole,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ref.invalidate(cyberWorkersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('cyber.worker_updated'.tr())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('cyber.edit_worker'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'cyber.name'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: 'cyber.role'.tr(),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'worker', child: Text('cyber.worker_role'.tr())),
                DropdownMenuItem(value: 'manager', child: Text('cyber.manager_role'.tr())),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedRole = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('cyber.cancel'.tr(), style: const TextStyle(color: kGray)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPurple,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text('cyber.save'.tr()),
        ),
      ],
    );
  }
}
