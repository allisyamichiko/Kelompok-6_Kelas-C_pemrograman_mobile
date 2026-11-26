import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/teamly_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/teamly_models.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/teamly_illustrations.dart';
import '../../dashboard/screens/main_shell.dart';

class IdeaGeneratorScreen extends ConsumerStatefulWidget {
  const IdeaGeneratorScreen({super.key, required this.onProjectCreated});
  final VoidCallback onProjectCreated;

  @override
  ConsumerState<IdeaGeneratorScreen> createState() => _IdeaGeneratorScreenState();
}

class _IdeaGeneratorScreenState extends ConsumerState<IdeaGeneratorScreen> {
  int _step = 0; // 0 = Intro, 1..6 = Survey, 7 = Results
  String _domain = 'kampus';
  String _platform = 'Mobile App';
  int _teamSize = 3;
  String _duration = 'medium';
  String _difficulty = 'standard';
  String _featureFocus = 'crud';
  bool _analyzing = false;
  List<ProjectIdeaCardModel> _ideas = [];

  static const _domains = [
    ('kampus', 'Seputar Kampus & Kuliah', 'Antrean kantin, jadwal kuliah, peminjaman lab', Icons.school_rounded),
    ('bisnis', 'Bisnis & Toko Kecil', 'Kasir UMKM, katalog jualan, stok barang', Icons.storefront_rounded),
    ('lingkungan', 'Sosial & Warga', 'Bank sampah, donasi makanan, info warga', Icons.eco_rounded),
    ('lifestyle', 'Hobi & Gaya Hidup', 'Olahraga, resep anak kos, jadwal harian', Icons.fitness_center_rounded),
    ('organisasi', 'Organisasi & Komunitas', 'Iuran kas kelompok, voting, acara', Icons.handshake_rounded),
    ('produktivitas', 'Belajar & Produktivitas', 'Belajar kelompok, pengingat tugas', Icons.schedule_rounded),
  ];

  static const _platforms = [
    ('Mobile App', 'Aplikasi HP', 'Aplikasi native Android / iOS dengan Flutter'),
    ('Web App', 'Website di Browser', 'Mudah dibuka di HP dan laptop tanpa instalasi'),
    ('Sistem Informasi', 'Kasir & Pengolah Data', 'Fokus formulir input data dan laporan rapi'),
    ('AI & Smart System', 'Aplikasi Cerdas', 'Dilengkapi rekomendasi otomatis pintar'),
  ];

  static const _teamSizes = [
    (1, 'Sendiri (1 Orang)', 'Tugas perorangan mandiri'),
    (2, 'Berdua (2 Orang)', 'Bagi dua: tampilan & sistem data'),
    (3, 'Bertiga (3 Orang)', 'Tampilan, logika, dan laporan'),
    (4, 'Tim Rame-rame (4-5 Orang)', 'Tim lengkap dengan penguji & dokumentasi'),
  ];

  static const _durations = [
    ('quick', 'Cepat (< 2 Minggu)', 'Fokus fitur inti yang simpel dan cepat selesai'),
    ('medium', 'Standar (~ 1 Bulan)', 'Waktu cukup untuk tampilan rapi dan laporan'),
    ('long', 'Panjang (> 1 Bulan)', 'Leluasa membuat fitur lengkap untuk portofolio'),
  ];

  static const _difficulties = [
    ('easy', 'Mudah & Ramah Pemula', 'Alur simpel dan kode tidak rumit dipahami'),
    ('standard', 'Standar Tugas Kuliah', 'Pas untuk target nilai bagus dosen'),
    ('ambitious', 'Menantang & Keren', 'Banyak fitur seru untuk portofolio'),
  ];

  static const _features = [
    ('crud', 'Pencatatan & Riwayat Data', 'Input, edit, cari, dan hapus data dengan rapi'),
    ('auth', 'Login Akun & Akses Pengguna', 'Bedakan akun Admin dan Anggota'),
    ('notif', 'Pengingat & Notifikasi', 'Pengingat otomatis batas waktu atau perubahan tugas'),
    ('report', 'Ringkasan & Laporan Visual', 'Grafik visual dan rangkuman data otomatis'),
  ];

  Future<void> _runAnalysis() async {
    setState(() => _analyzing = true);
    try {
      final ideas = await ref.read(aiRepositoryProvider).generateProjectIdea(
            domain: _domain,
            courseTopic: _platform,
            memberCount: _teamSize,
            platform: _platform,
            difficulty: _difficulty,
            problem: 'Fokus fitur: $_featureFocus, durasi: $_duration',
          );
      if (mounted) {
        setState(() {
          _ideas = ideas;
          _step = 7;
        });
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _selectIdea(ProjectIdeaCardModel idea) async {
    if (!ensureAuthenticated(context, ref, 'menerapkan ide project AI')) return;
    await ref.read(teamlyProvider.notifier).applyIdeaAsProject(idea);
    if (!mounted) return;
    setState(() => _step = 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Project "${idea.name}" dibuat! Anda adalah Project Leader.')),
    );
    widget.onProjectCreated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temukan Ide', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (_step > 0 && _step < 7)
            TextButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('Batal'),
            ),
          if (_step == 7)
            TextButton.icon(
              onPressed: () => setState(() => _step = 0),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Ulangi'),
            ),
        ],
      ),
      body: _step == 0
          ? _buildIntro()
          : (_step <= 6 ? _buildSurvey() : _buildResults()),
    );
  }

  Widget _buildIntro() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            children: [
              TeamlyHeroIllustration(size: 112, onDark: true),
              SizedBox(height: 16),
              Text(
                'Bingung Mau Buat Project Apa?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Jawab 6 pertanyaan singkat untuk mendapatkan 3 rekomendasi ide project lengkap dengan fitur, tech stack, dan daftar tugas awal.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Cara Kerja', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        const _IntroStepTile(
          stepNumber: '1',
          title: 'Pilih Minat & Platform',
          subtitle: 'Tentukan bidang masalah, platform aplikasi, dan ukuran tim.',
          icon: Icons.tune_rounded,
        ),
        const _IntroStepTile(
          stepNumber: '2',
          title: 'Dapatkan 3 Rekomendasi Konsep',
          subtitle: 'Sistem merumuskan konsep project yang realistis dan siap dikerjakan.',
          icon: Icons.lightbulb_outline_rounded,
        ),
        const _IntroStepTile(
          stepNumber: '3',
          title: 'Otomatis Jadi Workspace',
          subtitle: 'Anda langsung menjadi Project Leader dan daftar tugas sprint siap dikelola.',
          icon: Icons.rocket_launch_rounded,
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Mulai Survey Ide',
          onPressed: () => setState(() => _step = 1),
        ),
      ],
    );
  }

  Widget _buildSurvey() {
    final stepTitles = [
      'Bidang apa yang paling menarik untuk kelompokmu?',
      'Platform apa yang ingin kalian buat?',
      'Berapa jumlah anggota tim kalian?',
      'Berapa lama waktu pengerjaan yang tersedia?',
      'Tingkat kesulitan seperti apa yang diinginkan?',
      'Fitur utama apa yang ingin ditonjolkan?',
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Langkah $_step dari 6',
                    style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  Text('${((_step / 6) * 100).round()}%', style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: _step / 6,
                  minHeight: 6,
                  backgroundColor: AppTheme.primarySubtle,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                stepTitles[_step - 1],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: _buildStepOptions(),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                if (_step > 1)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step--),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: AppTheme.borderStrong),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Sebelumnya'),
                    ),
                  ),
                if (_step > 1) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _analyzing
                        ? null
                        : () {
                            if (_step < 6) {
                              setState(() => _step++);
                            } else {
                              _runAnalysis();
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _analyzing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _step < 6 ? 'Selanjutnya' : '✨ Temukan Rekomendasi Ide',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStepOptions() {
    switch (_step) {
      case 1:
        return _domains
            .map((d) => _OptionCard(
                  title: d.$2,
                  subtitle: d.$3,
                  icon: d.$4,
                  selected: _domain == d.$1,
                  onTap: () => setState(() => _domain = d.$1),
                ))
            .toList();
      case 2:
        return _platforms
            .map((p) => _OptionCard(
                  title: p.$2,
                  subtitle: p.$3,
                  icon: Icons.devices_rounded,
                  selected: _platform == p.$1,
                  onTap: () => setState(() => _platform = p.$1),
                ))
            .toList();
      case 3:
        return _teamSizes
            .map((t) => _OptionCard(
                  title: t.$2,
                  subtitle: t.$3,
                  icon: Icons.groups_rounded,
                  selected: _teamSize == t.$1,
                  onTap: () => setState(() => _teamSize = t.$1),
                ))
            .toList();
      case 4:
        return _durations
            .map((d) => _OptionCard(
                  title: d.$2,
                  subtitle: d.$3,
                  icon: Icons.timer_outlined,
                  selected: _duration == d.$1,
                  onTap: () => setState(() => _duration = d.$1),
                ))
            .toList();
      case 5:
        return _difficulties
            .map((d) => _OptionCard(
                  title: d.$2,
                  subtitle: d.$3,
                  icon: Icons.trending_up_rounded,
                  selected: _difficulty == d.$1,
                  onTap: () => setState(() => _difficulty = d.$1),
                ))
            .toList();
      default:
        return _features
            .map((f) => _OptionCard(
                  title: f.$2,
                  subtitle: f.$3,
                  icon: Icons.auto_awesome_outlined,
                  selected: _featureFocus == f.$1,
                  onTap: () => setState(() => _featureFocus = f.$1),
                ))
            .toList();
    }
  }

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ideas.length + 1,
      itemBuilder: (context, idx) {
        if (idx == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎯 3 Rekomendasi Ide Project', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text(
                  'Pilih ide terbaik untuk otomatis membuat workspace dan daftar tugas sprint.',
                  style: TextStyle(color: AppTheme.muted, fontSize: 13),
                ),
              ],
            ),
          );
        }
        final idea = _ideas[idx - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: idx == 1
                        ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                        : idx == 2
                            ? [const Color(0xFFF97316), const Color(0xFFEA580C)]
                            : [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(idea.category, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            idea.difficulty,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(idea.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(idea.tagline, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(idea.description, style: const TextStyle(fontSize: 13, height: 1.45)),
                    const SizedBox(height: 12),
                    const Text('Fitur Utama:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    ...idea.features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.success),
                            const SizedBox(width: 8),
                            Expanded(child: Text(f, style: const TextStyle(fontSize: 12.5))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: idea.techStack
                          .map((t) => Chip(
                                label: Text(t, style: const TextStyle(fontSize: 11.5)),
                                backgroundColor: AppTheme.canvas,
                                side: const BorderSide(color: AppTheme.borderSubtle),
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _selectIdea(idea),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                        label: const Text('Pilih Ide Ini & Buka Workspace', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryLight : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.borderSubtle,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : AppTheme.canvas,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: selected ? Colors.white : AppTheme.muted, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppTheme.primary : AppTheme.subtle,
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroStepTile extends StatelessWidget {
  const _IntroStepTile({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String stepNumber;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
              ],
            ),
          ),
          Icon(icon, color: AppTheme.primary, size: 20),
        ],
      ),
    );
  }
}
