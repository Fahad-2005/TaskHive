import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart'; 

class WorkspaceService {
  final _supabase = Supabase.instance.client;

  // --- HELPER: Generate a random 6-character invite code ---
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed 0, 1, O, I to avoid confusion
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  // --- 1. CREATE WORKSPACE ---
  Future<void> createWorkspace(String name) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'User not authenticated';

    // Insert the Workspace
    final workspaceData = await _supabase.from('workspaces').insert({
      'name': name,
      'owner_id': user.id,
      'invite_code': _generateInviteCode(),
    }).select().single();

    // Add the creator to workspace_members as 'owner'
    await _supabase.from('workspace_members').insert({
      'workspace_id': workspaceData['id'],
      'user_id': user.id,
      'role': 'owner',
    });
  }

  // --- 2. JOIN WORKSPACE ---
  Future<void> joinWorkspace(String inviteCode) async {
  try {
    final cleanCode = inviteCode.trim().toUpperCase();

    // Call our fixed function
    final response = await _supabase.rpc(
      'join_hive_by_code',
      params: {'hex_code': cleanCode},
    );

    // The function returns a list because it's a 'RETURNS TABLE'
    if (response != null && response is List && response.isNotEmpty) {
      final result = response[0];
      if (result['success'] == false) {
        // This catches 'Invalid Invite Code'
        throw result['message'];
      }
    }
    
    // Success! The database row is created.
  } catch (e) {
    // If they are already a member, ON CONFLICT DO NOTHING happens, 
    // but if you want to show a specific error, handle it here.
    rethrow;
  }
}

  // --- 3. CREATE TASK ---
  Future<void> createTask(Task task) async {
    await _supabase.from('tasks').insert(task.toMap());
await _logActivity(task.workspaceId, "created task", task.title);
    // We convert the Task model to a Map to send to Supabase
  }

  // --- 4. FETCH TASKS ---
  Future<List<Task>> getTasks(String workspaceId) async {
    final response = await _supabase
        .from('tasks')
        .select()
        .eq('workspace_id', workspaceId)
        .order('created_at', ascending: false);
    
    return (response as List).map((task) => Task.fromMap(task)).toList();
  }

  // --- 5. UPDATE TASK STATUS (For Kanban Drag & Drop) ---
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
  try {
    // 1. Fetch task details first to get the Title and Workspace ID for the log
    final taskData = await _supabase
        .from('tasks')
        .select('title, workspace_id')
        .eq('id', taskId)
        .single();

    final String taskTitle = taskData['title'];
    final String workspaceId = taskData['workspace_id'];

    // 2. Perform the update
    await _supabase
        .from('tasks')
        .update({'status': newStatus})
        .eq('id', taskId);

    // 3. Log the activity using the data we just fetched
    await _logActivity(workspaceId, "moved to ${_statusLabel(newStatus)}", taskTitle);

  } catch (e) {
    throw Exception('Could not update task status: $e');
  }
}

// Helper to make the status look nice in the activity feed (To Do instead of todo)
String _statusLabel(String status) {
  return status.replaceAll('_', ' ').split(' ').map((str) => 
    str[0].toUpperCase() + str.substring(1)).join(' ');
}

  Future<List<Task>> getMyPersonalTasks(String userId) async {
  final response = await _supabase
      .from('tasks')
      .select()
      .eq('assigned_to', userId)
      .order('deadline', ascending: true);

  return (response as List).map((t) => Task.fromMap(t)).toList();
}

Future<double> getWorkspaceProgress(String workspaceId) async {
  final response = await _supabase
      .from('tasks')
      .select('status')
      .eq('workspace_id', workspaceId);

  final List tasks = response as List;
  if (tasks.isEmpty) return 0.0;

  final doneTasks = tasks.where((t) => t['status'] == 'done').length;
  return doneTasks / tasks.length;
}

Future<void> _logActivity(String workspaceId, String action, String target) async {
  final userId = _supabase.auth.currentUser!.id;
  await _supabase.from('activities').insert({
    'workspace_id': workspaceId,
    'user_id': userId,
    'action_text': action,
    'target_name': target,
  });
}

}