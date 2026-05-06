import 'package:flutter/material.dart';
import '../models/guru.dart';

class DaftarHadirGuruPage extends StatefulWidget {
  const DaftarHadirGuruPage({super.key});

  @override
  State<DaftarHadirGuruPage> createState() => _DaftarHadirGuruPageState();
}

class _DaftarHadirGuruPageState extends State<DaftarHadirGuruPage> {
  String _searchQuery = "";

  final List<Guru> _guruList = [
    const Guru(nip: "19850101201001", nama: "Ustadz Ahmad Fauzi", mapel: "Bahasa Arab", kelas: "XI-C", status: "Hadir"),
    const Guru(nip: "19850102201002", nama: "Ustadzah Maryam", mapel: "Fiqih", kelas: "X-A", status: "Hadir"),
    const Guru(nip: "19850103201003", nama: "Ustadz Mansyur", mapel: "Tahfidz", kelas: "Semua Kelas", status: "Hadir"),
    const Guru(nip: "19850104201004", nama: "Ustadz Zaid", mapel: "Matematika", kelas: "XI-B", status: "Izin"),
    const Guru(nip: "19850105201005", nama: "Ibu Rahma", mapel: "Sejarah Islam", kelas: "XII-A", status: "Hadir"),
    const Guru(nip: "19850106201006", nama: "Ustadz Yusuf", mapel: "Aqidah Akhlak", kelas: "X-C", status: "Hadir"),
    const Guru(nip: "19850107201007", nama: "Ustadz Hamzah", mapel: "Bahasa Inggris", kelas: "X-B", status: "Sakit"),
    const Guru(nip: "19850108201008", nama: "Ibu Siti", mapel: "Bahasa Indonesia", kelas: "X-A", status: "Hadir"),
    const Guru(nip: "19850109201009", nama: "Pak Rudi", mapel: "Fisika", kelas: "XI-A", status: "Hadir"),
    const Guru(nip: "19850110201010", nama: "Ibu Dewi", mapel: "Kimia", kelas: "XII-B", status: "Alpha"),
  ];

  List<Guru> get _filteredGuru {
    if (_searchQuery.isEmpty) return _guruList;
    return _guruList.where((g) =>
      g.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      g.nip.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      g.mapel.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Hadir":
        return const Color(0xFF10B981);
      case "Izin":
        return const Color(0xFFF59E0B);
      case "Sakit":
        return const Color(0xFFEF4444);
      case "Alpha":
        return const Color(0xFF6B7280);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case "Hadir":
        return Icons.check_circle;
      case "Izin":
        return Icons.event_busy;
      case "Sakit":
        return Icons.local_hospital;
      case "Alpha":
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

void _toggleStatus(int index) {
    final guru = _guruList[index];
    final currentStatus = guru.status;
    String newStatus;

    switch (currentStatus) {
      case "Hadir":
        newStatus = "Izin";
        break;
      case "Izin":
        newStatus = "Sakit";
        break;
      case "Sakit":
        newStatus = "Alpha";
        break;
      case "Alpha":
        newStatus = "Hadir";
        break;
      default:
        newStatus = "Hadir";
    }

    setState(() {
      _guruList[index] = Guru(
        nip: guru.nip,
        nama: guru.nama,
        mapel: guru.mapel,
        kelas: guru.kelas,
        status: newStatus,
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Status ${guru.nama} diubah menjadi $newStatus"),
          duration: const Duration(seconds: 1),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }


  int _getHadirCount() {
    return _guruList.where((g) => g.status == "Hadir").length;
  }

  int _getTidakHadirCount() {
    return _guruList.where((g) => g.status != "Hadir").length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        title: const Text("Daftar Hadir Guru"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text("${_getHadirCount()}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text("Hadir", style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text("${_getTidakHadirCount()}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text("Tidak Hadir", style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: "Cari nama, NIP, atau mata pelajaran...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Guru List
            Expanded(
              child: ListView.separated(
                itemCount: _filteredGuru.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final guru = _filteredGuru[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(guru.status).withOpacity(0.1),
                        child: Icon(
                          _getStatusIcon(guru.status),
                          color: _getStatusColor(guru.status),
                        ),
                      ),
                      title: Text(guru.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("NIP: ${guru.nip} • ${guru.mapel} • Kelas ${guru.kelas}"),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(guru.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          guru.status,
                          style: TextStyle(
                            color: _getStatusColor(guru.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      onTap: () => _toggleStatus(index),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
