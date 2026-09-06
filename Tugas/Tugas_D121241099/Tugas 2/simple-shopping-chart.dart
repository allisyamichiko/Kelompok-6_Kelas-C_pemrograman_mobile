// SIMPLE SHOPPING CART

// Function untuk menghitung subtotal
double hitungSubtotal(double harga, int jumlah) {
  return harga * jumlah;
}

// Function untuk menentukan jumlah diskon
double hitungDiskon(double total) {
  if (total >= 500000) {
    return total * 0.10;
  } else if (total >= 300000) {
    return total * 0.05;
  } else {
    return 0;
  }
}

void main() {

  // Data produk
  List<Map<String, dynamic>> produk = [
    {
      "nama": "Laptop",
      "harga": 7500000.0,
      "jumlah": 1,
    },
    {
      "nama": "Mouse",
      "harga": 150000.0,
      "jumlah": 2,
    },
    {
      "nama": "Keyboard",
      "harga": 350000.0,
      "jumlah": 1,
    },
  ];

  double total = 0;

  print("=== SIMPLE SHOPPING CART ===");

  // Loop untuk setiap produk
  for (var item in produk) {

    String nama = item["nama"];
    double harga = item["harga"];
    int jumlah = item["jumlah"];

    // Menghitung subtotal
    double subtotal = hitungSubtotal(harga, jumlah);

    // Menambahkan subtotal ke total
    total += subtotal;

    print("\nProduk   : $nama");
    print("Harga    : Rp${harga.toStringAsFixed(0)}");
    print("Jumlah   : $jumlah");
    print("Subtotal : Rp${subtotal.toStringAsFixed(0)}");
  }

  // Menghitung diskon
  double diskon = hitungDiskon(total);

  // Menghitung total pembayaran
  double totalBayar = total - diskon;

  print("\n=== RINGKASAN PEMBAYARAN ===");
  print("Total Belanja : Rp${total.toStringAsFixed(0)}");
  print("Diskon        : Rp${diskon.toStringAsFixed(0)}");
  print("Total Bayar   : Rp${totalBayar.toStringAsFixed(0)}");
}