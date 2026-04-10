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
    // 1. Trim and uppercase to match database
    final cleanCode = inviteCode.trim().toUpperCase();
    
    // 2. Call the RPC
    await _supabase.rpc(
      'join_hive_by_code',
      params: {'hex_code': cleanCode},
    );
    
    // 3. FORCE a refresh of the dashboard
    // Note: We will do this in the UI after calling this method
  } catch (e) {
    print('Join Error: $e');
    throw 'Invalid code or already a member';
  }
}

  // --- 3. CREATE TASK ---
  Future<void> createTask(Task task) async {
    // We convert the Task model to a Map to send to Supabase
    await _supabase.from('tasks').insert(task.toMap());
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
    await _supabase
        .from('tasks')
        .update({'status': newStatus})
        .eq('id', taskId);
  }
}