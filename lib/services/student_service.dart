import '../models/siswa.dart';
import 'system_service.dart';

class StudentService {
  static final StudentService _instance = StudentService._internal();
  factory StudentService() => _instance;
  StudentService._internal();

  List<Siswa> getAllSiswa() {
    return SystemService().siswaList;
  }

  void addSiswa(Siswa siswa) {
    SystemService().addSiswa(siswa);
  }

  void deleteSiswa(String nisn) {
    SystemService().deleteSiswa(nisn);
  }

  void updateSiswa(Siswa siswa) {
    SystemService().updateSiswa(siswa);
  }

  Future<void> promoteSiswaClass(List<String> nisns, String kelasBaru) async {
    await SystemService().promoteSiswaClass(nisns, kelasBaru);
  }

  List<Siswa> searchSiswa(String query) {
    if (query.isEmpty) return getAllSiswa();
    final lowerQuery = query.toLowerCase();
    return SystemService().siswaList.where((s) =>
      s.nama.toLowerCase().contains(lowerQuery) ||
      s.nisn.toLowerCase().contains(lowerQuery) ||
      s.kelas.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}
