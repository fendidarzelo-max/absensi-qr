import 'package:flutter/material.dart';
import '../services/student_service.dart';
import 'class_students_page.dart';

class DataKelasPage extends StatefulWidget {
  final bool hideAppBar;
  const DataKelasPage({super.key, this.hideAppBar = false});

  @override
  State<DataKelasPage> createState() => _DataKelasPageState();
}

class _DataKelasPageState extends State<DataKelasPage> {
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
    final bool isMobile = MediaQuery.of(context).size.width < 750;
    final content = Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: GridView.builder(
        itemCount: _getKelasOptions().length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isMobile ? 2 : 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isMobile ? 0.95 : 1.3,
        ),
        itemBuilder: (context, index) {
          final namaKelas = _getKelasOptions()[index];
          const waliPlaceholder = "-";
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClassStudentsPage(kelas: namaKelas),
                    ),
                  );
                  // Refresh class options and counts when returning
                  setState(() {});
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.class_outlined, color: Color(0xFF10B981), size: 20),
                      ),
                      const Spacer(),
                      Text(namaKelas, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text("${_getJumlahSiswa(namaKelas)} Siswa", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 2),
                      Text("Wali: $waliPlaceholder", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    if (widget.hideAppBar) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: content,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        title: const Text("Data Kelas"),
        elevation: 0,
      ),
      body: content,
    );
  }
}
