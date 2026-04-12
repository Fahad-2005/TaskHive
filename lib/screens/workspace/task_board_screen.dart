import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workspace_model.dart';
import '../../models/task_model.dart';
import '../../providers/workspace_provider.dart';
import '../../services/workspace_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../chat/chat_screen.dart';

class TaskBoardScreen extends ConsumerWidget {
  final Workspace workspace;

  const TaskBoardScreen({super.key, required this.workspace});

  static String _statusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'done':
        return 'Done';
      default:
        return 'To Do';
    }
  }

  static String _deadlineText(DateTime d) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static bool _isOverdue(Task task) {
    if (task.deadline == null || task.status == 'done') return false;
    final now = DateTime.now();
    final endOfDeadlineDay = DateTime(
      task.deadline!.year,
      task.deadline!.month,
      task.deadline!.day,
      23,
      59,
      59,
    );
    return now.isAfter(endOfDeadlineDay);
  }

  /// Short relative hint for mobile (e.g. "Today", "In 2 days").
  static String? _relativeDueHint(Task task) {
    if (task.deadline == null) return null;
    final d = DateTime(
      task.deadline!.year,
      task.deadline!.month,
      task.deadline!.day,
    );
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);
    final diff = d.difference(t0).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1) return 'In $diff days';
    if (diff < -1) return '${-diff} days ago';
    return null;
  }

  static String _assigneeInitial(String? name) {
    final t = name?.trim() ?? '';
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final tasksAsync = ref.watch(hiveTasksProvider(workspace.id));

    return tasksAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(workspace.name)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error:
          (e, _) => Scaffold(
            appBar: AppBar(title: Text(workspace.name)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error: $e',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ),
          ),
      data: (tasks) {
        final todoCount = tasks.where((t) => t.status == 'todo').length;
        final inProgressCount =
            tasks.where((t) => t.status == 'in_progress').length;
        final doneCount = tasks.where((t) => t.status == 'done').length;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(workspace.name),
              bottom: TabBar(
                indicatorColor: colorScheme.primary,
                indicatorWeight: 3,
                isScrollable: true,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                tabs: [
                  Tab(text: 'To Do ($todoCount)'),
                  Tab(text: 'In progress ($inProgressCount)'),
                  Tab(text: 'Done ($doneCount)'),
                ],
              ),
            ),
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
              child: TabBarView(
                children: [
                  _buildTaskColumn(
                    context,
                    tasks,
                    'todo',
                    ref,
                    colorScheme,
                  ),
                  _buildTaskColumn(
                    context,
                    tasks,
                    'in_progress',
                    ref,
                    colorScheme,
                  ),
                  _buildTaskColumn(
                    context,
                    tasks,
                    'done',
                    ref,
                    colorScheme,
                  ),
                ],
              ),
            ),
           floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 💬 HIVE CHAT (Secondary/Tertiary Style)
                  // Using a smaller, distinct style to differentiate from task creation
                  FloatingActionButton.small(
                    heroTag: 'chat_fab', // Unique tag to prevent crashes
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => ChatScreen(
                            workspaceId: workspace.id,
                            workspaceName: workspace.name,
                          ),
                        ),
                      );
                    },
                    backgroundColor: colorScheme.tertiaryContainer,
                    foregroundColor: colorScheme.onTertiaryContainer,
                    child: const Icon(Icons.forum_rounded, size: 20),
                  ),
                  
                  const SizedBox(height: 12),

                  // ➕ NEW TASK (Primary Action)
                  // This remains the main focus of the screen
                  FloatingActionButton.extended(
                    heroTag: 'task_board_new_task',
                    onPressed: () => _showAddTaskDialog(context, ref),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('New task'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskColumn(
    BuildContext context,
    List<Task> allTasks,
    String status,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    final filteredTasks = allTasks.where((t) => t.status == status).toList();
    final label = _statusLabel(status);

    Future<void> onRefresh() async {
      ref.invalidate(hiveTasksProvider(workspace.id));
      await ref.read(hiveTasksProvider(workspace.id).future);
    }

    if (filteredTasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 56,
                    color: colorScheme.primary.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks in $label',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap New task to add one, or pull down to refresh.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$label · ${filteredTasks.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final task = filteredTasks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTaskCard(
                    context,
                    task,
                    ref,
                    colorScheme,
                  ),
                );
              },
              childCount: filteredTasks.length,
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    Task task,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    final overdue = _isOverdue(task);
    final isDone = task.status == 'done';

    return Opacity(
      opacity: isDone ? 0.88 : 1,
      child: Material(
        color: Colors.transparent,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _priorityStripeColor(task.priority, colorScheme),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      if (task.description != null &&
                          task.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          task.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildPriorityChip(
                            context,
                            task.priority,
                            colorScheme,
                          ),
                          _buildDeadlineChip(
                            context,
                            task,
                            colorScheme,
                            overdue,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 11,
                                backgroundColor:
                                    colorScheme.secondaryContainer,
                                child: Text(
                                  _assigneeInitial(task.assigneeName),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 120),
                                child: Text(
                                  task.assigneeName ?? 'Unassigned',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusPicker(context, task, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _priorityStripeColor(String priority, ColorScheme colorScheme) {
    switch (priority) {
      case 'high':
        return colorScheme.error;
      case 'medium':
        return colorScheme.tertiary;
      default:
        return colorScheme.primary;
    }
  }

  Widget _buildPriorityChip(
    BuildContext context,
    String priority,
    ColorScheme colorScheme,
  ) {
    Color fg;
    Color bg;
    switch (priority) {
      case 'high':
        fg = colorScheme.error;
        bg = colorScheme.errorContainer.withValues(alpha: 0.5);
        break;
      case 'medium':
        fg = colorScheme.tertiary;
        bg = colorScheme.tertiaryContainer.withValues(alpha: 0.55);
        break;
      default:
        fg = colorScheme.primary;
        bg = colorScheme.primaryContainer.withValues(alpha: 0.55);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildDeadlineChip(
    BuildContext context,
    Task task,
    ColorScheme colorScheme,
    bool overdue,
  ) {
    final hasDeadline = task.deadline != null;
    final relative = _relativeDueHint(task);
    final iconColor = overdue
        ? colorScheme.error
        : hasDeadline
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant;
    final textColor = overdue ? colorScheme.error : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: overdue
            ? colorScheme.errorContainer.withValues(alpha: 0.45)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: overdue
              ? colorScheme.error.withValues(alpha: 0.45)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_rounded, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(
                hasDeadline
                    ? _deadlineText(task.deadline!)
                    : 'No deadline',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (overdue) ...[
                const SizedBox(width: 4),
                Text(
                  '· Overdue',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ],
          ),
          if (relative != null && hasDeadline) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Text(
                relative,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusPicker(
    BuildContext context,
    Task task,
    WidgetRef ref,
  ) {
    return PopupMenuButton<String>(
      tooltip: 'Move task',
      onSelected: (newStatus) async {
        if (newStatus == task.status) return;

        final id = task.id;
        if (id == null || id.isEmpty) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This task has no id yet — pull to refresh.'),
            ),
          );
          return;
        }

        try {
          await HapticFeedback.selectionClick();
          await WorkspaceService().updateTaskStatus(id, newStatus);
          ref.invalidate(hiveTasksProvider(workspace.id));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Moved to ${_statusLabel(newStatus)}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not update status: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'todo',
          enabled: task.status != 'todo',
          child: const Text('To Do'),
        ),
        PopupMenuItem(
          value: 'in_progress',
          enabled: task.status != 'in_progress',
          child: const Text('In Progress'),
        ),
        PopupMenuItem(
          value: 'done',
          enabled: task.status != 'done',
          child: const Text('Done'),
        ),
      ],
      icon: const Icon(Icons.more_vert_rounded),
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'medium';
    DateTime? selectedDate;
    String? selectedAssigneeId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Watch members inside the builder to ensure it updates
          final membersAsync = ref.watch(hiveMembersProvider(workspace.id));

          return AlertDialog(
            title: const Text('New Hive Task'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Task Title'),
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 15),

                  // --- SAFE ASSIGNEE DROPDOWN ---
                  membersAsync.when(
                    data: (members) {
                      return DropdownButtonFormField<String>(
                        value: selectedAssigneeId,
                        decoration: const InputDecoration(labelText: 'Assign To'),
                        items: members.map((m) {
  // 1. Get the profile data
  final dynamic profileData = m['profiles'];
  
  // 2. Convert to Map safely
  final Map<String, dynamic> profile = (profileData is Map) 
      ? Map<String, dynamic>.from(profileData) 
      : {};

  // 3. Get the ID
  final String memberId = profile['id']?.toString() ?? m['user_id'].toString();
  
  // 4. CHANGE THIS LINE: This is where we decide what name to show
  // If 'username' is null, it will now show 'Team Member' instead of the long UUID
  final String memberName = (profile['username'] != null && profile['username'].toString().isNotEmpty)
      ? profile['username'].toString()
      : 'Team Member'; 

  return DropdownMenuItem<String>(
    value: memberId,
    child: Text(memberName),
  );
}).toList(),
                        onChanged: (val) => setDialogState(() => selectedAssigneeId = val),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (err, _) => Text('Error: $err'),
                  ),

                  const SizedBox(height: 10),

                  // 2. Priority Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: ['low', 'medium', 'high'].map((p) => 
                      DropdownMenuItem(value: p, child: Text(p.toUpperCase()))
                    ).toList(),
                    onChanged: (val) => setDialogState(() => selectedPriority = val!),
                  ),

                  // 3. Deadline Picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(selectedDate == null 
                      ? 'Set Deadline' 
                      : 'Due: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setDialogState(() => selectedDate = date);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (titleController.text.isNotEmpty && user != null) {
                    try {
                      final newTask = Task(
                        workspaceId: workspace.id,
                        creatorId: user.id,
                        assignedTo: selectedAssigneeId,
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        status: 'todo',
                        priority: selectedPriority,
                        deadline: selectedDate,
                      );

                      await WorkspaceService().createTask(newTask);
                      ref.invalidate(hiveTasksProvider(workspace.id));
                      
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      debugPrint('Error: $e');
                    }
                  }
                },
                child: const Text('Add to Hive'),
              ),
            ],
          );
        },
      ),
    );
  }
}
