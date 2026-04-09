import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.08),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TaskHive Privacy Policy',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Effective date: April 9, 2026',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 20),
                        _section(
                          context,
                          '1. Information We Collect',
                          'TaskHive collects account details (such as email and username), workspace and task data you create, and usage information required to provide collaboration features.',
                        ),
                        _section(
                          context,
                          '2. How We Use Information',
                          'We use your data to authenticate your account, manage workspaces, synchronize task activity, and maintain security and reliability of the platform.',
                        ),
                        _section(
                          context,
                          '3. Workspace Access and Security',
                          'TaskHive uses role-based access and Row-Level Security (RLS) to isolate workspace data and prevent unauthorized access between hives.',
                        ),
                        _section(
                          context,
                          '4. Data Storage',
                          'Data is stored in a secure PostgreSQL backend via Supabase services. Avatar images and related files are stored in protected cloud storage.',
                        ),
                        _section(
                          context,
                          '5. Your Rights',
                          'You can request profile updates, workspace membership changes, or account deletion according to applicable law and your organization policy.',
                        ),
                        _section(
                          context,
                          '6. Contact',
                          'For privacy questions, contact your TaskHive administrator or support channel configured for your deployment.',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This policy can be updated as TaskHive evolves. Continued use means you accept the latest version.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(content, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
