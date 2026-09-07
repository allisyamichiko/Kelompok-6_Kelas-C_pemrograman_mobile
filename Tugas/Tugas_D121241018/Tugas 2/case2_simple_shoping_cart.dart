// Simple Shopping Cart

// Function untuk menghitung subtotal
double hitungSubtotal(double harga, int jumlah) {
  return harga * jumlah;
}

// Function untuk menghitung diskon
double hitungDiskon(double total) {
  if (total >= 100000) {
    return total * 0.10; // Diskon 10%
  } else {
    return 0;
  }
}

void main() {
  // Data produk
  List<Map<String, dynamic>> produk = [
    {
      "nama": "Mouse",
      "harga": 75000.0,
      "jumlah": 1,
    },
    {
      "nama": "Keyboard",
      "harga": 120000.0,
      "jumlah": 1,
    },
    {
      "nama": "Flashdisk",
      "harga": 50000.0,
      "jumlah": 2,
    },
    {
      "nama": "Headset",
      "harga": 80000.0,
      "jumlah": 1,
    },
  ];

  double subtotal = 0;

  print("=== SIMPLE SHOPPING CART ===\n");

  // Loop untuk menampilkan produk dan menghitung subtotal
  for (var item in produk) {
    String nama = item["nama"];
    double harga = item["harga"];
    int jumlah = item["jumlah"];

    double totalProduk = hitungSubtotal(harga, jumlah);

    subtotal += totalProduk;

    print("Produk   : $nama");
    print("Harga    : Rp${harga.toStringAsFixed(0)}");
    print("Jumlah   : $jumlah");
    print("Subtotal : Rp${totalProduk.toStringAsFixed(0)}");
    print("----------------------------");
  }

  // Menghitung diskon
  double diskon = hitungDiskon(subtotal);

  // Menghitung total pembayaran
  double totalPembayaran = subtotal - diskon;

  print("\n=== RINGKASAN PEMBAYARAN ===");
  print("Subtotal : Rp${subtotal.toStringAsFixed(0)}");

  if (diskon > 0) {
    print("Diskon   : 10%");
    print("Potongan : Rp${diskon.toStringAsFixed(0)}");
  } else {
    print("Diskon   : Tidak mendapatkan diskon");
  }

  print("Total    : Rp${totalPembayaran.toStringAsFixed(0)}");
}
