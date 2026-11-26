// Student Grade Tracker

String tentukanGrade(double nilai) {
  if (nilai >= 85) {
    return "A";
  } else if (nilai >= 75) {
    return "B";
  } else if (nilai >= 65) {
    return "C";
  } else if (nilai >= 50) {
    return "D";
  } else {
    return "E";
  }
}

String tentukanStatus(double nilai, int kehadiran) {
  if (nilai >= 65 && kehadiran >= 75) {
    return "Lulus";
  } else {
    return "Tidak Lulus";
  }
}

void main() {
  // Data mahasiswa
  List<Map<String, dynamic>> mahasiswa = [
    {
      "nama": "Nada",
      "nilai": 88.0,
      "kehadiran": 90,
    },
    {
      "nama": "Chiko",
      "nilai": 72.0,
      "kehadiran": 80,
    },
    {
      "nama": "Revan",
      "nilai": 95.0,
      "kehadiran": 95,
    },
    {
      "nama": "Wanda",
      "nilai": 60.0,
      "kehadiran": 85,
    },
  ];

  print("=== STUDENT GRADE TRACKER ===\n");

  // Menampilkan data setiap mahasiswa
  for (var data in mahasiswa) {
    String nama = data["nama"];
    double nilai = data["nilai"];
    int kehadiran = data["kehadiran"];

    String grade = tentukanGrade(nilai);
    String status = tentukanStatus(nilai, kehadiran);

    print("Nama       : $nama");
    print("Nilai      : $nilai");
    print("Kehadiran  : $kehadiran%");
    print("Grade      : $grade");
    print("Status     : $status");
    print("----------------------------");
  }
}
