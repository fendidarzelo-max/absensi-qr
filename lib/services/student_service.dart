import '../models/siswa.dart';

class StudentService {
  static final StudentService _instance = StudentService._internal();
  factory StudentService() => _instance;
  StudentService._internal();

  final List<Siswa> _siswaList = [
    const Siswa(
      nisn: "009822314",
      nama: "M. Zidan Al-Fatih",
      kelas: "X-A",
      ttl: "Bandung, 15 Januari 2008",
      alamat: "Jl. Merdeka No. 10",
      namaOrtu: "Ahmad Susanto",
      namaIbu: "Siti Aminah",
      desa: "Mekar Jaya",
      kecamatan: "Cibeureum",
      kabupaten: "Bandung",
      provinsi: "Jawa Barat",
    ),
    const Siswa(
      nisn: "009822315",
      nama: "Aisyah Putri",
      kelas: "X-A",
      ttl: "Jakarta, 20 Februari 2008",
      alamat: "Jl. Sudirman No. 25",
      namaOrtu: "Budi Santoso",
      namaIbu: "Ratim",
      desa: "Menteng",
      kecamatan: "Jakarta Pusat",
      kabupaten: "Jakarta Pusat",
      provinsi: "DKI Jakarta",
    ),
    const Siswa(
      nisn: "009822316",
      nama: "Ahmad Fauzan",
      kelas: "X-B",
      ttl: "Surabaya, 10 Maret 2008",
      alamat: "Jl. Asia Afrika No. 5",
      namaOrtu: "Hendra Wijaya",
      namaIbu: "Lastri",
      desa: "Sawahan",
      kecamatan: "Wonokromo",
      kabupaten: "Surabaya",
      provinsi: "Jawa Timur",
    ),
    const Siswa(
      nisn: "009822317",
      nama: "Fatimah Az-Zahra",
      kelas: "XI-A",
      ttl: "Medan, 5 April 2007",
      alamat: "Jl. Gatot Subroto No. 15",
      namaOrtu: "Rahmat Hidayat",
      namaIbu: "Mariam",
      desa: "Padang Bulan",
      kecamatan: "Medan Selayang",
      kabupaten: "Medan",
      provinsi: "Sumatera Utara",
    ),
    const Siswa(
      nisn: "009822318",
      nama: "Umar Bin Khattab",
      kelas: "XI-B",
      ttl: "Makassar, 12 Mei 2007",
      alamat: "Jl. Pettarani No. 30",
      namaOrtu: "Andi Pratama",
      namaIbu: "Hasna",
      desa: "Bontorannu",
      kecamatan: "Makassar",
      kabupaten: "Makassar",
      provinsi: "Sulawesi Selatan",
    ),
    const Siswa(
      nisn: "009822319",
      nama: "Khadijah Al-Kubra",
      kelas: "XII-A",
      ttl: "Bandung, 8 Juni 2006",
      alamat: "Jl. Dago No. 45",
      namaOrtu: "Dedi Kurniawan",
      namaIbu: "Yanti",
      desa: "Dago",
      kecamatan: "Coblong",
      kabupaten: "Bandung",
      provinsi: "Jawa Barat",
    ),
    const Siswa(
      nisn: "009822320",
      nama: "Ali Bin Abi Thalib",
      kelas: "XII-B",
      ttl: "Semarang, 25 Juli 2006",
      alamat: "Jl. Ahmad Yani No. 60",
      namaOrtu: "Fajar Nugraha",
      namaIbu: "Dewi",
      desa: "Bendan",
      kecamatan: "Gajahmungkur",
      kabupaten: "Semarang",
      provinsi: "Jawa Tengah",
    ),
    const Siswa(
      nisn: "009822321",
      nama: "Zainab Binti Ali",
      kelas: "X-A",
      ttl: "Yogyakarta, 14 Agustus 2008",
      alamat: "Jl. Malioboro No. 20",
      namaOrtu: "Galih Permana",
      namaIbu: "Sri",
      desa: "Ngupasan",
      kecamatan: "Gondokusuman",
      kabupaten: "Yogyakarta",
      provinsi: "Yogyakarta",
    ),
    const Siswa(
      nisn: "009822322",
      nama: "Bilal Bin Rabah",
      kelas: "X-B",
      ttl: "Denpasar, 30 September 2008",
      alamat: "Jl. Ngurah Rai No. 8",
      namaOrtu: "Made Surya",
      namaIbu: "Ketut",
      desa: "Denpasar",
      kecamatan: "Denpasar Barat",
      kabupaten: "Denpasar",
      provinsi: "Bali",
    ),
    const Siswa(
      nisn: "009822323",
      nama: "Sumayyah Binti Khayyat",
      kelas: "XI-A",
      ttl: "Padang, 22 Oktober 2007",
      alamat: "Jl. Pasar Baru No. 12",
      namaOrtu: "Wendra Osman",
      namaIbu: "Rina",
      desa: "Padang",
      kecamatan: "Padang",
      kabupaten: "Padang",
      provinsi: "Sumatera Barat",
    ),
  ];

  List<Siswa> getAllSiswa() {
    return List.unmodifiable(_siswaList);
  }

  void addSiswa(Siswa siswa) {
    _siswaList.add(siswa);
  }

  void deleteSiswa(String nisn) {
    _siswaList.removeWhere((s) => s.nisn == nisn);
  }

  void updateSiswa(Siswa siswa) {
    final index = _siswaList.indexWhere((s) => s.nisn == siswa.nisn);
    if (index != -1) {
      _siswaList[index] = siswa;
    }
  }

  List<Siswa> searchSiswa(String query) {
    if (query.isEmpty) return getAllSiswa();
    final lowerQuery = query.toLowerCase();
    return _siswaList.where((s) =>
      s.nama.toLowerCase().contains(lowerQuery) ||
      s.nisn.toLowerCase().contains(lowerQuery) ||
      s.kelas.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}
