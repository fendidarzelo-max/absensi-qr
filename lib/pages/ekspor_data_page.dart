import 'package:flutter/material.dart';

class EksporDataPage extends StatelessWidget {
  const EksporDataPage({super.key});

  final List<Map<String, dynamic>> _eksporOptions = const [
    {"icon": Icons.people, "label": "Data Siswa", "format": "Excel, PDF"},
    {"icon": Icons.class_outlined, "label": "Data Kelas", "format": "Excel, PDF"},
    {"icon": Icons.calendar_today, "label": "Jadwal Mengajar", "format": "PDF"},
    {"icon": Icons.check_circle, "label": "Rekap Absensi", "format": "Excel, PDF"},
    {"icon": Icons.attach_money, "label": "Laporan Keuangan", "format": "Excel, PDF"},
    {"icon": Icons.assessment, "label": "Nilai & Rapor", "format": "PDF"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        title: const Text("Ekspor Data"),
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24.0),
        itemCount: _eksporOptions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _eksporOptions[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item["icon"], color: const Color(0xFF10B981)),
              ),
              title: Text(item["label"], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Format: ${item["format"]}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              trailing: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Mengekspor ${item["label"]}...")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Ekspor"),
              ),
            ),
          );
        },
      ),
    );
  }
}

