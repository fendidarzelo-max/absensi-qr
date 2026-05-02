import 'package:flutter/material.dart';

class DataKelasPage extends StatelessWidget {
  const DataKelasPage({super.key});

  final List<Map<String, dynamic>> _kelasList = const [
    {"nama": "X-A", "jumlah": 32, "wali": "Ustadz Mansyur"},
    {"nama": "X-B", "jumlah": 30, "wali": "Ustadzah Maryam"},
    {"nama": "X-C", "jumlah": 28, "wali": "Ustadz Zaid"},
    {"nama": "XI-A", "jumlah": 31, "wali": "Ustadz Yusuf"},
    {"nama": "XI-B", "jumlah": 29, "wali": "Ustadz Hamzah"},
    {"nama": "XI-C", "jumlah": 27, "wali": "Ibu Rahma"},
    {"nama": "XII-A", "jumlah": 33, "wali": "Ustadz Fauzi"},
    {"nama": "XII-B", "jumlah": 30, "wali": "Ustadzah Aminah"},
  ];

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
                  Text("${kelas["jumlah"]} Siswa", style: TextStyle(color: Colors.grey[600])),
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

