class Profile {
  final String id;
  final String username;
  final String? avatarUrl;

  Profile({required this.id, required this.username, this.avatarUrl});

  // Convert Supabase Map to Profile object
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      username: map['username'] ?? 'No Username',
      avatarUrl: map['avatar_url'],
    );
  }
}