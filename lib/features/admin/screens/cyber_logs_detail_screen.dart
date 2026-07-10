import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/system_log.dart';

class CyberLogsDetailScreen extends StatelessWidget {
  final String cyberName;
  final List<SystemLog> logs;

  const CyberLogsDetailScreen({
    super.key,
    required this.cyberName,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text('$cyberName Activity Logs'),
        backgroundColor: AppColors.darkCard,
        elevation: 0,
      ),
      body: logs.isEmpty
          ? const Center(
              child: Text(
                'No recent activity logs for this cyber.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  color: AppColors.darkCard,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.darkBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                log.eventType,
                                style: const TextStyle(
                                  color: AppColors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              _formatDate(log.createdAt),
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (log.userName != null) ...[
                          Text('User: ${log.userName}',
                              style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 4),
                        ],
                        if (log.details != null && log.details!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              log.details.toString(),
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
