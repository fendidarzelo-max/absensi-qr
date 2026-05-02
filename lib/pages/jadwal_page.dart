import 'package:flutter/material.dart';
import '../models/jadwal.dart';

class JadwalPage extends StatelessWidget {
  const JadwalPage({super.key});

  final Map<String, List<Jadwal>> _jadwalMingguan = const {
    "Senin": [
      Jadwal("07:30", "Bahasa Arab", "Ustadz Mansyur", "XI-C"),
      Jadwal("09:00", "Fiqih", "Ustadzah Maryam", "X-A"),
      Jadwal("10:30", "Bahasa Inggris", "Ibu Sarah", "X-B"),
    ],
    "Selasa": [
      Jadwal("07:30", "Tahfidz", "Ustadz Zaid", "Semua Kelas"),
      Jadwal("09:30", "Matematika", "Ibu Rahma", "XI-B"),
      Jadwal("11:00", "Sejarah Islam", "Ustadz Hamzah", "XII-A"),
    ],
    "Rabu": [
      Jadwal("08:00", "Aqidah Akhlak", "Ustadz Yusuf", "X-C"),
      Jadwal("10:00", "Sejarah Islam", "Ustadz Hamzah", "XII-A"),
      Jadwal("13:00", "Olahraga", "Pak Budi", "Semua Kelas"),
    ],
    "Kamis": [
      Jadwal("07:30", "Bahasa Indonesia", "Ibu Siti", "X-A"),
      Jadwal("09:00", "Fisika", "Pak Rudi", "XI-A"),
      Jadwal("10:30", "Kimia", "Ibu Dewi", "XII-B"),
    ],
    "Jumat": [
      Jadwal("07:30", "Hadits", "Ustadz Fauzi", "X-A"),
      Jadwal("09:00", "Tafsir", "Ustadz Mansyur", "XI-B"),
    ],
    "Sabtu": [
      Jadwal("08:00", "Praktek Ibadah", "Ustadz Zaid", "Semua Kelas"),
      Jadwal("10:00", "Seni Kaligrafi", "Ibu Aminah", "X-C"),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _jadwalMingguan.keys.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          title: const Text("Jadwal Mengajar"),
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: _jadwalMingguan.keys.map((day) => Tab(text: day)).toList(),
          ),
        ),
        body: TabBarView(
          children: _jadwalMingguan.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                children: entry.value.map((j) => _buildJadwalItem(j)).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildJadwalItem(Jadwal j) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF065F46),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(j.jam, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(j.mapel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("${j.guru} • Kelas ${j.kelas}", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        ],
      ),
    );
  }
}

