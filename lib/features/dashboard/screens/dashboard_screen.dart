import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/teamly_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/teamly_models.dart';
import '../../../shared/widgets/teamly_illustrations.dart';
import 'main_shell.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, required this.onNavigateTab});

  final ValueChanged<int> onNavigateTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teamlyProvider);
    final project = state.currentProject;
    final isLeader = state.isProjectLeader;
    final myMember = state.currentUserMember;
    final tasks = isLeader ? state.currentTasks : state.myAssignedTasks;
    final allProjectTasks = state.currentTasks;
    final members = state.currentMembers;

    final todoCount = tasks.where((t) => t.status == 'todo').length;
    final activeCount = tasks.where((t) => t.status == 'doing' || t.status == 'review').length;
    final reviewCount = tasks.where((t) => t.status == 'review').length;
    final doneCount = tasks.where((t) => t.status == 'done').length;
    final highCount = tasks.where((t) => t.priority == 'high' && t.status != 'done').length;
    final today = DateTime.now().toIso8601String().split('T').first;
    final overdueCount = tasks
        .where((t) => t.deadline != null && t.deadline!.isNotEmpty && t.deadline!.compareTo(today) < 0 && t.status != 'done')
        .length;
    final progress = tasks.isEmpty ? 0.0 : doneCount / tasks.length;

    final upcoming = tasks.where((t) => t.status != 'done' && t.deadline != null && t.deadline!.isNotEmpty).toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showProjectSwitcher(context, ref),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFB923C), Color(0xFFEA580C)]),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 17),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project?.name ?? 'Teamly Workspace',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      project != null ? 'Ketuk untuk ganti project' : 'Belum ada project aktif',
                      style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppTheme.muted),
            ],
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () => _showNotificationsSheet(context, ref),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              if (state.unreadNotificationCount > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: () => _showAccountMenu(context, ref),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: state.isGuest ? AppTheme.borderSubtle : AppTheme.primarySubtle,
                child: Text(
                  state.isGuest
                      ? 'G'
                      : (state.user!.name.isNotEmpty ? state.user!.name[0].toUpperCase() : 'U'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: state.isGuest ? AppTheme.muted : AppTheme.primaryDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => ref.read(teamlyProvider.notifier).syncProjectsFromBackend(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.isGuest)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.primaryDark),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Mode Guest aktif. Masuk untuk menyimpan project ke server.',
                        style: TextStyle(fontSize: 12, color: AppTheme.primaryDark),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/auth?mode=login'),
                      child: const Text('Masuk', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            if (project == null) ...[
              _EmptyWorkspaceCard(
                onFindIdea: () => onNavigateTab(1),
                onCreateProject: () => _showCreateProjectDialog(context, ref),
                onLoadDemo: () {
                  ref.read(teamlyProvider.notifier).loadDemoData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data demo berhasil dimuat!')),
                  );
                },
              ),
            ] else ...[
              Container(
                decoration: BoxDecoration(
                  gradient: isLeader ? AppTheme.primaryGradient : AppTheme.memberGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (isLeader ? AppTheme.primary : AppTheme.info).withValues(alpha: 0.28),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -35,
                        right: -25,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -45,
                        left: -20,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            isLeader
                                ? '👑 Project Leader · ${members.length} Anggota'
                                : '👤 Member · ${myMember?.role ?? "Anggota Tim"}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (!state.isRealJwt)
                          GestureDetector(
                            onTap: () => ref.read(teamlyProvider.notifier).toggleSimulatedRole(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'Ganti Role',
                                style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                          )
                        else if (project.deadline != null && project.deadline!.isNotEmpty)
                          Text(
                            'Deadline: ${project.deadline}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLeader
                                    ? project.name
                                    : 'Halo, ${state.user?.name ?? myMember?.name ?? "Member"}!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                isLeader
                                    ? (project.description.isNotEmpty
                                        ? project.description
                                        : 'Pantau seluruh progres tim dan kelola pembagian tugas.')
                                    : 'Project: ${project.name} · ${allProjectTasks.length} total tugas tim',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const TeamlyHeroIllustration(size: 76, onDark: true),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isLeader ? 'Progres Keseluruhan Tim' : 'Progres Tugas Saya',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.28),
                        color: Colors.white,
                      ),
                    ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (isLeader) ...[
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Total Tugas Tim',
                        value: '${tasks.length}',
                        sub: '$todoCount belum mulai',
                        icon: Icons.list_alt_rounded,
                        color: AppTheme.indigo,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Sedang Berjalan',
                        value: '$activeCount',
                        sub: '$doneCount selesai',
                        icon: Icons.timelapse_rounded,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Prioritas Tinggi',
                        value: '$highCount',
                        sub: 'Perlu perhatian',
                        icon: Icons.flag_rounded,
                        color: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Terlambat',
                        value: '$overdueCount',
                        sub: overdueCount > 0 ? 'Lewat tenggat!' : 'Semua aman',
                        icon: Icons.warning_amber_rounded,
                        color: overdueCount > 0 ? AppTheme.danger : AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Tugas Saya',
                        value: '${tasks.length}',
                        sub: '$todoCount belum mulai',
                        icon: Icons.assignment_ind_rounded,
                        color: AppTheme.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Dikerjakan',
                        value: '$activeCount',
                        sub: '$reviewCount menunggu review',
                        icon: Icons.timelapse_rounded,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Selesai',
                        value: '$doneCount',
                        sub: 'Tugas tuntas',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Terlambat',
                        value: '$overdueCount',
                        sub: overdueCount > 0 ? 'Segera selesaikan' : 'Tepat waktu',
                        icon: Icons.warning_amber_rounded,
                        color: overdueCount > 0 ? AppTheme.danger : AppTheme.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('Aksi Cepat Tugas Saya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (tasks.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: const Text(
                      'Belum ada tugas yang ditugaskan kepada Anda.',
                      style: TextStyle(color: AppTheme.muted, fontSize: 13),
                    ),
                  )
                else
                  ...tasks.take(5).map((t) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    TeamlyNotifier.statusLabel(t.status),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryDark),
                                  ),
                                ),
                              ],
                            ),
                            if (t.deadline != null && t.deadline!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Deadline: ${t.deadline}', style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (t.status != 'doing')
                                  ActionChip(
                                    label: const Text('Kerjakan', style: TextStyle(fontSize: 11.5)),
                                    onPressed: () => ref.read(teamlyProvider.notifier).changeTaskStatus(t, 'doing'),
                                  ),
                                if (t.status != 'review')
                                  ActionChip(
                                    label: const Text('Review', style: TextStyle(fontSize: 11.5)),
                                    onPressed: () => ref.read(teamlyProvider.notifier).changeTaskStatus(t, 'review'),
                                  ),
                                if (t.status != 'done')
                                  ActionChip(
                                    label: const Text('Selesai', style: TextStyle(fontSize: 11.5)),
                                    onPressed: () => ref.read(teamlyProvider.notifier).changeTaskStatus(t, 'done'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      )),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onNavigateTab(2),
                      icon: const Icon(Icons.view_kanban_outlined, size: 18),
                      label: const Text('Buka Kanban'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.ink,
                        side: const BorderSide(color: AppTheme.borderStrong),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onNavigateTab(3),
                      icon: const Icon(Icons.groups_outlined, size: 18),
                      label: const Text('Anggota Tim'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryDark,
                        side: const BorderSide(color: AppTheme.primaryBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tenggat Terdekat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  TextButton(onPressed: () => onNavigateTab(2), child: const Text('Lihat semua')),
                ],
              ),
              if (upcoming.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: const Text(
                    'Belum ada tugas dengan tenggat waktu terdekat.',
                    style: TextStyle(color: AppTheme.muted, fontSize: 13),
                  ),
                )
              else
                ...upcoming.take(4).map((t) => _UpcomingTaskTile(task: t, onTap: () => onNavigateTab(2))),
            ],
          ],
        ),
      ),
    );
  }

  void _showProjectSwitcher(BuildContext context, WidgetRef ref) {
    final state = ref.read(teamlyProvider);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pilih Project', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCreateProjectDialog(context, ref);
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Buat Baru'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.projects.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text('Belum ada project.', style: TextStyle(color: AppTheme.muted)),
              )
            else
              ...state.projects.map((p) {
                final active = p.id == state.currentProject?.id;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    active ? Icons.check_circle_rounded : Icons.folder_outlined,
                    color: active ? AppTheme.primary : AppTheme.muted,
                  ),
                  title: Text(p.name, style: TextStyle(fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
                  subtitle: p.description.isNotEmpty
                      ? Text(p.description, maxLines: 1, overflow: TextOverflow.ellipsis)
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                    onPressed: () async {
                      if (!ensureAuthenticated(context, ref, 'menghapus project')) return;
                      Navigator.pop(ctx);
                      await ref.read(teamlyProvider.notifier).deleteProject(p.id);
                    },
                  ),
                  onTap: () {
                    ref.read(teamlyProvider.notifier).selectProject(p.id);
                    Navigator.pop(ctx);
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context, WidgetRef ref) {
    if (!ensureAuthenticated(context, ref, 'membuat project baru')) return;
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final deadlineCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Buat Project Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Project', hintText: 'Contoh: Aplikasi Kasir UMKM'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Deskripsi Singkat'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: deadlineCtrl,
              decoration: const InputDecoration(labelText: 'Deadline (YYYY-MM-DD)', hintText: '2026-12-20'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await ref.read(teamlyProvider.notifier).createProject(
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      deadline: deadlineCtrl.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan Project', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context, WidgetRef ref) {
    final state = ref.read(teamlyProvider);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notifikasi Aktivitas', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: () {
                    ref.read(teamlyProvider.notifier).markAllNotificationsRead();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Tandai dibaca'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: state.notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (_, idx) {
                  final n = state.notifications[idx];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: n.unread ? AppTheme.primarySubtle : AppTheme.canvas,
                      child: Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                        color: n.unread ? AppTheme.primaryDark : AppTheme.muted,
                      ),
                    ),
                    title: Text(n.taskTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    subtitle: Text('${n.action}\n${n.time}', style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                    isThreeLine: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountMenu(BuildContext context, WidgetRef ref) {
    final state = ref.read(teamlyProvider);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              state.isGuest ? 'Mode Guest (Demo)' : state.user!.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              state.isGuest ? 'Masuk untuk menyinkronkan data ke backend' : state.user!.email,
              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            if (state.isGuest)
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/auth?mode=login');
                },
                style: FilledButton.styleFrom(backgroundColor: AppTheme.primary, minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Masuk / Daftar Akun'),
              )
            else
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(teamlyProvider.notifier).logout();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Berhasil keluar dari akun.')),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar dari Akun'),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWorkspaceCard extends StatelessWidget {
  const _EmptyWorkspaceCard({
    required this.onFindIdea,
    required this.onCreateProject,
    required this.onLoadDemo,
  });

  final VoidCallback onFindIdea;
  final VoidCallback onCreateProject;
  final VoidCallback onLoadDemo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          const TeamlyHeroIllustration(size: 108, onDark: false),
          const SizedBox(height: 12),
          const Text(
            'Mulai Project Tugas Kuliahmu',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bingung mulai dari mana? Gunakan Survey Ide AI untuk mendapatkan 3 rekomendasi konsep + daftar tugas otomatis.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.muted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onFindIdea,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.lightbulb_outline_rounded),
              label: const Text('Temukan Ide Project AI', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCreateProject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.ink,
                    side: const BorderSide(color: AppTheme.borderStrong),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Buat Manual'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onLoadDemo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryDark,
                    side: const BorderSide(color: AppTheme.primaryBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Muat Data Demo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, color.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
          Text(sub, style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _UpcomingTaskTile extends StatelessWidget {
  const _UpcomingTaskTile({required this.task, required this.onTap});
  final TaskModel task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: AppTheme.primaryLight,
          child: Icon(Icons.event_note_rounded, color: AppTheme.primary, size: 18),
        ),
        title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        subtitle: Text('${task.assigneeName} · Deadline ${task.deadline}', style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
      ),
    );
  }
}
