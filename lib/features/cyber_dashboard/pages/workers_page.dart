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
                  // In a real app, this would trigger an invite or creation flow.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('cyber.coming_soon'.tr())),
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
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kBorder),
                        ),
                        child: Text(
                          w.role.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: kSidebarText),
                        ),
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
}
