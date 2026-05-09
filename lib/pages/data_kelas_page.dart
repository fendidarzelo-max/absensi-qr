import 'package:flutter/material.dart';
import '../models/siswa.dart';
import '../services/student_service.dart';

class DataKelasPage extends StatelessWidget {
  DataKelasPage({super.key});

  final StudentService _studentService = StudentService();

  List<String> _getKelasOptions() {
    final allSiswa = _studentService.getAllSiswa();
    final kelasSet = allSiswa.map((s) => s.kelas).toSet();
    final kelasList = kelasSet.toList();
    kelasList.sort();
    return kelasList;
  }

  int _getJumlahSiswa(String kelas) {
    final allSiswa = _studentService.getAllSiswa();
    return allSiswa.where((s) => s.kelas == kelas).length;
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
          itemCount: _getKelasOptions().length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final namaKelas = _getKelasOptions()[index];
            const waliPlaceholder = "-";
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
                  Text(namaKelas, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("${_getJumlahSiswa(namaKelas)} Siswa", style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text("Wali: $waliPlaceholder", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

