import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/teamly_provider.dart';
import '../../../core/theme/app_theme.dart';

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  static const _quickPrompts = [
    'Analisis prioritas & risiko deadline',
    'Rekomendasi pembagian bab laporan kuliah',
    'Evaluasi beban kerja anggota tim',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);
    try {
      await ref.read(teamlyProvider.notifier).sendAiMessage(text);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamlyProvider);
    final messages = state.chatMessages;
    final project = state.currentProject;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.primarySubtle,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryDark, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Teamly AI Coach', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(
                    project != null ? 'Konteks: ${project.name}' : 'Asisten Pembimbing Tugas Kuliah',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.auto_awesome_rounded, size: 32, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Konsultasi Project dengan AI',
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tanyakan strategi pengerjaan, pembagian bab laporan, atau solusi kendala teknis tim Anda.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.muted, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: _quickPrompts
                                .map((p) => ActionChip(
                                      label: Text(p, style: const TextStyle(fontSize: 12)),
                                      backgroundColor: AppTheme.surface,
                                      side: const BorderSide(color: AppTheme.primaryBorder),
                                      onPressed: () => _send(p),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, idx) {
                      final m = messages[idx];
                      return Align(
                        alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: m.isUser ? AppTheme.primary : AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: m.isUser ? null : Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Text(
                            m.text,
                            style: TextStyle(
                              color: m.isUser ? Colors.white : AppTheme.ink,
                              fontSize: 13.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_sending)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('Teamly AI sedang menganalisis...', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: _send,
                      decoration: const InputDecoration(hintText: 'Tanya Teamly AI...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: AppTheme.primary),
                    onPressed: _sending ? null : () => _send(_controller.text),
                    icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
