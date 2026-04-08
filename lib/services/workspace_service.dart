import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkspaceService {
  final _supabase = Supabase.instance.client;

  // Generate a random 6-character invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  Future<void> createWorkspace(String name) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // 1. Insert the Workspace
    final workspaceData = await _supabase.from('workspaces').insert({
      'name': name,
      'owner_id': user.id,
      'invite_code': _generateInviteCode(),
    }).select().single();

    // 2. Add the creator to workspace_members as 'owner'
    await _supabase.from('workspace_members').insert({
      'workspace_id': workspaceData['id'],
      'user_id': user.id,
      'role': 'owner',
    });
  }
}