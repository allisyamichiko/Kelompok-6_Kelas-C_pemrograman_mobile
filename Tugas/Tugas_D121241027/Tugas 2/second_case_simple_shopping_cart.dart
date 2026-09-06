void main() {
  List<Map<String, dynamic>> keranjang = [
    {
      'produk': 'Makanan Kucing',
      'harga': 45000,
      'jumlah': 2,
    },
    {
      'produk': 'Pasir Kucing',
      'harga': 30000,
      'jumlah': 2,
    },
    {
      'produk': 'Mainan Kucing',
      'harga': 25000,
      'jumlah': 1,
    },
    {
      'produk': 'Tempat Makan',
      'harga': 20000,
      'jumlah': 1,
    },
    {
      'produk': 'Sisir Kucing',
      'harga': 15000,
      'jumlah': 1,
    },
  ];

  double subtotal = 0;

  for (var item in keranjang) {
    int harga = item['harga'];
    int jumlah = item['jumlah'];

    int totalProduk = harga * jumlah;
    subtotal += totalProduk;
  }

  double diskon = hitungDiskon(subtotal);

  double totalBayar = subtotal - diskon;

  print('===== SHOPPING CART KEPERLUAN KUCING =====');

  for (var item in keranjang) {
    String produk = item['produk'];
    int harga = item['harga'];
    int jumlah = item['jumlah'];

    int totalProduk = harga * jumlah;

    print('Produk      : $produk');
    print('Harga       : Rp$harga');
    print('Jumlah      : $jumlah');
    print('Total       : Rp$totalProduk');
    print('------------------------------------------');
  }

  print('Subtotal    : Rp$subtotal');
  print('Diskon      : Rp$diskon');
  print('Total Bayar : Rp$totalBayar');
}

double hitungDiskon(double subtotal) {
  if (subtotal >= 100000) {
    return subtotal * 0.10;
  } else {
    return 0;
  }
}
