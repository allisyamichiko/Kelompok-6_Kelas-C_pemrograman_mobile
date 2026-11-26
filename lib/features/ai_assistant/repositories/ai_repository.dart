import '../../../core/network/api_client.dart';
import '../../../shared/models/teamly_models.dart';

class AiRepository {
  AiRepository(this._client);
  final ApiClient _client;

  Future<Map<String, dynamic>> chat({
    required int projectId,
    required String message,
  }) async {
    final response = await _client.dio.post('/api/ai/chat', data: {
      'project_id': projectId,
      'message': message,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getInsights(int projectId) async {
    final response = await _client.dio.get('/api/projects/$projectId/insights');
    return response.data as Map<String, dynamic>;
  }

  Future<List<ProjectIdeaCardModel>> generateProjectIdea({
    required String domain,
    required String courseTopic,
    required int memberCount,
    required String platform,
    required String difficulty,
    String problem = '',
  }) async {
    try {
      final response = await _client.dio.post(
        '/api/ai/generate-project-idea',
        data: {
          'domain': domain,
          'course_topic': courseTopic,
          'member_count': memberCount,
          'target_platform': platform,
          'difficulty': difficulty,
          'problem': problem,
        },
      );
      final data = response.data;
      if (data is Map && data['ideas'] is List && (data['ideas'] as List).isNotEmpty) {
        return (data['ideas'] as List)
            .whereType<Map<String, dynamic>>()
            .map(ProjectIdeaCardModel.fromJson)
            .toList();
      }
    } catch (_) {
      // Fallback to local generator when backend is unreachable
    }
    return localGenerateIdeas(
      domain: domain,
      memberCount: memberCount,
      platform: platform,
    );
  }

  String localChatFallback(String question, ProjectModel? project, List<TaskModel> tasks) {
    final pName = project?.name ?? 'Project Tugas Kuliah';
    final total = tasks.length;
    final done = tasks.where((t) => t.status == 'done').length;
    final high = tasks.where((t) => t.priority == 'high' && t.status != 'done').length;
    return 'Analisis Teamly AI untuk $pName:\n\n'
        '• Progres saat ini: $done dari $total tugas selesai.\n'
        '• Terdapat $high tugas prioritas tinggi yang masih berjalan.\n'
        '• Prioritaskan tugas dengan tenggat terdekat dan pastikan setiap tugas memiliki penanggung jawab.\n'
        '• Lakukan check-in singkat dengan tim untuk membahas pertanyaan: "$question".';
  }

  List<ProjectIdeaCardModel> localGenerateIdeas({
    required String domain,
    required int memberCount,
    required String platform,
  }) {
    const rolePresets = [
      ['Project Lead & Fullstack Developer'],
      ['Project Lead & Frontend Developer', 'Backend & Database Engineer'],
      ['UI/UX Designer & Frontend', 'Backend & Database Engineer', 'QA Tester & Dokumentasi'],
      ['Project Manager & UI/UX', 'Frontend Developer', 'Backend & Database Engineer', 'QA & Technical Writer'],
      ['Project Lead', 'UI/UX Designer', 'Frontend Developer', 'Backend Developer', 'QA & Technical Writer'],
    ];
    final rIdx = (memberCount - 1).clamp(0, 4);
    final roles = rolePresets[rIdx];

    List<GeneratedTaskIdea> makeTasks(String pName) => [
          GeneratedTaskIdea(
            title: 'Rancang Wireframe & Alur UI/UX $pName',
            description: 'Mockup antarmuka interaktif fitur utama dan alur navigasi di Figma.',
            priority: 'high',
            estimatedHours: 6,
            role: roles[0],
          ),
          GeneratedTaskIdea(
            title: 'Rancang Skema Basis Data (ERD) & Relasi Tabel',
            description: 'Definisikan struktur entitas data, foreign key, dan skema database relasional.',
            priority: 'high',
            estimatedHours: 6,
            role: roles.length > 1 ? roles[1] : roles[0],
          ),
          GeneratedTaskIdea(
            title: 'Implementasi REST API & CRUD Fitur Utama',
            description: 'Bangun endpoint backend untuk menangani autentikasi dan logika bisnis inti.',
            priority: 'high',
            estimatedHours: 10,
            role: roles.length > 1 ? roles[1] : roles[0],
          ),
          GeneratedTaskIdea(
            title: 'Integrasi Antarmuka dengan Endpoint API',
            description: 'Hubungkan tampilan aplikasi dengan backend API secara responsif.',
            priority: 'medium',
            estimatedHours: 8,
            role: roles[0],
          ),
          GeneratedTaskIdea(
            title: 'Pengujian Sistem & Penyusunan Laporan Project',
            description: 'Uji fungsionalitas bebas error dan siapkan dokumen bab laporan tugas kuliah.',
            priority: 'medium',
            estimatedHours: 6,
            role: roles.last,
          ),
        ];

    final catalog = <String, List<ProjectIdeaCardModel>>{
      'kampus': [
        ProjectIdeaCardModel(
          id: 'kampus-1',
          name: 'KantinGo — Pre-Order & Antrean Digital Kantin Kampus',
          tagline: 'Pesan makanan tanpa antre saat jam istirahat kuliah',
          description: 'Sistem pemesanan makanan kantin kampus dengan estimasi waktu ambil dan nomor antrean digital.',
          category: 'Kampus & Akademik',
          difficulty: 'Standar Nilai A (Rekomendasi Utama)',
          targetPlatform: platform,
          bannerTheme: 'blue_campus',
          techStack: ['Flutter / React', 'FastAPI', 'PostgreSQL', 'REST API'],
          features: [
            'Katalog menu kantin & ketersediaan porsi real-time',
            'Pre-order dengan estimasi waktu penyiapan & nomor antrean',
            'Dashboard penjual untuk memproses pesanan masuk',
            'Notifikasi pesanan siap diambil via aplikasi'
          ],
          tasks: makeTasks('KantinGo'),
          roles: roles,
        ),
        ProjectIdeaCardModel(
          id: 'kampus-2',
          name: 'LabTrack — Inventaris & Peminjaman Alat Laboratorium',
          tagline: 'Kelola peminjaman fasilitas praktikum kampus anti-hilang',
          description: 'Aplikasi pengelolaan peminjaman fasilitas laboratorium kampus dengan verifikasi QR code.',
          category: 'Kampus & Akademik',
          difficulty: 'Praktis & Fokus Fitur Inti',
          targetPlatform: platform,
          bannerTheme: 'peach_reading',
          techStack: ['Flutter / React', 'FastAPI', 'SQLite', 'QR Scanner'],
          features: [
            'Katalog inventaris alat laboratorium beserta kondisinya',
            'Form peminjaman online dengan approval petugas laboran',
            'Scan QR code saat serah terima & pengembalian alat',
            'Log riwayat peminjaman dan pelaporan kerusakan'
          ],
          tasks: makeTasks('LabTrack'),
          roles: roles,
        ),
        ProjectIdeaCardModel(
          id: 'kampus-3',
          name: 'StudyBuddy — Pencari Teman Belajar & Berbagi Catatan',
          tagline: 'Belajar bareng teman satu mata kuliah makin terarah',
          description: 'Platform kolaborasi mahasiswa untuk mencari partner belajar dan berbagi ringkasan materi kuliah.',
          category: 'Kampus & Akademik',
          difficulty: 'Kreatif & Berdampak Sosial',
          targetPlatform: platform,
          bannerTheme: 'purple_cooking',
          techStack: ['Flutter / React', 'FastAPI', 'PostgreSQL'],
          features: [
            'Filter pencarian partner belajar berdasarkan mata kuliah',
            'Repositori catatan kuliah & rangkuman PDF',
            'Penjadwalan sesi belajar kelompok terjadwal',
            'Forum diskusi tanya-jawab seputar materi'
          ],
          tasks: makeTasks('StudyBuddy'),
          roles: roles,
        ),
      ],
      'bisnis': [
        ProjectIdeaCardModel(
          id: 'bisnis-1',
          name: 'KasirKu — POS & Manajemen Stok UMKM Pintar',
          tagline: 'Catat transaksi penjualan dan pantau stok menipis otomatis',
          description: 'Aplikasi Point of Sale (POS) ringan untuk UMKM lengkap dengan laporan laba harian.',
          category: 'Bisnis & UMKM',
          difficulty: 'Standar Nilai A (Rekomendasi Utama)',
          targetPlatform: platform,
          bannerTheme: 'amber_pos',
          techStack: ['Flutter / React', 'FastAPI', 'SQLite'],
          features: [
            'Input transaksi kasir cepat dengan perhitungan kembalian',
            'Manajemen stok barang dengan alert batas minimum',
            'Grafik omzet harian, mingguan, dan produk terlaris',
            'Riwayat struk digital yang dapat dicetak'
          ],
          tasks: makeTasks('KasirKu'),
          roles: roles,
        ),
        ProjectIdeaCardModel(
          id: 'bisnis-2',
          name: 'LaundryTrack — Pelacakan Cucian & Notifikasi Pelanggan',
          tagline: 'Pelanggan pantau status cucian langsung tanpa perlu tanya chat',
          description: 'Sistem manajemen operasional usaha laundry dengan pelacakan status tahap pencucian.',
          category: 'Bisnis & UMKM',
          difficulty: 'Praktis & Mudah Dipresentasikan',
          targetPlatform: platform,
          bannerTheme: 'blue_campus',
          techStack: ['Flutter / React', 'FastAPI', 'SQLite'],
          features: [
            'Pencatatan order masuk berdasarkan berat kiloan atau satuan',
            'Update progres tahap: Dicuci, Dikeringkan, Setrika, Siap Ambil',
            'Cek status cucian via kode nota unik',
            'Rekap pemasukan & daftar pelanggan setia'
          ],
          tasks: makeTasks('LaundryTrack'),
          roles: roles,
        ),
        ProjectIdeaCardModel(
          id: 'bisnis-3',
          name: 'PreOrderHub — Katalog & Manajemen Pesanan PO Toko',
          tagline: 'Rapikan rekap pesanan pre-order jualan tanpa pusing di chat',
          description: 'Platform pembuatan katalog produk pre-order dengan kuota pemesanan dan rekap otomatis.',
          category: 'Bisnis & UMKM',
          difficulty: 'Menengah & Relevan Bisnis',
          targetPlatform: platform,
          bannerTheme: 'peach_reading',
          techStack: ['Flutter / React', 'FastAPI', 'PostgreSQL'],
          features: [
            'Etalase produk PO dengan batas kuota dan tenggat tutup',
            'Form pemesanan pembeli beserta upload bukti bayar',
            'Rekap otomatis daftar pesanan untuk penjual',
            'Status pengiriman dan verifikasi pembayaran'
          ],
          tasks: makeTasks('PreOrderHub'),
          roles: roles,
        ),
      ],
    };

    final defaultList = [
      ProjectIdeaCardModel(
        id: 'gen-1',
        name: 'TeamFlow — Manajemen Proyek & Kolaborasi Tim Cerdas',
        tagline: 'Kelola tugas kelompok, progres, dan beban kerja secara adil',
        description: 'Aplikasi kolaborasi proyek untuk tim kecil dengan papan Kanban, analitik, dan asisten AI.',
        category: domain,
        difficulty: 'Standar Nilai A',
        targetPlatform: platform,
        bannerTheme: 'blue_campus',
        techStack: ['Flutter', 'FastAPI', 'PostgreSQL', 'Gemini AI'],
        features: [
          'Papan Kanban sprint dengan prioritas dan tenggat waktu',
          'Pemantauan beban kerja anggota tim secara transparan',
          'Asisten AI pembimbing proyek dan pembagian tugas',
          'Laporan progres otomatis dan log aktivitas'
        ],
        tasks: makeTasks('TeamFlow'),
        roles: roles,
      ),
      ProjectIdeaCardModel(
        id: 'gen-2',
        name: 'WargaCare — Pelaporan & Aspirasi Komunitas Terpadu',
        tagline: 'Sampaikan laporan fasilitas dan pantau tindak lanjut secara transparan',
        description: 'Platform pelaporan masalah lingkungan atau komunitas dengan pelacakan status penyelesaian.',
        category: domain,
        difficulty: 'Praktis & Berdampak',
        targetPlatform: platform,
        bannerTheme: 'emerald_eco',
        techStack: ['Flutter', 'FastAPI', 'SQLite'],
        features: [
          'Form pengaduan cepat lengkap dengan kategori & lokasi',
          'Tracking status laporan dari Diterima hingga Selesai',
          'Dashboard rekap prioritas untuk pengurus',
          'Notifikasi pembaruan status laporan'
        ],
        tasks: makeTasks('WargaCare'),
        roles: roles,
      ),
      ProjectIdeaCardModel(
        id: 'gen-3',
        name: 'KasKu — Transparansi Kas & Iuran Kelompok Digital',
        tagline: 'Catat pemasukan, pengeluaran, dan bukti bayar tanpa ribet',
        description: 'Sistem pencatatan keuangan kelompok dengan verifikasi bukti transfer dan laporan real-time.',
        category: domain,
        difficulty: 'Fokus Fitur Inti',
        targetPlatform: platform,
        bannerTheme: 'purple_cooking',
        techStack: ['Flutter', 'FastAPI', 'PostgreSQL'],
        features: [
          'Catatan transaksi masuk dan keluar yang transparan',
          'Upload bukti pembayaran iuran anggota',
          'Ringkasan saldo & tunggakan per anggota',
          'Ekspor ringkasan laporan kas bulanan'
        ],
        tasks: makeTasks('KasKu'),
        roles: roles,
      ),
    ];

    return catalog[domain] ?? defaultList;
  }
}
