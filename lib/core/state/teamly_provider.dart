import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/projects/repositories/project_repository.dart';
import '../../features/tasks/repositories/task_repository.dart';
import '../../features/team/repositories/team_repository.dart';
import '../../features/ai_assistant/repositories/ai_repository.dart';
import '../../shared/models/teamly_models.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokenStorage: ref.watch(tokenStorageProvider)),
);
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider)),
);
final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => ProjectRepository(ref.watch(apiClientProvider)),
);
final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(apiClientProvider)),
);
final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => TeamRepository(ref.watch(apiClientProvider)),
);
final aiRepositoryProvider = Provider<AiRepository>(
  (ref) => AiRepository(ref.watch(apiClientProvider)),
);

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.provider,
  });
  final String text;
  final bool isUser;
  final String? provider;
}

class TeamlyState {
  const TeamlyState({
    this.initialized = false,
    this.token,
    this.user,
    this.projects = const [],
    this.activeProjectId,
    this.allTasks = const [],
    this.allMembers = const [],
    this.notifications = const [],
    this.chatMessages = const [],
    this.isLoading = false,
    this.simulatedRole = 'leader',
  });

  final bool initialized;
  final String? token;
  final UserModel? user;
  final List<ProjectModel> projects;
  final int? activeProjectId;
  final List<TaskModel> allTasks;
  final List<MemberModel> allMembers;
  final List<NotificationItem> notifications;
  final List<ChatMessage> chatMessages;
  final bool isLoading;
  final String simulatedRole; // 'leader' | 'member' for demo preview

  bool get isGuest => token == null || token!.isEmpty || user == null;
  bool get isRealJwt =>
      token != null &&
      token!.isNotEmpty &&
      !token!.startsWith('admin_token_') &&
      !token!.startsWith('local_');

  ProjectModel? get currentProject {
    if (projects.isEmpty) return null;
    if (activeProjectId != null) {
      for (final p in projects) {
        if (p.id == activeProjectId) return p;
      }
    }
    return projects.first;
  }

  bool get isProjectLeader {
    final p = currentProject;
    if (p == null) return true;
    if (user != null && p.ownerId != 0) {
      return p.ownerId == user!.id;
    }
    return simulatedRole == 'leader';
  }

  MemberModel? get currentUserMember {
    final members = currentMembers;
    if (members.isEmpty) return null;
    if (user != null) {
      for (final m in members) {
        if (m.userId == user!.id || m.email.toLowerCase() == user!.email.toLowerCase()) {
          return m;
        }
      }
    }
    if (!isProjectLeader) {
      for (final m in members) {
        if (!m.role.toLowerCase().contains('owner') && !m.role.toLowerCase().contains('leader')) {
          return m;
        }
      }
      return members.last;
    }
    return members.first;
  }

  List<TaskModel> get myAssignedTasks {
    final me = currentUserMember;
    if (me == null) return currentTasks;
    return currentTasks.where((t) => t.assigneeId == me.id).toList();
  }

  List<TaskModel> get currentTasks {
    final p = currentProject;
    if (p == null) return const [];
    return allTasks.where((t) => t.projectId == p.id).toList();
  }

  List<MemberModel> get currentMembers {
    final p = currentProject;
    if (p == null) return const [];
    return allMembers.where((m) => m.projectId == p.id).toList();
  }

  int get unreadNotificationCount => notifications.where((n) => n.unread).length;

  TeamlyState copyWith({
    bool? initialized,
    String? token,
    bool clearToken = false,
    UserModel? user,
    bool clearUser = false,
    List<ProjectModel>? projects,
    int? activeProjectId,
    bool clearActiveProject = false,
    List<TaskModel>? allTasks,
    List<MemberModel>? allMembers,
    List<NotificationItem>? notifications,
    List<ChatMessage>? chatMessages,
    bool? isLoading,
    String? simulatedRole,
  }) =>
      TeamlyState(
        initialized: initialized ?? this.initialized,
        token: clearToken ? null : (token ?? this.token),
        user: clearUser ? null : (user ?? this.user),
        projects: projects ?? this.projects,
        activeProjectId: clearActiveProject ? null : (activeProjectId ?? this.activeProjectId),
        allTasks: allTasks ?? this.allTasks,
        allMembers: allMembers ?? this.allMembers,
        notifications: notifications ?? this.notifications,
        chatMessages: chatMessages ?? this.chatMessages,
        isLoading: isLoading ?? this.isLoading,
        simulatedRole: simulatedRole ?? this.simulatedRole,
      );
}

class TeamlyNotifier extends StateNotifier<TeamlyState> {
  TeamlyNotifier(this._ref) : super(const TeamlyState()) {
    _bootstrap();
  }

  final Ref _ref;
  WebSocket? _ws;
  Timer? _syncTimer;

  AuthRepository get _authRepo => _ref.read(authRepositoryProvider);
  ProjectRepository get _projectRepo => _ref.read(projectRepositoryProvider);
  TaskRepository get _taskRepo => _ref.read(taskRepositoryProvider);
  TeamRepository get _teamRepo => _ref.read(teamRepositoryProvider);
  AiRepository get _aiRepo => _ref.read(aiRepositoryProvider);
  TokenStorage get _storage => _ref.read(tokenStorageProvider);

  @override
  void dispose() {
    _stopRealtime();
    super.dispose();
  }

  void _stopRealtime() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _ws?.close();
    _ws = null;
  }

  Future<void> _startRealtime(int projectId) async {
    _stopRealtime();
    if (!state.isRealJwt) return;

    _syncTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (state.isRealJwt) {
        syncProjectsFromBackend(silent: true);
      }
    });

    if (kIsWeb) return;
    try {
      final wsUrl = '${AppConfig.wsBaseUrl}/ws/projects/$projectId';
      _ws = await WebSocket.connect(wsUrl);
      _ws?.listen(
        (_) {
          if (state.activeProjectId == projectId) {
            loadProjectData(projectId);
          }
        },
        onError: (_) {},
        onDone: () {},
      );
    } catch (_) {}
  }

  void toggleSimulatedRole() {
    final next = state.simulatedRole == 'leader' ? 'member' : 'leader';
    state = state.copyWith(simulatedRole: next);
  }

  Future<void> setServerUrl(String url) async {
    AppConfig.setOverrideBaseUrl(url);
    await _storage.saveApiBaseUrl(AppConfig.apiBaseUrl);
  }

  Future<void> _bootstrap() async {
    try {
      final savedUrl = await _storage.readApiBaseUrl();
      if (savedUrl != null && savedUrl.isNotEmpty) {
        AppConfig.setOverrideBaseUrl(savedUrl);
      }
      final token = await _authRepo.readToken();
      final cachedUserMap = await _authRepo.readCachedUser();
      final cache = await _storage.readWorkspaceCache();

      var projects = <ProjectModel>[];
      var tasks = <TaskModel>[];
      var members = <MemberModel>[];
      var notifications = _defaultNotifications();
      int? activePid;

      if (cache != null) {
        projects = (cache['projects'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(ProjectModel.fromJson)
                .toList() ??
            [];
        tasks = (cache['tasks'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(TaskModel.fromJson)
                .toList() ??
            [];
        members = (cache['members'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(MemberModel.fromJson)
                .toList() ??
            [];
        if (cache['notifications'] is List) {
          notifications = (cache['notifications'] as List)
              .whereType<Map<String, dynamic>>()
              .map(NotificationItem.fromJson)
              .toList();
        }
        activePid = (cache['active_project_id'] as num?)?.toInt();
      }

      UserModel? user = cachedUserMap != null ? UserModel.fromJson(cachedUserMap) : null;

      state = state.copyWith(
        initialized: true,
        token: token,
        user: user,
        projects: projects,
        allTasks: tasks,
        allMembers: members,
        notifications: notifications,
        activeProjectId: activePid ?? (projects.isNotEmpty ? projects.first.id : null),
      );

      if (token != null && token.isNotEmpty && state.isRealJwt) {
        try {
          final freshUser = await _authRepo.me();
          state = state.copyWith(user: freshUser);
          await syncProjectsFromBackend();
        } catch (e) {
          final msg = ApiClient.errorMessage(e, '');
          if (msg.contains('401')) {
            await logout();
          }
        }
      }
    } catch (_) {
      state = state.copyWith(initialized: true, notifications: _defaultNotifications());
    }
  }

  Future<void> _persistCache() async {
    try {
      await _storage.saveWorkspaceCache({
        'projects': state.projects.map((p) => p.toJson()).toList(),
        'tasks': state.allTasks.map((t) => t.toJson()).toList(),
        'members': state.allMembers.map((m) => m.toJson()).toList(),
        'notifications': state.notifications.map((n) => n.toJson()).toList(),
        'active_project_id': state.activeProjectId,
      });
    } catch (_) {}
  }

  void loadDemoData() {
    final demoProjects = [
      const ProjectModel(
        id: 1,
        name: 'KantinGo — Pre-Order Kantin Kampus',
        description:
            'Aplikasi pre-order makanan kantin kampus untuk memangkas waktu antre saat jam istirahat kuliah.',
        deadline: '2026-12-15',
        theme: 'blue_campus',
      ),
      const ProjectModel(
        id: 2,
        name: 'KasKu — Transparansi Kas Mahasiswa',
        description:
            'Platform pencatatan iuran kas organisasi mahasiswa dengan bukti digital terverifikasi.',
        deadline: '2026-12-30',
        theme: 'purple_cooking',
      ),
    ];

    final demoMembers = [
      const MemberModel(
        id: 1,
        projectId: 1,
        name: 'Nadia Putri',
        role: 'UI/UX Designer & Dokumen',
        email: 'nadia@kampus.ac.id',
        colorHex: '#6366F1',
      ),
      const MemberModel(
        id: 2,
        projectId: 1,
        name: 'Rizky Pratama',
        role: 'Backend & Database Engineer',
        email: 'rizky@kampus.ac.id',
        colorHex: '#059669',
      ),
      const MemberModel(
        id: 3,
        projectId: 1,
        name: 'Fajar Ramadhan',
        role: 'Frontend Developer',
        email: 'fajar@kampus.ac.id',
        colorHex: '#D97706',
      ),
      const MemberModel(
        id: 4,
        projectId: 2,
        name: 'Budi Santoso',
        role: 'Fullstack Developer',
        email: 'budi@kampus.ac.id',
        colorHex: '#8B5CF6',
      ),
      const MemberModel(
        id: 5,
        projectId: 2,
        name: 'Siti Rahma',
        role: 'UI/UX & Tester',
        email: 'siti@kampus.ac.id',
        colorHex: '#EC4899',
      ),
    ];

    final demoTasks = [
      const TaskModel(
        id: 't1',
        projectId: 1,
        title: 'Rancang wireframe katalog kantin & nomor antrean',
        description: 'Wireframe responsif untuk katalog kantin dan nomor antrean.',
        status: 'done',
        priority: 'medium',
        assigneeId: 1,
        assigneeName: 'Nadia Putri',
        deadline: '2026-11-18',
        estimatedHours: 5,
        category: 'UI/UX',
        timeSlot: '08.30',
        comments: [
          TaskComment(
            id: 'c1',
            author: 'Nadia Putri',
            role: 'UI/UX',
            text: 'Wireframe v1 sudah selesai dan diunggah ke Figma.',
            time: '2 hari lalu',
          ),
        ],
      ),
      const TaskModel(
        id: 't2',
        projectId: 1,
        title: 'Implementasi API katalog menu & autentikasi JWT',
        description: 'Endpoint menu, stok real-time, dan akun pengguna.',
        status: 'doing',
        priority: 'high',
        assigneeId: 2,
        assigneeName: 'Rizky Pratama',
        deadline: '2026-11-20',
        estimatedHours: 8,
        category: 'Backend',
        timeSlot: '10.30',
      ),
      const TaskModel(
        id: 't3',
        projectId: 1,
        title: 'Desain skema basis data pesanan & transaksi',
        description: 'Relasi tabel mahasiswa, pesanan, menu, dan detail transaksi.',
        status: 'done',
        priority: 'high',
        assigneeId: 2,
        assigneeName: 'Rizky Pratama',
        deadline: '2026-11-21',
        estimatedHours: 6,
        category: 'Database',
        timeSlot: '13.00',
      ),
      const TaskModel(
        id: 't4',
        projectId: 1,
        title: 'Integrasi frontend pemesanan dengan REST API',
        description: 'Tampilan keranjang, checkout pesanan, dan nomor antrean.',
        status: 'review',
        priority: 'high',
        assigneeId: 3,
        assigneeName: 'Fajar Ramadhan',
        deadline: '2026-12-05',
        estimatedHours: 8,
        category: 'Frontend',
        timeSlot: '15.30',
      ),
      const TaskModel(
        id: 't5',
        projectId: 1,
        title: 'Pengujian fungsionalitas & bab laporan tugas',
        description: 'Uji alur checkout dan tulis bab pengujian untuk laporan tugas.',
        status: 'todo',
        priority: 'medium',
        assigneeId: 1,
        assigneeName: 'Nadia Putri',
        deadline: '2026-12-10',
        estimatedHours: 6,
        category: 'Laporan',
        timeSlot: '17.00',
      ),
      const TaskModel(
        id: 't6',
        projectId: 2,
        title: 'Setup arsitektur project & skema kas iuran',
        description: 'Struktur tabel kas, pencatatan transaksi masuk dan keluar.',
        status: 'done',
        priority: 'high',
        assigneeId: 4,
        assigneeName: 'Budi Santoso',
        deadline: '2026-11-15',
        estimatedHours: 8,
        category: 'Backend',
        timeSlot: '09.00',
      ),
      const TaskModel(
        id: 't7',
        projectId: 2,
        title: 'Desain UI form upload bukti transfer kas',
        description: 'Form upload bukti transfer dengan preview gambar.',
        status: 'doing',
        priority: 'medium',
        assigneeId: 5,
        assigneeName: 'Siti Rahma',
        deadline: '2026-12-08',
        estimatedHours: 5,
        category: 'Frontend',
        timeSlot: '14.00',
      ),
    ];

    state = state.copyWith(
      projects: demoProjects,
      allMembers: demoMembers,
      allTasks: demoTasks,
      activeProjectId: 1,
      notifications: _defaultNotifications(),
    );
    _persistCache();
  }

  Future<void> setAuthenticatedSession(String token, UserModel user) async {
    state = state.copyWith(token: token, user: user);
    await _authRepo.saveLocalSession(token, user);
    if (state.isRealJwt) {
      await syncProjectsFromBackend();
    }
  }

  Future<void> logout() async {
    _stopRealtime();
    state = TeamlyState(
      initialized: true,
      notifications: _defaultNotifications(),
    );
    await _authRepo.logout();
    await _storage.clearWorkspaceCache();
  }

  Future<void> syncProjectsFromBackend({bool silent = false}) async {
    if (!state.isRealJwt) return;
    try {
      if (!silent) state = state.copyWith(isLoading: true);
      final remoteProjects = await _projectRepo.getProjects();
      if (!state.isRealJwt) return;
      int? activePid = state.activeProjectId;
      if (remoteProjects.isNotEmpty &&
          (activePid == null || !remoteProjects.any((p) => p.id == activePid))) {
        activePid = remoteProjects.first.id;
      } else if (remoteProjects.isEmpty) {
        activePid = null;
      }
      state = state.copyWith(
        projects: remoteProjects,
        activeProjectId: activePid,
        clearActiveProject: activePid == null,
        isLoading: false,
      );
      if (activePid != null) {
        await loadProjectData(activePid);
        if (_ws == null) {
          await _startRealtime(activePid);
        }
      }
      await _persistCache();
    } catch (_) {
      if (!silent) state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadProjectData(int projectId) async {
    if (!state.isRealJwt) return;
    try {
      final results = await Future.wait([
        _teamRepo.getMembers(projectId),
        _taskRepo.getTasks(projectId),
        _projectRepo.getNotifications(projectId),
      ]);
      if (!state.isRealJwt) return;
      final remoteMembers = results[0] as List<MemberModel>;
      final remoteTasks = results[1] as List<TaskModel>;
      final remoteLogs = results[2];

      final memberById = {for (final m in remoteMembers) m.id: m.name};
      final existingComments = {for (final t in state.allTasks) t.id: t.comments};
      final enrichedTasks = remoteTasks
          .map((t) => t.copyWith(
                assigneeName: t.assigneeId != null
                    ? (memberById[t.assigneeId] ?? 'Anggota')
                    : 'Unassigned',
                comments: existingComments[t.id] ?? t.comments,
              ))
          .toList();

      final otherTasks = state.allTasks.where((t) => t.projectId != projectId).toList();
      final otherMembers = state.allMembers.where((m) => m.projectId != projectId).toList();

      final mappedNotifs = remoteLogs
          .whereType<Map<String, dynamic>>()
          .map((log) => NotificationItem(
                id: (log['id'] as num?)?.toInt() ?? 0,
                title: (log['actor'] ?? 'Sistem').toString(),
                taskTitle: (log['action'] ?? '').toString(),
                recipientName: 'Tim',
                action: 'Aktivitas real-time',
                time: (log['created_at'] ?? '').toString().split('T').first,
                unread: true,
              ))
          .toList();

      state = state.copyWith(
        allTasks: [...otherTasks, ...enrichedTasks],
        allMembers: [...otherMembers, ...remoteMembers],
        notifications: mappedNotifs.isNotEmpty ? mappedNotifs : state.notifications,
      );
      await _persistCache();
    } catch (_) {}
  }

  Future<void> selectProject(int projectId) async {
    state = state.copyWith(activeProjectId: projectId);
    await _persistCache();
    await loadProjectData(projectId);
    await _startRealtime(projectId);
  }

  Future<void> createProject({
    required String name,
    String description = '',
    String? deadline,
    String theme = 'blue_campus',
  }) async {
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final newProj = ProjectModel(
      id: tempId,
      name: name,
      description: description,
      ownerId: state.user?.id ?? 0,
      deadline: deadline,
      theme: theme,
    );
    final leadMember = MemberModel(
      id: tempId + 1,
      projectId: tempId,
      userId: state.user?.id,
      name: state.user?.name ?? 'Project Leader',
      email: state.user?.email ?? 'leader@teamly.app',
      role: 'Project Leader',
      colorHex: '#F97316',
    );

    state = state.copyWith(
      projects: [newProj, ...state.projects],
      allMembers: [leadMember, ...state.allMembers],
      activeProjectId: tempId,
    );
    _addNotification(name, 'Project baru dibuat');
    await _persistCache();

    if (state.isRealJwt) {
      try {
        final created = await _projectRepo.createProject({
          'name': name,
          'description': description,
          'deadline': (deadline != null && deadline.isNotEmpty) ? deadline : null,
        });
        state = state.copyWith(
          projects: state.projects.map((p) => p.id == tempId ? created : p).toList(),
          allMembers: state.allMembers
              .map((m) => m.projectId == tempId ? m.copyWith(projectId: created.id) : m)
              .toList(),
          activeProjectId: created.id,
        );
        await loadProjectData(created.id);
        await _persistCache();
      } catch (_) {}
    }
  }

  Future<void> deleteProject(int projectId) async {
    final nextProjects = state.projects.where((p) => p.id != projectId).toList();
    final nextActive = state.activeProjectId == projectId
        ? (nextProjects.isNotEmpty ? nextProjects.first.id : null)
        : state.activeProjectId;

    state = state.copyWith(
      projects: nextProjects,
      allTasks: state.allTasks.where((t) => t.projectId != projectId).toList(),
      allMembers: state.allMembers.where((m) => m.projectId != projectId).toList(),
      activeProjectId: nextActive,
      clearActiveProject: nextActive == null,
    );
    await _persistCache();

    if (state.isRealJwt) {
      try {
        await _projectRepo.deleteProject(projectId);
      } catch (_) {}
    }
  }

  Future<void> applyIdeaAsProject(ProjectIdeaCardModel idea) async {
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final newProj = ProjectModel(
      id: tempId,
      name: idea.name,
      description: idea.description,
      ownerId: state.user?.id ?? 0,
      theme: idea.bannerTheme,
    );
    final leadMember = MemberModel(
      id: tempId + 1,
      projectId: tempId,
      userId: state.user?.id,
      name: state.user?.name ?? 'Project Leader',
      email: state.user?.email ?? 'leader@teamly.app',
      role: 'Project Leader',
      colorHex: '#F97316',
    );
    const slots = ['08.30', '10.30', '13.00', '15.30', '17.00'];
    final generatedTasks = <TaskModel>[];
    for (var i = 0; i < idea.tasks.length; i++) {
      final t = idea.tasks[i];
      generatedTasks.add(TaskModel(
        id: 'gt_${tempId}_$i',
        projectId: tempId,
        title: t.title,
        description: t.description,
        status: 'todo',
        priority: t.priority,
        estimatedHours: t.estimatedHours,
        assigneeName: 'Unassigned',
        category: i == 0
            ? 'UI/UX'
            : i == 1
                ? 'Database'
                : i == 2
                    ? 'Backend'
                    : i == 3
                        ? 'Frontend'
                        : 'Testing',
        timeSlot: slots[i % slots.length],
      ));
    }

    state = state.copyWith(
      projects: [newProj, ...state.projects],
      allMembers: [leadMember, ...state.allMembers],
      allTasks: [...generatedTasks, ...state.allTasks],
      activeProjectId: tempId,
    );
    _addNotification(idea.name, 'Workspace dibuat dari rekomendasi AI');
    await _persistCache();

    if (state.isRealJwt) {
      try {
        final created = await _projectRepo.createProject({
          'name': idea.name,
          'description': idea.description,
          'deadline': null,
        });
        state = state.copyWith(
          projects: state.projects.map((p) => p.id == tempId ? created : p).toList(),
          activeProjectId: created.id,
        );
        for (final t in idea.tasks) {
          await _taskRepo.createTask(created.id, {
            'title': t.title,
            'description': t.description,
            'status': 'todo',
            'priority': t.priority,
            'deadline': null,
            'estimated_hours': t.estimatedHours,
            'assignee_id': null,
          });
        }
        await loadProjectData(created.id);
        await _persistCache();
      } catch (_) {}
    }
  }

  Future<void> createTask({
    required String title,
    String description = '',
    String status = 'todo',
    String priority = 'medium',
    String? deadline,
    double estimatedHours = 4,
    int? assigneeId,
    String category = 'Frontend',
    String timeSlot = '10.00',
  }) async {
    final project = state.currentProject;
    if (project == null) return;

    MemberModel? member;
    for (final m in state.currentMembers) {
      if (m.id == assigneeId) {
        member = m;
        break;
      }
    }

    final tempId = 't_${DateTime.now().millisecondsSinceEpoch}';
    final task = TaskModel(
      id: tempId,
      projectId: project.id,
      title: title,
      description: description,
      status: status,
      priority: priority,
      deadline: (deadline != null && deadline.isNotEmpty) ? deadline : null,
      estimatedHours: estimatedHours,
      assigneeId: assigneeId,
      assigneeName: member?.name ?? 'Unassigned',
      category: category,
      timeSlot: timeSlot,
    );

    state = state.copyWith(allTasks: [task, ...state.allTasks]);
    _addNotification(title, 'Tugas baru ditambahkan', recipient: task.assigneeName);
    await _persistCache();

    if (state.isRealJwt) {
      try {
        final created = await _taskRepo.createTask(project.id, {
          'title': title,
          'description': description,
          'status': status,
          'priority': priority,
          'deadline': (deadline != null && deadline.isNotEmpty) ? deadline : null,
          'estimated_hours': estimatedHours,
          'assignee_id': assigneeId,
        });
        final synced = created.copyWith(
          assigneeName: task.assigneeName,
          category: category,
          timeSlot: timeSlot,
        );
        state = state.copyWith(
          allTasks: state.allTasks.map((t) => t.id == tempId ? synced : t).toList(),
        );
        await _persistCache();
      } catch (_) {}
    }
  }

  Future<String?> updateTask(TaskModel updated) async {
    final previous = state.allTasks;
    state = state.copyWith(
      allTasks: state.allTasks.map((t) => t.id == updated.id ? updated : t).toList(),
    );
    _addNotification(
      updated.title,
      'Tugas diperbarui (${statusLabel(updated.status)})',
      recipient: updated.assigneeName,
    );
    await _persistCache();

    if (state.isRealJwt) {
      try {
        final payload = state.isProjectLeader
            ? {
                'title': updated.title,
                'description': updated.description,
                'status': updated.status,
                'priority': updated.priority,
                'deadline': (updated.deadline != null && updated.deadline!.isNotEmpty)
                    ? updated.deadline
                    : null,
                'estimated_hours': updated.estimatedHours,
                'assignee_id': updated.assigneeId,
              }
            : {'status': updated.status};
        final remote = await _taskRepo.updateTask(updated.id, payload);
        final synced = remote.copyWith(
          assigneeName: updated.assigneeName,
          category: updated.category,
          timeSlot: updated.timeSlot,
          comments: updated.comments,
        );
        state = state.copyWith(
          allTasks: state.allTasks.map((t) => t.id == updated.id ? synced : t).toList(),
        );
        await _persistCache();
      } catch (e) {
        state = state.copyWith(allTasks: previous);
        return ApiClient.errorMessage(e, 'Gagal menyimpan perubahan tugas');
      }
    }
    return null;
  }

  Future<void> changeTaskStatus(TaskModel task, String newStatus) async {
    await updateTask(task.copyWith(status: newStatus));
  }

  Future<void> deleteTask(TaskModel task) async {
    state = state.copyWith(
      allTasks: state.allTasks.where((t) => t.id != task.id).toList(),
    );
    _addNotification(task.title, 'Tugas dihapus dari sprint', recipient: task.assigneeName);
    await _persistCache();

    if (state.isRealJwt) {
      try {
        await _taskRepo.deleteTask(task.id);
      } catch (_) {}
    }
  }

  Future<void> addComment(TaskModel task, String text) async {
    final author = state.user?.name ??
        (task.assigneeName != 'Unassigned' ? task.assigneeName : 'Anggota Tim');
    final comment = TaskComment(
      id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
      author: author,
      role: state.isProjectLeader ? 'Project Leader' : 'Anggota Tim',
      text: text.trim(),
      time: 'Baru saja',
    );
    final updated = task.copyWith(comments: [...task.comments, comment]);
    state = state.copyWith(
      allTasks: state.allTasks.map((t) => t.id == task.id ? updated : t).toList(),
    );
    _addNotification(task.title, 'Feedback baru dari $author', recipient: task.assigneeName);
    await _persistCache();

    if (state.isRealJwt) {
      try {
        await _taskRepo.addComment(task.id, text.trim());
        await loadProjectData(task.projectId);
      } catch (_) {}
    }
  }

  Future<void> loadTaskComments(TaskModel task) async {
    if (!state.isRealJwt) return;
    try {
      final remote = await _taskRepo.getComments(task.id);
      final updated = task.copyWith(comments: remote);
      state = state.copyWith(
        allTasks: state.allTasks.map((t) => t.id == task.id ? updated : t).toList(),
      );
    } catch (_) {}
  }

  Future<void> addMember({
    required String name,
    required String email,
    required String role,
    required String colorHex,
  }) async {
    final project = state.currentProject;
    if (project == null) return;
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final member = MemberModel(
      id: tempId,
      projectId: project.id,
      name: name,
      email: email,
      role: role,
      colorHex: colorHex,
    );
    state = state.copyWith(allMembers: [...state.allMembers, member]);
    _addNotification(project.name, 'Anggota baru $name bergabung', recipient: name);
    await _persistCache();

    if (state.isRealJwt) {
      try {
        final created = await _teamRepo.addMember(project.id, {
          'name': name,
          'email': email,
          'role': role,
        });
        state = state.copyWith(
          allMembers: state.allMembers
              .map((m) => m.id == tempId
                  ? MemberModel(
                      id: created.id,
                      projectId: created.projectId,
                      userId: created.userId,
                      name: created.name,
                      email: created.email,
                      role: created.role,
                      colorHex: colorHex,
                    )
                  : m)
              .toList(),
        );
        await _persistCache();
      } catch (_) {}
    }
  }

  Future<void> removeMember(MemberModel member) async {
    state = state.copyWith(
      allMembers: state.allMembers.where((m) => m.id != member.id).toList(),
    );
    await _persistCache();

    if (state.isRealJwt) {
      try {
        await _teamRepo.removeMember(member.projectId, member.id);
      } catch (_) {}
    }
  }

  Future<void> sendAiMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      chatMessages: [...state.chatMessages, ChatMessage(text: trimmed, isUser: true)],
    );

    final project = state.currentProject;
    String answer;
    String provider = 'rule-based-fallback';

    if (project != null && state.isRealJwt) {
      try {
        final res = await _aiRepo.chat(projectId: project.id, message: trimmed);
        answer = (res['answer'] ?? '').toString();
        provider = (res['provider'] ?? 'gemini').toString();
      } catch (_) {
        answer = _aiRepo.localChatFallback(trimmed, project, state.currentTasks);
      }
    } else {
      answer = _aiRepo.localChatFallback(trimmed, project, state.currentTasks);
    }

    state = state.copyWith(
      chatMessages: [
        ...state.chatMessages,
        ChatMessage(text: answer, isUser: false, provider: provider),
      ],
    );
  }

  void markAllNotificationsRead() {
    state = state.copyWith(
      notifications: state.notifications.map((n) => n.copyWith(unread: false)).toList(),
    );
    _persistCache();
  }

  void _addNotification(String taskTitle, String action, {String recipient = 'Anggota Tim'}) {
    final item = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Aktivitas Tugas',
      taskTitle: taskTitle,
      recipientName: recipient,
      action: action,
      time: 'Baru saja',
      unread: true,
    );
    state = state.copyWith(
      notifications: [item, ...state.notifications.take(19)],
    );
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'todo':
        return 'Belum Mulai';
      case 'doing':
        return 'Dikerjakan';
      case 'review':
        return 'Review';
      case 'done':
        return 'Selesai';
      default:
        return status;
    }
  }

  static List<NotificationItem> _defaultNotifications() => const [
        NotificationItem(
          id: 1,
          title: 'Selamat Datang',
          taskTitle: 'Teamly',
          recipientName: 'Tim Kelompok',
          action: 'Mulai dengan Temukan Ide atau muat data demo.',
          time: 'Baru saja',
          unread: true,
        ),
      ];
}

final teamlyProvider = StateNotifierProvider<TeamlyNotifier, TeamlyState>(
  (ref) => TeamlyNotifier(ref),
);
