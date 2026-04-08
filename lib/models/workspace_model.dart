class Workspace {
  final String id;
  final String name;
  final String ownerId;
  final String inviteCode;

  Workspace({
    required this.id, 
    required this.name, 
    required this.ownerId, 
    required this.inviteCode
  });

  factory Workspace.fromMap(Map<String, dynamic> map) {
    return Workspace(
      id: map['id'],
      name: map['name'],
      ownerId: map['owner_id'],
      inviteCode: map['invite_code'],
    );
  }
}