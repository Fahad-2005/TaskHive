class Task {
  final String? id;
  final String workspaceId;
  final String creatorId;
  final String? assignedTo;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final DateTime? deadline;
  final DateTime? createdAt;
  final String? assigneeName; // 👈 1. Add this field

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
    this.assigneeName, // 👈 2. Add this to constructor
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      // Ensure string UUID for Supabase .eq('id', ...) filters
      id: map['id']?.toString(),
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
      // 👈 3. Add this line to grab the username from the join
      assigneeName: map['assignee']?['username']?.toString(), 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'workspace_id': workspaceId,
      'creator_id': creatorId,
      'assigned_to': assignedTo,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'deadline': deadline?.toIso8601String(),
      // Note: we don't include assigneeName here because it's not a column in the tasks table
    };
  }
}