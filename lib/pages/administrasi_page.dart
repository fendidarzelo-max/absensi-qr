import 'package:flutter/material.dart';

class AdministrasiPage extends StatelessWidget {
  const AdministrasiPage({super.key});

  final List<Map<String, dynamic>> _menuAdmin = const [
    {"icon": Icons.file_copy, "label": "Rapor Siswa", "desc": "Cetak & kelola rapor"},
    {"icon": Icons.assignment, "label": "Surat Izin", "desc": "Pengajuan & approval"},
    {"icon": Icons.attach_money, "label": "SPP & Keuangan", "desc": "Pembayaran & laporan"},
    {"icon": Icons.event_note, "label": "Kalender Akademik", "desc": "Jadwal kegiatan"},
    {"icon": Icons.folder_shared, "label": "Arsip Digital", "desc": "Dokumen madrasah"},
    {"icon": Icons.settings, "label": "Pengaturan", "desc": "Konfigurasi sistem"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        title: const Text("Administrasi"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.builder(
          itemCount: _menuAdmin.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            final menu = _menuAdmin[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(menu["icon"], color: const Color(0xFF10B981), size: 32),
                  const Spacer(),
                  Text(menu["label"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(menu["desc"], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

