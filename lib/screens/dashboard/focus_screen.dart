import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/task_model.dart';
import '../../services/workspace_service.dart';
import 'package:intl/intl.dart';
import '../chat/chat_screen.dart';

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

    // 2. TASK LIST SECTION HEADER
    const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Text(
          "My Assignments",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    ),

    // 3. THE TASK TILES
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: pendingTasks.isEmpty
          ? const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text("All tasks cleared! 🎯"),
                ),
              ),
            )
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _EnhancedTaskTile(task: pendingTasks[index]),
                childCount: pendingTasks.length,
              ),
            ),
    ),

    // 🚀 4. THE LIVE ACTIVITY FEED (The Missing Part!)
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: _buildActivityFeed(user.id), // We call your function here
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
  Widget _buildActivityFeed(String workspaceId) {
  final client = Supabase.instance.client;

  return StreamBuilder<List<Map<String, dynamic>>>(
    stream: client
    .from('activities')
    .stream(primaryKey: ['id']) // 👈 This is the "hook" that listens for changes
    .order('created_at', ascending: false)
    .limit(10),// Only show last 10 actions
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox();

      final activities = snapshot.data!;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text("Latest Activity", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final act = activities[index];
              return ListTile(
  leading: ChatAvatar(userId: act['user_id']),
  title: FutureBuilder(
    // Fetch the username for the activity text
    future: Supabase.instance.client.from('profiles').select('username').eq('id', act['user_id']).single(),
    builder: (context, snapshot) {
      final username = snapshot.data?['username'] ?? 'Someone';
      return RichText(
        text: TextSpan(
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
          children: [
            TextSpan(text: username, style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: " ${act['action_text']} "),
            TextSpan(
              text: act['target_name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    },
  ),
  subtitle: Text(
    DateFormat('hh:mm a').format(DateTime.parse(act['created_at']).toLocal()),
    style: const TextStyle(fontSize: 10),
  ),
);
            },
          ),
        ],
      );
    },
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