import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/task_model.dart';
import '../../services/workspace_service.dart';
import 'package:intl/intl.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.4),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<Task>>(
            future: WorkspaceService().getMyPersonalTasks(user!.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allTasks = snapshot.data ?? [];
              final pendingTasks = allTasks.where((t) => t.status != 'done').toList();
              final doneTasksCount = allTasks.where((t) => t.status == 'done').length;
              
              // Sort pending by priority and deadline
              pendingTasks.sort((a, b) {
                if (a.priority == 'high' && b.priority != 'high') return -1;
                return 0;
              });

              return CustomScrollView(
                slivers: [
                  // 1. STYLISH HEADER
                  SliverToBoxAdapter(
                    child: _buildEnhancedHeader(context, allTasks.length, doneTasksCount),
                  ),

                  // 2. TASK LIST
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: pendingTasks.isEmpty
                        ? const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: Text("All tasks cleared! 🎯")),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _EnhancedTaskTile(task: pendingTasks[index]),
                              childCount: pendingTasks.length,
                            ),
                          ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader(BuildContext context, int total, int done) {
    final colorScheme = Theme.of(context).colorScheme;
    double progress = total > 0 ? (done / total) : 0;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "My Focus",
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: colorScheme.surfaceVariant,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Progress",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "$done of $total tasks completed",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedTaskTile extends StatelessWidget {
  final Task task;
  const _EnhancedTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isHigh = task.priority == 'high';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHigh ? colorScheme.error.withOpacity(0.3) : colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getPriorityColor(task.priority, colorScheme),
          ),
        ),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.calendar_today, size: 12, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              task.deadline != null 
                  ? DateFormat('MMM dd').format(task.deadline!.toLocal()) 
                  : 'No deadline',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: colorScheme.outline),
      ),
    );
  }

  Color _getPriorityColor(String? priority, ColorScheme scheme) {
    if (priority == 'high') return scheme.error;
    if (priority == 'medium') return scheme.tertiary;
    return scheme.primary;
  }
}