import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workspace_model.dart';
import '../../models/task_model.dart';
import '../../providers/workspace_provider.dart';
import '../../services/workspace_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../chat/chat_screen.dart';
import '../../theme/app_colors.dart';

class _ColumnConfig {
  final String status;
  final String label;
  final IconData icon;
  final Color Function(ColorScheme) accentColor;

  const _ColumnConfig({
    required this.status,
    required this.label,
    required this.icon,
    required this.accentColor,
  });
}

class TaskBoardScreen extends ConsumerStatefulWidget {
  final Workspace workspace;

  const TaskBoardScreen({super.key, required this.workspace});

  @override
  ConsumerState<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends ConsumerState<TaskBoardScreen> {
  static const _columns = [
    _ColumnConfig(
      status: 'todo',
      label: 'To Do',
      icon: Icons.radio_button_unchecked_rounded,
      accentColor: _todoAccent,
    ),
    _ColumnConfig(
      status: 'in_progress',
      label: 'In Progress',
      icon: Icons.timelapse_rounded,
      accentColor: _inProgressAccent,
    ),
    _ColumnConfig(
      status: 'done',
      label: 'Done',
      icon: Icons.check_circle_outline_rounded,
      accentColor: _doneAccent,
    ),
  ];

  static Color _todoAccent(ColorScheme s) => const Color(0xFF5B8DEF);
  static Color _inProgressAccent(ColorScheme s) => const Color(0xFFF59E0B);
  static Color _doneAccent(ColorScheme s) => const Color(0xFF22C55E);

  String? _draggingTaskId;

  static String _deadlineText(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  static bool _isOverdue(Task task) {
    if (task.deadline == null || task.status == 'done') return false;
    final endOfDeadlineDay = DateTime(
      task.deadline!.year,
      task.deadline!.month,
      task.deadline!.day,
      23,
      59,
      59,
    );
    return DateTime.now().isAfter(endOfDeadlineDay);
  }

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
    if (diff < -1) return '${-diff}d overdue';
    return null;
  }

  static String _assigneeInitial(String? name) {
    final t = name?.trim() ?? '';
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }

  Future<void> _moveTask(String taskId, String newStatus) async {
    try {
      await HapticFeedback.mediumImpact();
      await WorkspaceService().updateTaskStatus(taskId, newStatus);
      ref.invalidate(hiveTasksProvider(widget.workspace.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not move task: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasksAsync = ref.watch(hiveTasksProvider(widget.workspace.id));

    return tasksAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(widget.workspace.name)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(widget.workspace.name)),
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
        final doneCount = tasks.where((t) => t.status == 'done').length;
        final progress = tasks.isEmpty ? 0.0 : doneCount / tasks.length;

        return Scaffold(
          backgroundColor: AppColors.pageBackground(context),
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.workspace.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${tasks.length} tasks · ${(progress * 100).round()}% complete',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: () =>
                    ref.invalidate(hiveTasksProvider(widget.workspace.id)),
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: 'Hive Chat',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => ChatScreen(
                        workspaceId: widget.workspace.id,
                        workspaceName: widget.workspace.name,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.forum_rounded),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildProgressBar(context, progress, doneCount, tasks.length),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(hiveTasksProvider(widget.workspace.id));
                    await ref.read(hiveTasksProvider(widget.workspace.id).future);
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columnWidth = (constraints.maxWidth / 3)
                          .clamp(260.0, 340.0);
                      return ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                        children: _columns.map((col) {
                          final columnTasks = tasks
                              .where((t) => t.status == col.status)
                              .toList();
                          return _buildKanbanColumn(
                            context,
                            col,
                            columnTasks,
                            tasks,
                            columnWidth,
                            colorScheme,
                            isDark,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'task_board_new_task',
            onPressed: () => _showAddTaskDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Task'),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    double progress,
    int done,
    int total,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : progress,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: _doneAccent(colorScheme),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$done of $total completed',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn(
    BuildContext context,
    _ColumnConfig config,
    List<Task> tasks,
    List<Task> allTasks,
    double width,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final accent = config.accentColor(colorScheme);
    final isHoverTarget = _draggingTaskId != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        width: width,
        child: DragTarget<String>(
          onWillAcceptWithDetails: (details) {
            final dragged = allTasks.cast<Task?>().firstWhere(
                  (t) => t?.id == details.data,
                  orElse: () => null,
                );
            return dragged != null && dragged.status != config.status;
          },
          onAcceptWithDetails: (details) async {
            setState(() => _draggingTaskId = null);
            await _moveTask(details.data, config.status);
          },
          builder: (context, candidateData, rejectedData) {
            final isActive = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isActive
                    ? accent.withValues(alpha: isDark ? 0.18 : 0.1)
                    : AppColors.cardBackground(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? accent
                      : colorScheme.outlineVariant.withValues(alpha: 0.6),
                  width: isActive ? 2 : 1,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildColumnHeader(context, config, tasks.length, accent),
                  Expanded(
                    child: tasks.isEmpty
                        ? _buildEmptyColumn(context, config, accent, isHoverTarget)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildDraggableCard(
                                  context,
                                  tasks[index],
                                  accent,
                                  colorScheme,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildColumnHeader(
    BuildContext context,
    _ColumnConfig config,
    int count,
    Color accent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Icon(config.icon, size: 18, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              config.label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Add to ${config.label}',
            onPressed: () => _showAddTaskDialog(context, defaultStatus: config.status),
            icon: Icon(Icons.add_rounded, size: 20, color: accent),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyColumn(
    BuildContext context,
    _ColumnConfig config,
    Color accent,
    bool isDragging,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDragging ? Icons.download_rounded : Icons.inbox_outlined,
              size: 36,
              color: isDragging
                  ? accent
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 10),
            Text(
              isDragging ? 'Drop here' : 'No tasks yet',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableCard(
    BuildContext context,
    Task task,
    Color columnAccent,
    ColorScheme colorScheme,
  ) {
    final taskId = task.id;
    if (taskId == null || taskId.isEmpty) {
      return _buildTaskCard(context, task, columnAccent, colorScheme);
    }

    return LongPressDraggable<String>(
      data: taskId,
      delay: const Duration(milliseconds: 150),
      onDragStarted: () => setState(() => _draggingTaskId = taskId),
      onDragEnd: (_) => setState(() => _draggingTaskId = null),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        shadowColor: Colors.black45,
        child: SizedBox(
          width: 240,
          child: Opacity(
            opacity: 0.95,
            child: _buildTaskCard(
              context,
              task,
              columnAccent,
              colorScheme,
              isDragging: true,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _buildTaskCard(context, task, columnAccent, colorScheme),
      ),
      child: _buildTaskCard(context, task, columnAccent, colorScheme),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    Task task,
    Color columnAccent,
    ColorScheme colorScheme, {
    bool isDragging = false,
  }) {
    final overdue = _isOverdue(task);
    final isDone = task.status == 'done';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDragging ? null : () => _showTaskDetail(context, task),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDragging
                  ? columnAccent
                  : colorScheme.outlineVariant.withValues(alpha: 0.7),
              width: isDragging ? 1.5 : 1,
            ),
            boxShadow: isDragging
                ? [
                    BoxShadow(
                      color: columnAccent.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _priorityDot(task.priority, colorScheme),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                    ),
                  ),
                  if (!isDragging)
                    Icon(
                      Icons.drag_indicator_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                ],
              ),
              if (task.description != null &&
                  task.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildPriorityChip(context, task.priority, colorScheme),
                  const Spacer(),
                  if (task.deadline != null)
                    _buildDueDateBadge(context, task, overdue, colorScheme),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: columnAccent.withValues(alpha: 0.2),
                    child: Text(
                      _assigneeInitial(task.assigneeName),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: columnAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task.assigneeName ?? 'Unassigned',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityDot(String priority, ColorScheme colorScheme) {
    Color color;
    switch (priority) {
      case 'high':
        color = colorScheme.error;
      case 'medium':
        color = const Color(0xFFF59E0B);
      default:
        color = colorScheme.primary;
    }
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
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
      case 'medium':
        fg = const Color(0xFFF59E0B);
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
      default:
        fg = colorScheme.primary;
        bg = colorScheme.primaryContainer.withValues(alpha: 0.45);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDueDateBadge(
    BuildContext context,
    Task task,
    bool overdue,
    ColorScheme colorScheme,
  ) {
    final relative = _relativeDueHint(task);
    final color = overdue ? colorScheme.error : colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: overdue
            ? colorScheme.errorContainer.withValues(alpha: 0.4)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            overdue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            relative ?? _deadlineText(task.deadline!),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDetail(BuildContext context, Task task) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  task.title,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (task.description != null &&
                    task.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    task.description!,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPriorityChip(ctx, task.priority, colorScheme),
                    if (task.deadline != null)
                      _buildDueDateBadge(
                        ctx,
                        task,
                        _isOverdue(task),
                        colorScheme,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Move to',
                  style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: _columns.map((col) {
                    final isCurrent = task.status == col.status;
                    final accent = col.accentColor(colorScheme);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilledButton.tonal(
                          onPressed: isCurrent || task.id == null
                              ? null
                              : () async {
                                  Navigator.pop(ctx);
                                  await _moveTask(task.id!, col.status);
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: isCurrent
                                ? accent.withValues(alpha: 0.25)
                                : null,
                            foregroundColor: accent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            col.label,
                            style: const TextStyle(fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(
    BuildContext context, {
    String defaultStatus = 'todo',
  }) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'medium';
    DateTime? selectedDate;
    String? selectedAssigneeId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final membersAsync =
              ref.watch(hiveMembersProvider(widget.workspace.id));
          final colorScheme = Theme.of(context).colorScheme;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.add_task_rounded, color: colorScheme.primary),
                const SizedBox(width: 10),
                const Text('New Task'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'What needs to be done?',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Add details...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  membersAsync.when(
                    data: (members) {
                      return DropdownButtonFormField<String>(
                        value: selectedAssigneeId,
                        decoration:
                            const InputDecoration(labelText: 'Assign To'),
                        items: members.map((m) {
                          final dynamic profileData = m['profiles'];
                          final Map<String, dynamic> profile =
                              (profileData is Map)
                                  ? Map<String, dynamic>.from(profileData)
                                  : {};
                          final String memberId =
                              profile['id']?.toString() ??
                                  m['user_id'].toString();
                          final String memberName =
                              (profile['username'] != null &&
                                      profile['username']
                                          .toString()
                                          .isNotEmpty)
                                  ? profile['username'].toString()
                                  : 'Team Member';
                          return DropdownMenuItem<String>(
                            value: memberId,
                            child: Text(memberName),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedAssigneeId = val),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (err, _) => Text('Error: $err'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: ['low', 'medium', 'high']
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedPriority = val!),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.calendar_month, color: colorScheme.primary),
                    title: Text(
                      selectedDate == null
                          ? 'Set Deadline'
                          : 'Due: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                    ),
                    trailing: selectedDate != null
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () =>
                                setDialogState(() => selectedDate = null),
                          )
                        : null,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setDialogState(() => selectedDate = date);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (titleController.text.isEmpty || user == null) return;
                  try {
                    final newTask = Task(
                      workspaceId: widget.workspace.id,
                      creatorId: user.id,
                      assignedTo: selectedAssigneeId,
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      status: defaultStatus,
                      priority: selectedPriority,
                      deadline: selectedDate,
                    );
                    await WorkspaceService().createTask(newTask);
                    ref.invalidate(hiveTasksProvider(widget.workspace.id));
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    debugPrint('Error: $e');
                  }
                },
                child: const Text('Create Task'),
              ),
            ],
          );
        },
      ),
    );
  }
}
