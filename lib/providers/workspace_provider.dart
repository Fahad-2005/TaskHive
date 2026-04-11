import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workspace_model.dart';
import '../services/workspace_service.dart';
import '../models/task_model.dart';

// This provider fetches the list of workspaces
// Change from StreamProvider to FutureProvider
final workspacesProvider = FutureProvider<List<Workspace>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  // Get IDs from the members table
  final memberRows = await Supabase.instance.client
      .from('workspace_members')
      .select('workspace_id')
      .eq('user_id', user.id);

  final List<String> joinedIds = (memberRows as List)
      .map((row) => row['workspace_id'].toString())
      .toList();

  if (joinedIds.isEmpty) return [];

  // Fetch the actual Hives
  final response = await Supabase.instance.client
      .from('workspaces')
      .select()
      .inFilter('id', joinedIds);
      
  return (response as List).map((map) => Workspace.fromMap(map)).toList();
});

// Fetches the profiles of everyone in this specific Hive
final hiveMembersProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, workspaceId) async {
  final response = await Supabase.instance.client
      .from('workspace_members')
      .select('''
        user_id,
        profiles (
          username
        )
      ''') // No "!inner" here!
      .eq('workspace_id', workspaceId);
      
  return List<Map<String, dynamic>>.from(response);
});
// In workspace_provider.dart
final hiveTasksProvider = FutureProvider.family<List<Task>, String>((ref, workspaceId) async {
  final response = await Supabase.instance.client
      .from('tasks')
      .select('''
        *,
        assignee:profiles!assigned_to(username)
      ''')
      .eq('workspace_id', workspaceId)
      .order('created_at');

  final List data = response as List;
  // Change from .fromJson to .fromMap here:
  return data.map((taskMap) => Task.fromMap(taskMap)).toList();
});
// This provider keeps track of which Workspace is currently selected
final selectedWorkspaceProvider = StateProvider<Workspace?>((ref) => null);