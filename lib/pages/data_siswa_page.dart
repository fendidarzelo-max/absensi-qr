import 'package:flutter/material.dart';
import '../models/siswa.dart';
import '../services/student_service.dart';
import '../widgets/siswa_detail_modal.dart';
import 'data_kelas_page.dart';
import 'tambah_siswa_page.dart';

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

  Widget _buildAllSiswaTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
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
            child: _filteredSiswa.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, color: Colors.grey[400], size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          "Siswa tidak ditemukan",
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredSiswa.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final siswa = _filteredSiswa[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                        ),
                        child: InkWell(
                          onTap: () => SiswaDetailModal.show(
                            context,
                            siswa,
                            onRefresh: () => setState(() {}),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                              child: Text(
                                (siswa.nama.isNotEmpty ? siswa.nama[0] : "?"),
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          title: const Text("Data Siswa"),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Semua Siswa"),
              Tab(text: "Rekap per Kelas"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAllSiswaTab(),
            DataKelasPage(hideAppBar: true),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TambahSiswaPage(),
              ),
            );
            if (result == true) {
              setState(() {});
            }
          },
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
