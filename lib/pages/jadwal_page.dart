import 'package:flutter/material.dart';
import '../models/jadwal.dart';

class JadwalPage extends StatelessWidget {
  const JadwalPage({super.key});

  final Map<String, List<Jadwal>> _jadwalMingguan = const {
    "Senin": [
      Jadwal(jam: "07:30", mapel: "Bahasa Arab", guru: "Ustadz Mansyur", kelas: "XI-C"),
      Jadwal(jam: "09:00", mapel: "Fiqih", guru: "Ustadzah Maryam", kelas: "X-A"),
      Jadwal(jam: "10:30", mapel: "Bahasa Inggris", guru: "Ibu Sarah", kelas: "X-B"),
    ],
    "Selasa": [
      Jadwal(jam: "07:30", mapel: "Tahfidz", guru: "Ustadz Zaid", kelas: "Semua Kelas"),
      Jadwal(jam: "09:30", mapel: "Matematika", guru: "Ibu Rahma", kelas: "XI-B"),
      Jadwal(jam: "11:00", mapel: "Sejarah Islam", guru: "Ustadz Hamzah", kelas: "XII-A"),
    ],
    "Rabu": [
      Jadwal(jam: "08:00", mapel: "Aqidah Akhlak", guru: "Ustadz Yusuf", kelas: "X-C"),
      Jadwal(jam: "10:00", mapel: "Sejarah Islam", guru: "Ustadz Hamzah", kelas: "XII-A"),
      Jadwal(jam: "13:00", mapel: "Olahraga", guru: "Pak Budi", kelas: "Semua Kelas"),
    ],
    "Kamis": [
      Jadwal(jam: "07:30", mapel: "Bahasa Indonesia", guru: "Ibu Siti", kelas: "X-A"),
      Jadwal(jam: "09:00", mapel: "Fisika", guru: "Pak Rudi", kelas: "XI-A"),
      Jadwal(jam: "10:30", mapel: "Kimia", guru: "Ibu Dewi", kelas: "XII-B"),
    ],
    "Jumat": [
      Jadwal(jam: "07:30", mapel: "Hadits", guru: "Ustadz Fauzi", kelas: "X-A"),
      Jadwal(jam: "09:00", mapel: "Tafsir", guru: "Ustadz Mansyur", kelas: "XI-B"),
    ],
    "Sabtu": [
      Jadwal(jam: "08:00", mapel: "Praktek Ibadah", guru: "Ustadz Zaid", kelas: "Semua Kelas"),
      Jadwal(jam: "10:00", mapel: "Seni Kaligrafi", guru: "Ibu Aminah", kelas: "X-C"),
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
