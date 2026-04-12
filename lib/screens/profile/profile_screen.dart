import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../models/profile_model.dart';
import 'privacy_policy_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _pickAndUploadImage(ImageSource source) async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: source, imageQuality: 50);

  if (image == null) return;

  setState(() => _isLoading = true);

  try {
    final userId = _supabase.auth.currentUser!.id;
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';
    final path = '$userId/$fileName';

    if (kIsWeb) {
      // 🌐 WEB UPLOAD LOGIC
      final bytes = await image.readAsBytes();
      await _supabase.storage.from('profile_Avatar').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
    } else {
      // 📱 MOBILE UPLOAD LOGIC
      final file = File(image.path);
      await _supabase.storage.from('profile_Avatar').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
    }

    final imageUrl = _supabase.storage.from('profile_Avatar').getPublicUrl(path);

    await _supabase.from('profiles').update({'avatar_url': imageUrl}).eq('id', userId);

    if (mounted) setState(() {}); 
  } catch (e) {
    print("Upload Error: $e");
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
        child: FutureBuilder(
          future: _supabase.from('profiles').select().eq('id', user!.id).single(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Failed to load profile.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              );
            }

            final profile = Profile.fromMap(snapshot.data!);

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: colorScheme.primaryContainer,
                                  foregroundImage: profile.avatarUrl != null
                                      ? NetworkImage(profile.avatarUrl!)
                                      : null,
                                  child: _isLoading
                                      ? const CircularProgressIndicator()
                                      : profile.avatarUrl == null
                                          ? Icon(
                                              Icons.person_rounded,
                                              size: 58,
                                              color:
                                                  colorScheme.onPrimaryContainer,
                                            )
                                          : null,
                                ),
                                FloatingActionButton.small(
                                  heroTag: 'edit_profile_avatar',
                                  onPressed: _showPickerOptions,
                                  child: const Icon(Icons.edit_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              profile.username,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email ?? 'No Email',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              child: Text(
                                'Your profile controls your identity across all hives and activity in TaskHive.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const PrivacyPolicyScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.privacy_tip_outlined),
                              label: const Text('Privacy Policy'),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => AuthService().signOut(),
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Sign Out'),
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
