// STUDENT GRADE TRACKER

// Function untuk menentukan grade
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

// Function untuk menentukan status kelulusan
String tentukanStatus(double nilai, double kehadiran) {
  if (nilai >= 50 && kehadiran >= 75) {
    return "LULUS";
  } else {
    return "TIDAK LULUS";
  }
}

void main() {
  // Data mahasiswa
  List<Map<String, dynamic>> mahasiswa = [
    {"nama": "Nahdah", "nilai": 88.0, "kehadiran": 90.0},
    {"nama": "Chiko", "nilai": 76.0, "kehadiran": 80.0},
    {"nama": "Nue", "nilai": 64.0, "kehadiran": 85.0},
    {"nama": "Naufal", "nilai": 45.0, "kehadiran": 70.0},
  ];

  print("=== STUDENT GRADE TRACKER ===");

  // Loop untuk memproses setiap mahasiswa
  for (var data in mahasiswa) {
    String nama = data["nama"];
    double nilai = data["nilai"];
    double kehadiran = data["kehadiran"];

    // Memanggil function
    String grade = tentukanGrade(nilai);
    String status = tentukanStatus(nilai, kehadiran);

    // Menampilkan hasil
    print("\nNama       : $nama");
    print("Nilai      : $nilai");
    print("Kehadiran  : $kehadiran%");
    print("Grade      : $grade");
    print("Status     : $status");
    print("----------------------------");
  }
}
