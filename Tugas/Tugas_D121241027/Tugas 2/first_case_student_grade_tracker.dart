void main() {
  List<Map<String, dynamic>> mahasiswa = [
    {
      'nama': 'Lincoln',
      'nilai': 90,
      'kehadiran': 95,
    },
    {
      'nama': 'Lori',
      'nilai': 78,
      'kehadiran': 85,
    },
    {
      'nama': 'Leni',
      'nilai': 68,
      'kehadiran': 80,
    },
    {
      'nama': 'Luna',
      'nilai': 55,
      'kehadiran': 90,
    },
    {
      'nama': 'Luan',
      'nilai': 45,
      'kehadiran': 60,
    },
  ];

  for (var data in mahasiswa) {
    String nama = data['nama'];
    int nilai = data['nilai'];
    int kehadiran = data['kehadiran'];

    String grade = tentukanGrade(nilai);
    String status = tentukanStatus(nilai, kehadiran);

    print('==============================');
    print('Nama       : $nama');
    print('Nilai      : $nilai');
    print('Kehadiran  : $kehadiran%');
    print('Grade      : $grade');
    print('Status     : $status');
  }

  print('==============================');
}

String tentukanGrade(int nilai) {
  if (nilai >= 85) {
    return 'A';
  } else if (nilai >= 75) {
    return 'B';
  } else if (nilai >= 65) {
    return 'C';
  } else if (nilai >= 50) {
    return 'D';
  } else {
    return 'E';
  }
}

String tentukanStatus(int nilai, int kehadiran) {
  if (nilai >= 65 && kehadiran >= 75) {
    return 'Lulus';
  } else {
    return 'Tidak Lulus';
  }
}
