import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workspace_model.dart';

// This provider fetches the list of workspaces
final workspacesProvider = StreamProvider<List<Workspace>>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  
  return Supabase.instance.client
      .from('workspaces')
      .stream(primaryKey: ['id'])
      .order('name')
      .map((data) => data.map((map) => Workspace.fromMap(map)).toList());
});

// This provider keeps track of which Workspace is currently selected
final selectedWorkspaceProvider = StateProvider<Workspace?>((ref) => null);