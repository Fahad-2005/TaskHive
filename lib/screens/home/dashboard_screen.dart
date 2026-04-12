import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/workspace_provider.dart';
import '../../models/profile_model.dart';
import '../../models/workspace_model.dart'; 
import '../../services/auth_service.dart';
import '../../services/workspace_service.dart';
import '../workspace/task_board_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Watches the provider that filters by your real database memberships
    final workspacesAsync = ref.watch(workspacesProvider);
    final user = Supabase.instance.client.auth.currentUser;
    

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskHive'),
        actions: [
          IconButton(
            onPressed: () => AuthService().signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        // Allows you to pull down to refresh the Hive list
        onRefresh: () => ref.refresh(workspacesProvider.future),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primary.withOpacity(0.08),
                colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            children: [
              // 1. Profile Summary Section
              FutureBuilder(
                future: Supabase.instance.client
                    .from('profiles')
                    .select()
                    .eq('id', user?.id ?? '')
                    .single(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox(height: 80);
                  final profile = Profile.fromMap(snapshot.data!);
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildProfileHeader(context, profile, colorScheme),
                  );
                },
              ),

              // 2. The Hive List Section
              Expanded(
                child: workspacesAsync.when(
                  data: (allWorkspaces) {
                    if (allWorkspaces.isEmpty) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: _buildEmptyState(context, colorScheme),
                        ),
                      );
                    }

                    // Separation logic: Owner vs Member
                    final myHives = allWorkspaces
                        .where((h) => h.ownerId == user?.id)
                        .toList();
                    final joinedHives = allWorkspaces
                        .where((h) => h.ownerId != user?.id)
                        .toList();

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        if (myHives.isNotEmpty) ...[
                          _buildSectionHeader('My Hives'),
                          ...myHives.map((hive) =>
                              _buildWorkspaceCard(context, hive, colorScheme, ref)),
                        ],
                        const SizedBox(height: 20),
                        if (joinedHives.isNotEmpty) ...[
                          _buildSectionHeader('Joined Hives'),
                          ...joinedHives.map((hive) =>
                              _buildWorkspaceCard(context, hive, colorScheme, ref, isJoined: true)),
                        ],
                        const SizedBox(height: 100), 
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        label: const Text('New Hive'),
        icon: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FilledButton.icon(
          onPressed: () => _showJoinDialog(context, ref),
          icon: const Icon(Icons.group_add_rounded),
          label: const Text('Join a Hive'),
        ),
      ),
    );
  }

  // --- UI HELPER METHODS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Profile profile, ColorScheme color) {
    return Row(
      children: [
        CircleAvatar(
  radius: 28,
  // Direct call to Theme.of(context) avoids the "undefined variable" error
  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
  
  foregroundImage: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
      ? NetworkImage(profile.avatarUrl!)
      : null,
      
  child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
      ? Text(
          profile.username[0].toUpperCase(),
          style: TextStyle(
            // Direct call here too
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        )
      : null,
),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: Theme.of(context).textTheme.bodySmall),
            Text(profile.username,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkspaceCard(
      BuildContext context, Workspace hive, ColorScheme color, WidgetRef ref, {bool isJoined = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: isJoined ? color.tertiaryContainer : color.secondaryContainer,
              borderRadius: BorderRadius.circular(12)),
          child: Icon(
            isJoined ? Icons.group_work_rounded : Icons.hive_rounded, 
            color: isJoined ? color.onTertiaryContainer : color.onSecondaryContainer
          ),
        ),
        title: Text(hive.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: isJoined 
          ? const Text('Member') 
          : Text('Invite Code: ${hive.inviteCode}'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TaskBoardScreen(workspace: hive)),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rocket_launch_rounded,
              size: 60, color: color.primary.withOpacity(0.3)),
          const SizedBox(height: 10),
          const Text('No Hives yet. Time to create or join one!'),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Hive'),
        content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Hive Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await WorkspaceService().createWorkspace(controller.text);
                  ref.invalidate(workspacesProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join a Hive'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter 6-digit Invite Code',
            prefixIcon: Icon(Icons.vpn_key_rounded),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                await WorkspaceService().joinWorkspace(controller.text);
                ref.invalidate(workspacesProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Welcome to the Hive!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}