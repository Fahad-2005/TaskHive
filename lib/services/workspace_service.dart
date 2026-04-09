import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart'; // Make sure this path is correct

class WorkspaceService {
  final _supabase = Supabase.instance.client;

  // --- HELPER: Generate a random 6-character invite code ---
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  // --- 1. CREATE: Create a new Hive and set user as Owner ---
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

  // --- 2. JOIN: Join an existing Hive using an Invite Code ---
  Future<void> joinWorkspace(String inviteCode) async {
  final user = _supabase.auth.currentUser;
  if (user == null) throw 'User not authenticated';

  // .trim() removes accidental spaces at start/end
  // .toUpperCase() ensures 'abc123' matches 'ABC123'
  final cleanCode = inviteCode.trim().toUpperCase();

  // 1. Find the workspace
  final workspaceData = await _supabase
      .from('workspaces')
      .select('id')
      .eq('invite_code', cleanCode) 
      .maybeSingle();

  if (workspaceData == null) {
    // This is where your error is currently triggering
    throw 'Invalid Invite Code. Please check and try again.';
  }

  final String workspaceId = workspaceData['id'];

  // 2. Add the member
  await _supabase.from('workspace_members').upsert({
    'workspace_id': workspaceId,
    'user_id': user.id,
    'role': 'member',
  });
}

  // --- 3. FETCH TASKS: Get all tasks for a specific Hive ---
  Future<List<Task>> getTasks(String workspaceId) async {
    final response = await _supabase
        .from('tasks')
        .select()
        .eq('workspace_id', workspaceId)
        .order('created_at', ascending: false);
    
    return (response as List).map((task) => Task.fromMap(task)).toList();
  }
}