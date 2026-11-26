import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/teamly_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/teamly_models.dart';
import '../../dashboard/screens/main_shell.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  static const _palette = [
    ('#6366F1', 'Indigo'),
    ('#059669', 'Emerald'),
    ('#D97706', 'Amber'),
    ('#0284C7', 'Blue'),
    ('#8B5CF6', 'Purple'),
    ('#EC4899', 'Pink'),
  ];

  Color _parseHex(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.tryParse('FF$clean', radix: 16) ?? 0xFFF97316);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teamlyProvider);
    final project = state.currentProject;
    final members = state.currentMembers;
    final tasks = state.currentTasks;

    final scheduledTasks = tasks.where((t) => t.timeSlot.isNotEmpty).toList()
      ..sort((a, b) => a.timeSlot.compareTo(b.timeSlot));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggota Tim', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (project != null && state.isProjectLeader)
            IconButton(
              onPressed: () => _showAddMemberSheet(context, ref),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              tooltip: 'Tambah Anggota',
            ),
        ],
      ),
      body: project == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Pilih atau buat project terlebih dahulu untuk mengelola tim.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.muted)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Anggota ${project.name}', style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
                const SizedBox(height: 12),
                if (members.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: const Text('Belum ada anggota di project ini. Ketuk ikon + di kanan atas untuk menambah anggota.'),
                  )
                else
                  ...members.map((m) {
                    final activeTasks = tasks.where((t) => t.assigneeId == m.id && t.status != 'done').toList();
                    final totalHours = activeTasks.fold<double>(0, (sum, t) => sum + t.estimatedHours);
                    final avatarColor = _parseHex(m.colorHex);
                    final workloadRatio = (totalHours / 20).clamp(0.0, 1.0);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: avatarColor.withValues(alpha: 0.14),
                                child: Text(
                                  m.initials,
                                  style: TextStyle(color: avatarColor, fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                                    Text('${m.role} · ${m.email}', style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                                  ],
                                ),
                              ),
                              if (state.isProjectLeader)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.muted, size: 20),
                                  onPressed: () {
                                    if (!ensureAuthenticated(context, ref, 'menghapus anggota tim')) return;
                                    ref.read(teamlyProvider.notifier).removeMember(m);
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Beban Kerja: ${activeTasks.length} tugas aktif',
                                style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                              ),
                              Text(
                                '${totalHours.toStringAsFixed(0)} jam',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: workloadRatio,
                              minHeight: 6,
                              backgroundColor: AppTheme.canvas,
                              color: workloadRatio > 0.8 ? AppTheme.danger : AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 20),
                const Text('Timeline Tugas Harian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (scheduledTasks.isEmpty)
                  const Text('Belum ada jadwal tugas harian.', style: TextStyle(color: AppTheme.muted, fontSize: 13))
                else
                  ...scheduledTasks.map((t) => _TimelineRow(task: t)),
              ],
            ),
    );
  }

  void _showAddMemberSheet(BuildContext context, WidgetRef ref) {
    if (!ensureAuthenticated(context, ref, 'menambah anggota tim')) return;
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Anggota Tim');
    final emailCtrl = TextEditingController();
    String selectedColor = _palette.first.$1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tambah Anggota Tim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
              const SizedBox(height: 10),
              TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Peran / Role')),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', hintText: 'nama@kampus.ac.id'),
              ),
              const SizedBox(height: 12),
              const Text('Warna Avatar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _palette.map((c) {
                  final color = _parseHex(c.$1);
                  final active = selectedColor == c.$1;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedColor = c.$1),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: color,
                      child: active ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
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
                  final name = nameCtrl.text.trim();
                  final email = emailCtrl.text.trim().isNotEmpty
                      ? emailCtrl.text.trim()
                      : '${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}@kampus.ac.id';
                  await ref.read(teamlyProvider.notifier).addMember(
                        name: name,
                        email: email,
                        role: roleCtrl.text.trim().isEmpty ? 'Anggota Tim' : roleCtrl.text.trim(),
                        colorHex: selectedColor,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Simpan Anggota', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.task});
  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              task.timeSlot,
              style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                Text('${task.assigneeName} · ${TeamlyNotifier.statusLabel(task.status)}', style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
