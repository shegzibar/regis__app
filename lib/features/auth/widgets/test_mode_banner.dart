import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Shown on login / sign-up when test flags are enabled.
class TestModeBanner extends StatelessWidget {
  const TestModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConstants.bypassRoleChecksForTesting &&
        !AppConstants.allowTestRoleSelection) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text(
                'Test mode',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Email login works on User, Admin, and Cyber apps. '
            'On sign-up, pick a role (user, owner, manager, admin). '
            'Role checks are disabled for testing.',
            style: TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
