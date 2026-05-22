import 'package:flutter/material.dart';
import '../models/siswa.dart';
import '../models/guru.dart';

class AttendanceLog {
  final String waktu;
  final String nama;
  final String tipe; // Siswa, Guru
  final String status; // Tepat Waktu, Terlambat

  const AttendanceLog({
    required this.waktu,
    required this.nama,
    required this.tipe,
    required this.status,
  });
}

class Holiday {
  final String nama;
  final DateTime tanggal;

  const Holiday({
    required this.nama,
    required this.tanggal,
  });
}

class SystemService extends ChangeNotifier {
  static final SystemService _instance = SystemService._internal();
  factory SystemService() => _instance;

  SystemService._internal() {
    _initDefaultData();
  }

  // School Identity
  String _schoolName = "MADRASAH AMMIYAH MIFTAHUL ULUM  AN-NASHAR";
  String _schoolNpsn = "20219384";
  String _schoolAddress = "Sumber Kembang Pancor, Ketapang, Sampang, Jawa Timur";
  String? _schoolLogoPath;

  // Peripheral Diagnostic
  bool _isPeripheralConnected = true;

  // Admin Profile
  String _adminName = "Ustadz Ahmad Fauzi";
  String _adminRole = "Administrator Utama";

  // Master Lists
  final List<Siswa> _siswaList = [];
  final List<Guru> _guruList = [];
  final List<AttendanceLog> _logs = [];
  final List<Holiday> _holidays = [];

  // Getters
  String get schoolName => _schoolName;
  String get schoolNpsn => _schoolNpsn;
  String get schoolAddress => _schoolAddress;
  String? get schoolLogoPath => _schoolLogoPath;
  bool get isPeripheralConnected => _isPeripheralConnected;
  String get adminName => _adminName;
  String get adminRole => _adminRole;
  List<Siswa> get siswaList => List.unmodifiable(_siswaList);
  List<Guru> get guruList => List.unmodifiable(_guruList);
  List<AttendanceLog> get logs => List.unmodifiable(_logs);
  List<Holiday> get holidays => List.unmodifiable(_holidays);

  // Setters
  void updateSchoolIdentity({required String name, required String npsn, required String address, String? logoPath}) {
    _schoolName = name;
    _schoolNpsn = npsn;
    _schoolAddress = address;
    _schoolLogoPath = logoPath;
    notifyListeners();
  }

  void togglePeripheralConnection() {
    _isPeripheralConnected = !_isPeripheralConnected;
    notifyListeners();
  }

  void setPeripheralConnection(bool value) {
    _isPeripheralConnected = value;
    notifyListeners();
  }

  void updateAdminProfile({required String name, required String role}) {
    _adminName = name;
    _adminRole = role;
    notifyListeners();
  }

  // Siswa CRUD
  void addSiswa(Siswa siswa) {
    _siswaList.add(siswa);
    notifyListeners();
  }

  void updateSiswa(Siswa siswa) {
    final index = _siswaList.indexWhere((s) => s.nisn == siswa.nisn);
    if (index != -1) {
      _siswaList[index] = siswa;
      notifyListeners();
    }
  }

  void deleteSiswa(String nisn) {
    _siswaList.removeWhere((s) => s.nisn == nisn);
    notifyListeners();
  }

  // Guru CRUD
  void addGuru(Guru guru) {
    _guruList.add(guru);
    notifyListeners();
  }

  void updateGuru(Guru guru) {
    final index = _guruList.indexWhere((g) => g.nip == guru.nip);
    if (index != -1) {
      _guruList[index] = guru;
      notifyListeners();
    }
  }

  void deleteGuru(String nip) {
    _guruList.removeWhere((g) => g.nip == nip);
    notifyListeners();
  }

  // Holidays CRUD
  void addHoliday(Holiday holiday) {
    _holidays.add(holiday);
    _holidays.sort((a, b) => a.tanggal.compareTo(b.tanggal));
    notifyListeners();
  }

  void deleteHoliday(int index) {
    if (index >= 0 && index < _holidays.length) {
      _holidays.removeAt(index);
      notifyListeners();
    }
  }

  // Attendance scan logger
  bool recordAttendance(String code, bool isGuru) {
    if (!_isPeripheralConnected) {
      // Diagnostic check: if peripheral is disconnected, scan fails
      return false;
    }

    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    
    // Simple late validation: late if after 07:30
    String status = "Tepat Waktu";
    if (now.hour > 7 || (now.hour == 7 && now.minute > 30)) {
      status = "Terlambat";
    }

    if (isGuru) {
      final index = _guruList.indexWhere((g) => g.nip == code || g.nama == code);
      if (index != -1) {
        final guru = _guruList[index];
        _logs.insert(0, AttendanceLog(
          waktu: timeStr,
          nama: guru.nama,
          tipe: "Guru",
          status: status,
        ));
        // Update guru status
        _guruList[index] = guru.copyWith(status: "Hadir");
        notifyListeners();
        return true;
      }
    } else {
      final index = _siswaList.indexWhere((s) => s.nisn == code || s.nama == code);
      if (index != -1) {
        final siswa = _siswaList[index];
        _logs.insert(0, AttendanceLog(
          waktu: timeStr,
          nama: siswa.nama,
          tipe: "Siswa",
          status: status,
        ));
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  // Student status management
  final Map<String, String> _siswaStatuses = {};

  String getSiswaStatus(String nisn) {
    final index = _siswaList.indexWhere((s) => s.nisn == nisn);
    if (index == -1) return "Alfa";
    final siswa = _siswaList[index];
    final hasScanned = _logs.any((l) => l.nama == siswa.nama && l.tipe == "Siswa");
    if (hasScanned) return "Hadir";
    return _siswaStatuses[nisn] ?? "Alfa";
  }

  void setSiswaStatus(String nisn, String status) {
    final index = _siswaList.indexWhere((s) => s.nisn == nisn);
    if (index == -1) return;
    final siswa = _siswaList[index];

    if (status == "Hadir") {
      final hasScanned = _logs.any((l) => l.nama == siswa.nama && l.tipe == "Siswa");
      if (!hasScanned) {
        final now = DateTime.now();
        final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
        _logs.insert(0, AttendanceLog(
          waktu: timeStr,
          nama: siswa.nama,
          tipe: "Siswa",
          status: "Tepat Waktu",
        ));
      }
      _siswaStatuses[nisn] = "Hadir";
    } else {
      _logs.removeWhere((l) => l.nama == siswa.nama && l.tipe == "Siswa");
      _siswaStatuses[nisn] = status;
    }
    notifyListeners();
  }

  int getSiswaHadirCount() {
    return _logs.where((l) => l.tipe == "Siswa").map((l) => l.nama).toSet().length;
  }

  int getSiswaIzinCount() {
    int count = 0;
    for (var s in _siswaList) {
      if (getSiswaStatus(s.nisn) == "Izin") {
        count++;
      }
    }
    return count;
  }

  int getSiswaSakitCount() {
    int count = 0;
    for (var s in _siswaList) {
      if (getSiswaStatus(s.nisn) == "Sakit") {
        count++;
      }
    }
    return count;
  }

  int getSiswaAlfaCount() {
    int count = 0;
    for (var s in _siswaList) {
      if (getSiswaStatus(s.nisn) == "Alfa") {
        count++;
      }
    }
    return count;
  }

  int getSiswaTidakHadirCount() {
    return _siswaList.length - getSiswaHadirCount();
  }

  int getGuruHadirCount() {
    return _logs.where((l) => l.tipe == "Guru").map((l) => l.nama).toSet().length;
  }

  void _initDefaultData() {
    // Populate default Siswa
    _siswaList.addAll([
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
    ]);

    // Populate default Guru
    _guruList.addAll([
      const Guru(nip: "19850101201001", nama: "Ustadz Ahmad Fauzi", mapel: "Bahasa Arab", kelas: "XI-C", status: "Tidak Hadir"),
      const Guru(nip: "19850102201002", nama: "Ustadzah Maryam", mapel: "Fiqih", kelas: "X-A", status: "Tidak Hadir"),
      const Guru(nip: "19850103201003", nama: "Ustadz Mansyur", mapel: "Tahfidz", kelas: "Semua Kelas", status: "Tidak Hadir"),
      const Guru(nip: "19850104201004", nama: "Ustadz Zaid", mapel: "Matematika", kelas: "XI-B", status: "Tidak Hadir"),
      const Guru(nip: "19850105201005", nama: "Ibu Rahma", mapel: "Sejarah Islam", kelas: "XII-A", status: "Tidak Hadir"),
    ]);

    // Populate default Holidays
    _holidays.addAll([
      Holiday(nama: "Tahun Baru Masehi", tanggal: DateTime(2026, 1, 1)),
      Holiday(nama: "Hari Raya Nyepi", tanggal: DateTime(2026, 3, 19)),
      Holiday(nama: "Wafat Isa Al-Masih", tanggal: DateTime(2026, 4, 3)),
      Holiday(nama: "Hari Raya Idul Fitri 1447 H", tanggal: DateTime(2026, 4, 18)),
      Holiday(nama: "Hari Buruh Internasional", tanggal: DateTime(2026, 5, 1)),
    ]);

    _siswaStatuses["009822315"] = "Izin";
  }
}
