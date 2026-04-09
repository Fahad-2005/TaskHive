import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/workspace_provider.dart';
import '../../models/profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/workspace_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final workspacesAsync = ref.watch(workspacesProvider);
    final userId = Supabase.instance.client.auth.currentUser!.id;

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
        child: Column(
          children: [
            // 1. Profile Summary Section (using FutureBuilder for the name)
            FutureBuilder(
              future: Supabase.instance.client.from('profiles').select().eq('id', userId).single(),
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
                data: (workspaces) => workspaces.isEmpty
                    ? _buildEmptyState(context, colorScheme)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: workspaces.length,
                        itemBuilder: (context, index) {
                          final hive = workspaces[index];
                          return _buildWorkspaceCard(context, hive, colorScheme, ref);
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        label: const Text('New Hive'),
        icon: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FilledButton.icon(
          onPressed: () => _showJoinDialog(context),
          icon: const Icon(Icons.group_add_rounded),
          label: const Text('Join a Hive'),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Profile profile, ColorScheme color) {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: color.primaryContainer,
          child: Text(profile.username[0].toUpperCase()),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: Theme.of(context).textTheme.bodySmall),
            Text(profile.username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkspaceCard(BuildContext context, dynamic hive, ColorScheme color, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.secondaryContainer, borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.hive_rounded, color: color.onSecondaryContainer),
        ),
        title: Text(hive.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Invite Code: ${hive.inviteCode}'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          // Tomorrow we will navigate here!
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening ${hive.name}...')));
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rocket_launch_rounded, size: 60, color: color.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 10),
          const Text('No Hives yet. Time to create one!'),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Hive'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Hive Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await WorkspaceService().createWorkspace(controller.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
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