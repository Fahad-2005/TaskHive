class Task {
  final String? id; // Optional so the database can generate it
  final String workspaceId;
  final String creatorId;
  final String? assignedTo;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final DateTime? deadline;
  final DateTime? createdAt;

  Task({
    this.id,
    required this.workspaceId,
    required this.creatorId,
    this.assignedTo,
    required this.title,
    this.description,
    this.status = 'todo',
    this.priority = 'medium',
    this.deadline,
    this.createdAt,
  });

  // --- Converts Database Map to Flutter Object ---
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      workspaceId: map['workspace_id'] ?? '',
      creatorId: map['creator_id'] ?? '',
      assignedTo: map['assigned_to'],
      title: map['title'] ?? 'Untitled Task',
      description: map['description'],
      status: map['status'] ?? 'todo',
      priority: map['priority'] ?? 'medium',
      deadline: map['deadline'] != null 
          ? DateTime.parse(map['deadline']) 
          : null,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
    );
  }

  // --- Converts Flutter Object to Database Map ---
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id, // Only include ID if it exists (for updates)
      'workspace_id': workspaceId,
      'creator_id': creatorId,
      'assigned_to': assignedTo,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'deadline': deadline?.toIso8601String(),
    };
  }
}