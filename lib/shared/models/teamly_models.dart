class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'member',
  });

  final int id;
  final String name;
  final String email;
  final String role;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        role: (json['role'] ?? 'member').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
      };
}

class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.name,
    this.description = '',
    this.ownerId = 0,
    this.startDate,
    this.deadline,
    this.theme = 'blue_campus',
  });

  final int id;
  final String name;
  final String description;
  final int ownerId;
  final String? startDate;
  final String? deadline;
  final String theme;

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: (json['name'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        ownerId: (json['owner_id'] as num?)?.toInt() ?? 0,
        startDate: json['start_date']?.toString(),
        deadline: json['deadline']?.toString(),
        theme: (json['theme'] ?? 'blue_campus').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'owner_id': ownerId,
        'start_date': startDate,
        'deadline': deadline,
        'theme': theme,
      };
}

class MemberModel {
  const MemberModel({
    required this.id,
    required this.projectId,
    this.userId,
    required this.name,
    required this.email,
    this.role = 'Member',
    this.colorHex = '#6366F1',
  });

  final int id;
  final int projectId;
  final int? userId;
  final String name;
  final String email;
  final String role;
  final String colorHex;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'TM';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        projectId: (json['project_id'] as num?)?.toInt() ?? 0,
        userId: (json['user_id'] as num?)?.toInt(),
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        role: (json['role'] ?? 'Member').toString(),
        colorHex: (json['bg'] ?? json['color_hex'] ?? '#6366F1').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'user_id': userId,
        'name': name,
        'email': email,
        'role': role,
        'bg': colorHex,
      };

  MemberModel copyWith({int? projectId}) => MemberModel(
        id: id,
        projectId: projectId ?? this.projectId,
        userId: userId,
        name: name,
        email: email,
        role: role,
        colorHex: colorHex,
      );
}

class TaskComment {
  const TaskComment({
    required this.id,
    required this.author,
    required this.role,
    required this.text,
    required this.time,
  });

  final String id;
  final String author;
  final String role;
  final String text;
  final String time;

  factory TaskComment.fromJson(Map<String, dynamic> json) => TaskComment(
        id: (json['id'] ?? '').toString(),
        author: (json['author'] ?? '').toString(),
        role: (json['role'] ?? 'Anggota').toString(),
        text: (json['text'] ?? '').toString(),
        time: (json['time'] ?? 'Baru saja').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'role': role,
        'text': text,
        'time': time,
      };
}

class TaskModel {
  const TaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.assigneeId,
    this.assigneeName = 'Unassigned',
    this.status = 'todo',
    this.priority = 'medium',
    this.deadline,
    this.estimatedHours = 4,
    this.category = 'Task',
    this.timeSlot = '10.00',
    this.comments = const [],
  });

  final String id;
  final int projectId;
  final String title;
  final String description;
  final int? assigneeId;
  final String assigneeName;
  final String status;
  final String priority;
  final String? deadline;
  final double estimatedHours;
  final String category;
  final String timeSlot;
  final List<TaskComment> comments;

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: (json['id'] ?? '').toString(),
        projectId: (json['project_id'] as num?)?.toInt() ?? 0,
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        assigneeId: (json['assignee_id'] as num?)?.toInt(),
        assigneeName: (json['assignee'] ?? 'Unassigned').toString(),
        status: (json['status'] ?? 'todo').toString(),
        priority: (json['priority'] ?? 'medium').toString(),
        deadline: json['deadline']?.toString(),
        estimatedHours: (json['estimated_hours'] as num?)?.toDouble() ?? 4.0,
        category: (json['category'] ?? 'Task').toString(),
        timeSlot: (json['time_slot'] ?? '10.00').toString(),
        comments: (json['comments'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(TaskComment.fromJson)
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'title': title,
        'description': description,
        'assignee_id': assigneeId,
        'assignee': assigneeName,
        'status': status,
        'priority': priority,
        'deadline': deadline,
        'estimated_hours': estimatedHours,
        'category': category,
        'time_slot': timeSlot,
        'comments': comments.map((c) => c.toJson()).toList(),
      };

  TaskModel copyWith({
    String? id,
    int? projectId,
    String? title,
    String? description,
    int? assigneeId,
    bool clearAssignee = false,
    String? assigneeName,
    String? status,
    String? priority,
    String? deadline,
    bool clearDeadline = false,
    double? estimatedHours,
    String? category,
    String? timeSlot,
    List<TaskComment>? comments,
  }) =>
      TaskModel(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        title: title ?? this.title,
        description: description ?? this.description,
        assigneeId: clearAssignee ? null : (assigneeId ?? this.assigneeId),
        assigneeName: assigneeName ?? this.assigneeName,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        deadline: clearDeadline ? null : (deadline ?? this.deadline),
        estimatedHours: estimatedHours ?? this.estimatedHours,
        category: category ?? this.category,
        timeSlot: timeSlot ?? this.timeSlot,
        comments: comments ?? this.comments,
      );
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.taskTitle,
    required this.recipientName,
    required this.action,
    required this.time,
    this.unread = true,
  });

  final int id;
  final String title;
  final String taskTitle;
  final String recipientName;
  final String action;
  final String time;
  final bool unread;

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: (json['id'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
        title: (json['title'] ?? 'Aktivitas').toString(),
        taskTitle: (json['taskTitle'] ?? '').toString(),
        recipientName: (json['recipientName'] ?? 'Anggota Tim').toString(),
        action: (json['action'] ?? '').toString(),
        time: (json['time'] ?? 'Baru saja').toString(),
        unread: json['unread'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'taskTitle': taskTitle,
        'recipientName': recipientName,
        'action': action,
        'time': time,
        'unread': unread,
      };

  NotificationItem copyWith({bool? unread}) => NotificationItem(
        id: id,
        title: title,
        taskTitle: taskTitle,
        recipientName: recipientName,
        action: action,
        time: time,
        unread: unread ?? this.unread,
      );
}

class GeneratedTaskIdea {
  const GeneratedTaskIdea({
    required this.title,
    this.description = '',
    this.priority = 'medium',
    this.estimatedHours = 4,
    this.role = 'Developer',
  });

  final String title;
  final String description;
  final String priority;
  final double estimatedHours;
  final String role;

  factory GeneratedTaskIdea.fromJson(Map<String, dynamic> json) => GeneratedTaskIdea(
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        priority: (json['priority'] ?? 'medium').toString(),
        estimatedHours: (json['estimated_hours'] as num?)?.toDouble() ?? 4.0,
        role: (json['role'] ?? 'Developer').toString(),
      );
}

class ProjectIdeaCardModel {
  const ProjectIdeaCardModel({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.targetPlatform,
    required this.bannerTheme,
    required this.techStack,
    required this.features,
    required this.tasks,
    required this.roles,
  });

  final String id;
  final String name;
  final String tagline;
  final String description;
  final String category;
  final String difficulty;
  final String targetPlatform;
  final String bannerTheme;
  final List<String> techStack;
  final List<String> features;
  final List<GeneratedTaskIdea> tasks;
  final List<String> roles;

  factory ProjectIdeaCardModel.fromJson(Map<String, dynamic> json) => ProjectIdeaCardModel(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        tagline: (json['tagline'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        category: (json['category'] ?? '').toString(),
        difficulty: (json['difficulty'] ?? 'Standar').toString(),
        targetPlatform: (json['target_platform'] ?? 'Web App').toString(),
        bannerTheme: (json['banner_theme'] ?? 'blue_campus').toString(),
        techStack: (json['tech_stack'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        features: (json['features'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        tasks: (json['tasks'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(GeneratedTaskIdea.fromJson)
                .toList() ??
            const [],
        roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}
