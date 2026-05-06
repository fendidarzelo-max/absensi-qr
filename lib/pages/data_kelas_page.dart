import 'package:flutter/material.dart';
import '../models/siswa.dart';
import '../services/student_service.dart';

class DataKelasPage extends StatelessWidget {
  DataKelasPage({super.key});


  final StudentService _studentService = StudentService();



  final List<Map<String, dynamic>> _kelasList = const [
    {"nama": "X-A", "wali": "Ustadz Mansyur"},
    {"nama": "X-B", "wali": "Ustadzah Maryam"},
    {"nama": "X-C", "wali": "Ustadz Zaid"},
    {"nama": "XI-A", "wali": "Ustadz Yusuf"},
    {"nama": "XI-B", "wali": "Ustadz Hamzah"},
    {"nama": "XI-C", "wali": "Ibu Rahma"},
    {"nama": "XII-A", "wali": "Ustadz Fauzi"},
    {"nama": "XII-B", "wali": "Ustadzah Aminah"},
  ];

  int _getJumlahSiswa(String kelas) {
    final allSiswa = _studentService.getAllSiswa();
    return allSiswa.where((s) => s.kelas == kelas).length;
  }

  List<Siswa> _getSiswaByKelas(String kelas) {
    final allSiswa = _studentService.getAllSiswa();
    return allSiswa.where((s) => s.kelas == kelas).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        title: const Text("Data Kelas"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.builder(
          itemCount: _kelasList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final kelas = _kelasList[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.class_outlined, color: Color(0xFF10B981)),
                  ),
                  const Spacer(),
                  Text(kelas["nama"], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("${_getJumlahSiswa(kelas["nama"] as String)} Siswa", style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text("Wali: ${kelas["wali"]}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

