class Task {
  final String id;
  final String workspaceId;
  final String title;
  final String? description;
  final String status; // 'todo', 'in_progress', 'done'
  final DateTime createdAt;

  Task({
    required this.id,
    required this.workspaceId,
    required this.title,
    this.description,
    required this.status,
    required this.createdAt,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      workspaceId: map['workspace_id'],
      title: map['title'],
      description: map['description'],
      status: map['status'] ?? 'todo',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}