import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workspace_model.dart';
import '../../models/task_model.dart';
import '../../providers/workspace_provider.dart';
import '../../services/workspace_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskBoardScreen extends ConsumerWidget {
  final Workspace workspace;

  const TaskBoardScreen({super.key, required this.workspace});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(hiveTasksProvider(workspace.id));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(workspace.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'To Do'),
              Tab(text: 'In Progress'),
              Tab(text: 'Done'),
            ],
          ),
        ),
        body: tasksAsync.when(
          data: (tasks) => TabBarView(
            children: [
              _buildTaskColumn(tasks, 'todo', ref),
              _buildTaskColumn(tasks, 'in_progress', ref),
              _buildTaskColumn(tasks, 'done', ref),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddTaskDialog(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTaskColumn(List<Task> allTasks, String status, WidgetRef ref) {
    final filteredTasks = allTasks.where((t) => t.status == status).toList();

    if (filteredTasks.isEmpty) {
      return Center(
        child: Text('No tasks in ${status.replaceAll('_', ' ')}', 
        style: const TextStyle(color: Colors.grey))
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description != null && task.description!.isNotEmpty)
                  Text(task.description!),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildPriorityBadge(task.priority),
                    const SizedBox(width: 8),
                    if (task.deadline != null)
                      Text(
                        'Due: ${task.deadline!.day}/${task.deadline!.month}',
                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                  ],
                ),
              ],
            ),
            trailing: _buildStatusPicker(task, ref),
          ),
        );
      },
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority) {
      case 'high': color = Colors.red; break;
      case 'medium': color = Colors.orange; break;
      default: color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(priority.toUpperCase(), 
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusPicker(Task task, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (newStatus) async {
        await WorkspaceService().updateTaskStatus(task.id!, newStatus);
        ref.invalidate(hiveTasksProvider(workspace.id));
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'todo', child: Text('To Do')),
        const PopupMenuItem(value: 'in_progress', child: Text('In Progress')),
        const PopupMenuItem(value: 'done', child: Text('Done')),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'medium';
    DateTime? selectedDate;
    String? selectedAssigneeId;

    // We watch the members here so the dropdown can use them
    final membersAsync = ref.watch(hiveMembersProvider(workspace.id));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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

                // 1. Assignee Dropdown (Dynamic from Hive members)
                membersAsync.when(
                  data: (members) => DropdownButtonFormField<String>(
                    value: selectedAssigneeId,
                    decoration: const InputDecoration(labelText: 'Assign To'),
                    items: members.map((m) {
                      final profile = m['profiles'] as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: profile['id'].toString(),
                        child: Text(profile['username'].toString()),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedAssigneeId = val),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Error loading members'),
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
                  // Show loading overlay
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

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
                    
                    if (context.mounted) {
                      Navigator.pop(context); // Pop Loader
                      Navigator.pop(context); // Pop Dialog
                    }
                  } catch (e) {
                    if (context.mounted) Navigator.pop(context); // Pop Loader
                    debugPrint('Error: $e');
                  }
                }
              },
              child: const Text('Add to Hive'),
            ),
          ],
        ),
      ),
    );
  }
}