import 'package:vegetables_app/model/vegetable_model/vegetable_detail_model.dart';
import 'package:vegetables_app/model/vegetable_model/vegetable_model.dart';

/// Sayuran lokal dengan gambar dari folder assets/images.
/// Dipakai sebagai pelengkap data dari API agar tetap tampil saat offline.
class LocalVegetables {
  LocalVegetables._();

  static final List<VegetableModel> items = [
    VegetableModel(
      id: 9001,
      nama: 'Kacang Panjang',
      kategori: 'Sayuran Polong',
      harga: 8000,
      gambar: 'assets/images/kacang panjang.jpg',
      deskripsi: 'Kacang panjang segar dan renyah',
    ),
    VegetableModel(
      id: 9002,
      nama: 'Terong Ungu',
      kategori: 'Sayuran Buah',
      harga: 12000,
      gambar: 'assets/images/terong ungu.webp',
      deskripsi: 'Terong ungu muda dengan tekstur lembut',
    ),
    VegetableModel(
      id: 9003,
      nama: 'Sawi Hijau',
      kategori: 'Sayuran Daun',
      harga: 6000,
      gambar: 'assets/images/sawi hijau.webp',
      deskripsi: 'Sawi hijau segar kaya serat',
    ),
    VegetableModel(
      id: 9004,
      nama: 'Kangkung',
      kategori: 'Sayuran Daun',
      harga: 5000,
      gambar: 'assets/images/kangkung.jpg',
      deskripsi: 'Kangkung segar siap tumis',
    ),
  ];

  static List<VegetableModel> filter({String? kategori, String? cari}) {
    final query = cari?.trim().toLowerCase() ?? '';

    return items.where((item) {
      final matchKategori =
          kategori == null ||
          item.kategori.toLowerCase() == kategori.toLowerCase();
      final matchCari =
          query.isEmpty ||
          item.nama.toLowerCase().contains(query) ||
          item.deskripsi.toLowerCase().contains(query);

      return matchKategori && matchCari;
    }).toList();
  }

  static VegetableDetailModel? detailFor(int id) {
    VegetableModel? item;
    for (final vegetable in items) {
      if (vegetable.id == id) {
        item = vegetable;
        break;
      }
    }

    if (item == null) return null;

    return VegetableDetailModel(
      id: item.id,
      nama: item.nama,
      kategori: item.kategori,
      harga: item.harga,
      gambar: item.gambar,
      deskripsi: item.deskripsi,
      manfaat: const [
        'Kaya serat dan vitamin untuk tubuh',
        'Membantu menjaga pencernaan tetap sehat',
      ],
      tipsPenyimpanan:
          'Simpan di wadah tertutup pada suhu dingin dan cuci sebelum dimasak.',
      asal: 'Petani mitra GoVeg',
      nutrisi: NutrisiModel(
        kalori: '25 kkal',
        karbohidrat: '5 g',
        protein: '2 g',
        serat: '3 g',
      ),
    );
  }
}
