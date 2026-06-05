import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/workspace_provider.dart';
import '../../models/profile_model.dart';
import '../../models/workspace_model.dart';
import '../../services/auth_service.dart';
import '../../services/workspace_service.dart';
import '../../theme/app_colors.dart';
import '../workspace/task_board_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = AppColors.isDark(context);
    final workspacesAsync = ref.watch(workspacesProvider);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.hiveAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.hive_rounded,
                size: 20,
                color: AppColors.hiveAccent,
              ),
            ),
            const SizedBox(width: 10),
            const Text('TaskHive'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => AuthService().signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(workspacesProvider.future),
        child: Container(
          decoration: AppColors.pageDecoration(context),
          child: Column(
            children: [
              FutureBuilder(
                future: Supabase.instance.client
                    .from('profiles')
                    .select()
                    .eq('id', user?.id ?? '')
                    .single(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox(height: 8);
                  final profile = Profile.fromMap(snapshot.data!);
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: _buildWelcomeCard(context, profile, colorScheme, isDark),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showJoinDialog(context, ref),
                        icon: const Icon(Icons.group_add_rounded, size: 18),
                        label: const Text('Join Hive'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _showCreateDialog(context, ref),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('New Hive'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: workspacesAsync.when(
                  data: (allWorkspaces) {
                    if (allWorkspaces.isEmpty) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: _buildEmptyState(context, colorScheme),
                        ),
                      );
                    }

                    final myHives = allWorkspaces
                        .where((h) => h.ownerId == user?.id)
                        .toList();
                    final joinedHives = allWorkspaces
                        .where((h) => h.ownerId != user?.id)
                        .toList();

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        if (myHives.isNotEmpty) ...[
                          _buildSectionHeader(context, 'My Hives', myHives.length),
                          ...myHives.map(
                            (hive) => _buildWorkspaceCard(
                              context,
                              hive,
                              colorScheme,
                              ref,
                              isDark: isDark,
                            ),
                          ),
                        ],
                        if (joinedHives.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildSectionHeader(
                            context,
                            'Joined Hives',
                            joinedHives.length,
                          ),
                          ...joinedHives.map(
                            (hive) => _buildWorkspaceCard(
                              context,
                              hive,
                              colorScheme,
                              ref,
                              isJoined: true,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(
    BuildContext context,
    Profile profile,
    ColorScheme color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.primary, width: 2),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: color.primaryContainer,
              foregroundImage:
                  (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
              child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                  ? Text(
                      profile.username[0].toUpperCase(),
                      style: TextStyle(
                        color: color.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                ),
                Text(
                  profile.username,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceCard(
    BuildContext context,
    Workspace hive,
    ColorScheme color,
    WidgetRef ref, {
    bool isJoined = false,
    required bool isDark,
  }) {
    final accent = isJoined ? AppColors.brandSecondary : AppColors.brandPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskBoardScreen(workspace: hive),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder(context)),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(14),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isJoined
                                      ? Icons.group_work_rounded
                                      : Icons.hive_rounded,
                                  color: accent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hive.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isJoined
                                          ? 'Team member'
                                          : 'Code: ${hive.inviteCode}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: color.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: color.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          FutureBuilder<double>(
                            future:
                                WorkspaceService().getWorkspaceProgress(hive.id),
                            builder: (context, snapshot) {
                              final progress = snapshot.data ?? 0.0;
                              final isComplete =
                                  progress == 1.0 && snapshot.hasData;

                              return Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Progress',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: color.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        '${(progress * 100).toInt()}%',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isComplete
                                              ? AppColors.success
                                              : accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 5,
                                      backgroundColor:
                                          color.surfaceContainerHighest,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isComplete
                                            ? AppColors.success
                                            : accent,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hive_rounded,
                size: 48,
                color: color.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Hives yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first workspace or join one with an invite code.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Hive'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Hive name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await WorkspaceService().createWorkspace(controller.text);
                  ref.invalidate(workspacesProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join a Hive'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter 6-digit invite code',
            prefixIcon: Icon(Icons.vpn_key_rounded),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await WorkspaceService().joinWorkspace(controller.text);
                ref.invalidate(workspacesProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Welcome to the Hive!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}
