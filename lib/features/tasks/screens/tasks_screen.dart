import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/teamly_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/teamly_models.dart';
import '../../../shared/widgets/teamly_illustrations.dart';
import '../../dashboard/screens/main_shell.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _viewMode = 'board'; // 'board' | 'list'
  String _search = '';
  String _priorityFilter = 'all';
  String _selectedKanbanStatus = 'todo';

  static const _statuses = [
    ('todo', 'Belum Mulai', Color(0xFF64748B)),
    ('doing', 'Dikerjakan', Color(0xFFF97316)),
    ('review', 'Review', Color(0xFF8B5CF6)),
    ('done', 'Selesai', Color(0xFF059669)),
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamlyProvider);
    final project = state.currentProject;
    final allTasks = state.currentTasks;

    final filtered = allTasks.where((t) {
      final q = _search.trim().toLowerCase();
      final matchQ = q.isEmpty ||
          t.title.toLowerCase().contains(q) ||
          t.assigneeName.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q);
      final matchPrio = _priorityFilter == 'all' || t.priority == _priorityFilter;
      return matchQ && matchPrio;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Papan Tugas', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'board', icon: Icon(Icons.view_kanban_outlined, size: 16), label: Text('Kanban')),
                ButtonSegment(value: 'list', icon: Icon(Icons.list_rounded, size: 16), label: Text('Daftar')),
              ],
              selected: {_viewMode},
              onSelectionChanged: (v) => setState(() => _viewMode = v.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: (project == null || !state.isProjectLeader)
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              onPressed: () => _showAddTaskSheet(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Tugas', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
      body: project == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada project aktif. Buat project atau gunakan Temukan Ide AI terlebih dahulu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.muted),
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (v) => setState(() => _search = v),
                        decoration: const InputDecoration(
                          hintText: 'Cari tugas, kategori, atau anggota...',
                          prefixIcon: Icon(Icons.search_rounded, size: 20),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _FilterChip(
                              label: 'Semua',
                              selected: _priorityFilter == 'all',
                              onTap: () => setState(() => _priorityFilter = 'all'),
                            ),
                            _FilterChip(
                              label: 'Prioritas Tinggi',
                              selected: _priorityFilter == 'high',
                              onTap: () => setState(() => _priorityFilter = 'high'),
                            ),
                            _FilterChip(
                              label: 'Medium',
                              selected: _priorityFilter == 'medium',
                              onTap: () => setState(() => _priorityFilter = 'medium'),
                            ),
                            _FilterChip(
                              label: 'Rendah',
                              selected: _priorityFilter == 'low',
                              onTap: () => setState(() => _priorityFilter = 'low'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_viewMode == 'board') ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _statuses.map((s) {
                          final count = filtered.where((t) => t.status == s.$1).length;
                          final active = _selectedKanbanStatus == s.$1;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              selected: active,
                              selectedColor: AppTheme.primarySubtle,
                              label: Text('${s.$2} ($count)', style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
                              onSelected: (_) => setState(() => _selectedKanbanStatus = s.$1),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildTaskList(
                      filtered.where((t) => t.status == _selectedKanbanStatus).toList(),
                      emptyText: 'Tidak ada tugas di kolom ${TeamlyNotifier.statusLabel(_selectedKanbanStatus)}.',
                    ),
                  ),
                ] else
                  Expanded(
                    child: _buildTaskList(
                      filtered,
                      emptyText: 'Belum ada tugas yang sesuai filter.',
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildTaskList(List<TaskModel> tasks, {required String emptyText}) {
    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TeamlyEmptyTaskIllustration(size: 108),
              const SizedBox(height: 12),
              Text(emptyText, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
      itemCount: tasks.length,
      itemBuilder: (context, idx) {
        final task = tasks[idx];
        return _TaskCard(
          task: task,
          onTap: () => _showTaskDetailSheet(context, ref, task),
          onMoveStatus: (dir) {
            if (!ensureAuthenticated(context, ref, 'memindahkan status tugas')) return;
            const order = ['todo', 'doing', 'review', 'done'];
            final cur = order.indexOf(task.status);
            final next = cur + dir;
            if (next >= 0 && next < order.length) {
              ref.read(teamlyProvider.notifier).changeTaskStatus(task, order[next]);
            }
          },
        );
      },
    );
  }

  void _showAddTaskSheet(BuildContext context, WidgetRef ref) {
    if (!ensureAuthenticated(context, ref, 'menambah tugas baru')) return;
    final members = ref.read(teamlyProvider).currentMembers;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final deadlineCtrl = TextEditingController();
    final hoursCtrl = TextEditingController(text: '4');
    String status = 'todo';
    String priority = 'medium';
    String category = 'Frontend';
    String timeSlot = '10.00';
    int? assigneeId = members.isNotEmpty ? members.first.id : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Tambah Tugas Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Judul Tugas'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'todo', child: Text('Belum Mulai')),
                          DropdownMenuItem(value: 'doing', child: Text('Dikerjakan')),
                          DropdownMenuItem(value: 'review', child: Text('Review')),
                          DropdownMenuItem(value: 'done', child: Text('Selesai')),
                        ],
                        onChanged: (v) => setModalState(() => status = v ?? 'todo'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: priority,
                        decoration: const InputDecoration(labelText: 'Prioritas'),
                        items: const [
                          DropdownMenuItem(value: 'high', child: Text('Tinggi')),
                          DropdownMenuItem(value: 'medium', child: Text('Sedang')),
                          DropdownMenuItem(value: 'low', child: Text('Rendah')),
                        ],
                        onChanged: (v) => setModalState(() => priority = v ?? 'medium'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(
                  initialValue: assigneeId,
                  decoration: const InputDecoration(labelText: 'Penanggung Jawab'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Belum ditentukan')),
                    ...members.map((m) => DropdownMenuItem<int?>(value: m.id, child: Text(m.name))),
                  ],
                  onChanged: (v) => setModalState(() => assigneeId = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: deadlineCtrl,
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.tryParse(deadlineCtrl.text) ?? DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            deadlineCtrl.text = picked.toIso8601String().split('T').first;
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Deadline',
                          hintText: 'Pilih tanggal',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today_outlined, size: 18),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: DateTime.tryParse(deadlineCtrl.text) ?? DateTime.now(),
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                deadlineCtrl.text = picked.toIso8601String().split('T').first;
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: hoursCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Estimasi (Jam)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    await ref.read(teamlyProvider.notifier).createTask(
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          status: status,
                          priority: priority,
                          deadline: deadlineCtrl.text.trim(),
                          estimatedHours: double.tryParse(hoursCtrl.text.trim()) ?? 4,
                          assigneeId: assigneeId,
                          category: category,
                          timeSlot: timeSlot,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Simpan Tugas', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskDetailSheet(BuildContext context, WidgetRef ref, TaskModel task) {
    ref.read(teamlyProvider.notifier).loadTaskComments(task);
    final isLeader = ref.read(teamlyProvider).isProjectLeader;
    final members = ref.read(teamlyProvider).currentMembers;
    final titleCtrl = TextEditingController(text: task.title);
    final descCtrl = TextEditingController(text: task.description);
    final deadlineCtrl = TextEditingController(text: task.deadline ?? '');
    final commentCtrl = TextEditingController();
    String status = task.status;
    String priority = task.priority;
    int? assigneeId = members.any((m) => m.id == task.assigneeId) ? task.assigneeId : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Detail & Edit Tugas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    if (isLeader)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                        onPressed: () async {
                          if (!ensureAuthenticated(context, ref, 'menghapus tugas')) return;
                          Navigator.pop(ctx);
                          await ref.read(teamlyProvider.notifier).deleteTask(task);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Tugas')),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Deskripsi')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'todo', child: Text('Belum Mulai')),
                          DropdownMenuItem(value: 'doing', child: Text('Dikerjakan')),
                          DropdownMenuItem(value: 'review', child: Text('Review')),
                          DropdownMenuItem(value: 'done', child: Text('Selesai')),
                        ],
                        onChanged: (v) => setModalState(() => status = v ?? status),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: priority,
                        decoration: const InputDecoration(labelText: 'Prioritas'),
                        items: const [
                          DropdownMenuItem(value: 'high', child: Text('Tinggi')),
                          DropdownMenuItem(value: 'medium', child: Text('Sedang')),
                          DropdownMenuItem(value: 'low', child: Text('Rendah')),
                        ],
                        onChanged: (v) => setModalState(() => priority = v ?? priority),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(
                  initialValue: assigneeId,
                  decoration: const InputDecoration(labelText: 'Penanggung Jawab'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Unassigned')),
                    ...members.map((m) => DropdownMenuItem<int?>(value: m.id, child: Text(m.name))),
                  ],
                  onChanged: isLeader ? (v) => setModalState(() => assigneeId = v) : null,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: deadlineCtrl,
                  readOnly: true,
                  onTap: !isLeader
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.tryParse(deadlineCtrl.text) ?? DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setModalState(() {
                              deadlineCtrl.text = picked.toIso8601String().split('T').first;
                            });
                          }
                        },
                  decoration: InputDecoration(
                    labelText: 'Deadline',
                    hintText: 'Pilih tanggal deadline',
                    suffixIcon: !isLeader
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (deadlineCtrl.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () => setModalState(() => deadlineCtrl.clear()),
                                ),
                              IconButton(
                                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: DateTime.tryParse(deadlineCtrl.text) ?? DateTime.now(),
                                    firstDate: DateTime(2024),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      deadlineCtrl.text = picked.toIso8601String().split('T').first;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                  ),
                ),
                if (!isLeader) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Sebagai Member, Anda dapat mengubah status tugas & mengirim feedback.',
                      style: TextStyle(fontSize: 12, color: AppTheme.primaryDark),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (!ensureAuthenticated(context, ref, 'mengedit tugas')) return;
                    MemberModel? assigned;
                    for (final m in members) {
                      if (m.id == assigneeId) assigned = m;
                    }
                    final err = await ref.read(teamlyProvider.notifier).updateTask(
                          task.copyWith(
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            status: status,
                            priority: priority,
                            deadline: deadlineCtrl.text.trim(),
                            clearDeadline: deadlineCtrl.text.trim().isEmpty,
                            assigneeId: assigneeId,
                            clearAssignee: assigneeId == null,
                            assigneeName: assigned?.name ?? 'Unassigned',
                          ),
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(err ?? 'Perubahan tugas berhasil disimpan!'),
                          backgroundColor: err != null ? AppTheme.danger : null,
                        ),
                      );
                    }
                  },
                  child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Feedback & Komentar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 8),
                if (task.comments.isEmpty)
                  const Text('Belum ada komentar.', style: TextStyle(color: AppTheme.muted, fontSize: 12.5))
                else
                  ...task.comments.map((c) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.canvas,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(c.author, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                Text(c.time, style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(c.text, style: const TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      )),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentCtrl,
                        decoration: const InputDecoration(hintText: 'Tulis feedback...', isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: AppTheme.primary),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      onPressed: () {
                        if (!ensureAuthenticated(context, ref, 'mengirim feedback tugas')) return;
                        if (commentCtrl.text.trim().isEmpty) return;
                        ref.read(teamlyProvider.notifier).addComment(task, commentCtrl.text);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        selectedColor: AppTheme.primarySubtle,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onTap, required this.onMoveStatus});
  final TaskModel task;
  final VoidCallback onTap;
  final ValueChanged<int> onMoveStatus;

  Color _prioColor() {
    switch (task.priority) {
      case 'high':
        return AppTheme.danger;
      case 'low':
        return AppTheme.success;
      default:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prioColor = _prioColor();
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: prioColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.priority.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: prioColor),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.canvas,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(task.category, style: const TextStyle(fontSize: 10.5, color: AppTheme.muted)),
                ),
                const Spacer(),
                Text('${task.estimatedHours.toStringAsFixed(0)}j', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
              ],
            ),
            const SizedBox(height: 10),
            Text(task.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.muted, fontSize: 12.5)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 15, color: AppTheme.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.assigneeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                  ),
                ),
                if (task.deadline != null && task.deadline!.isNotEmpty) ...[
                  const Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.muted),
                  const SizedBox(width: 4),
                  Text(task.deadline!, style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (task.status != 'todo')
                  TextButton.icon(
                    onPressed: () => onMoveStatus(-1),
                    icon: const Icon(Icons.arrow_back_rounded, size: 15),
                    label: const Text('Mundur', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                if (task.status != 'done')
                  TextButton.icon(
                    onPressed: () => onMoveStatus(1),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                    label: const Text('Lanjut', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryDark,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
