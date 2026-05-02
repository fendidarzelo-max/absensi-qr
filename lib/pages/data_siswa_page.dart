import 'package:flutter/material.dart';
import '../models/siswa.dart';
import '../services/student_service.dart';

class DataSiswaPage extends StatefulWidget {
  const DataSiswaPage({super.key});

  @override
  State<DataSiswaPage> createState() => _DataSiswaPageState();
}

class _DataSiswaPageState extends State<DataSiswaPage> {
  String _searchQuery = "";
  final StudentService _studentService = StudentService();

  List<Siswa> get _siswaList => _studentService.getAllSiswa();

  List<Siswa> get _filteredSiswa {
    if (_searchQuery.isEmpty) return _siswaList;
    final lowerQuery = _searchQuery.toLowerCase();
    return _siswaList.where((s) =>
      s.nama.toLowerCase().contains(lowerQuery) ||
      s.nisn.toLowerCase().contains(lowerQuery) ||
      s.kelas.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  void _showDetailSiswa(BuildContext context, Siswa siswa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
              child: Text(
                siswa.nama[0],
                style: const TextStyle(
                  fontSize: 36,
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              siswa.nama,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Kelas ${siswa.kelas}",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.badge_outlined, "NISN", siswa.nisn),
                    _buildDetailRow(Icons.cake_outlined, "Tanggal Lahir", siswa.ttl),
                    _buildDetailRow(Icons.home_outlined, "Alamat Orang Tua/Wali", siswa.alamat),
                    _buildDetailRow(Icons.location_city_outlined, "Desa", siswa.desa),
                    _buildDetailRow(Icons.map_outlined, "Kecamatan", siswa.kecamatan),
                    _buildDetailRow(Icons.business_outlined, "Kabupaten", siswa.kabupaten),
                    _buildDetailRow(Icons.flag_outlined, "Provinsi", siswa.provinsi),
                    _buildDetailRow(Icons.person_pin_outlined, "Nama Orang Tua/Wali", siswa.namaOrtu),
                    _buildDetailRow(Icons.woman_outlined, "Nama Ibu Kandung", siswa.namaIbu),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        title: const Text("Data Siswa"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
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
                  hintText: "Cari nama, NISN, atau kelas...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _filteredSiswa.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final siswa = _filteredSiswa[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: InkWell(
                      onTap: () => _showDetailSiswa(context, siswa),
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                          child: Text(siswa.nama[0], style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                        ),
                        title: Text(siswa.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("NISN: ${siswa.nisn} • Kelas ${siswa.kelas}"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      ),
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
