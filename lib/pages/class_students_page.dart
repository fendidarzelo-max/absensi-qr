import 'package:flutter/material.dart';
import '../models/siswa.dart';
import '../services/student_service.dart';
import '../widgets/siswa_detail_modal.dart';
import 'tambah_siswa_page.dart';

class ClassStudentsPage extends StatefulWidget {
  final String kelas;
  const ClassStudentsPage({super.key, required this.kelas});

  @override
  State<ClassStudentsPage> createState() => _ClassStudentsPageState();
}

class _ClassStudentsPageState extends State<ClassStudentsPage> {
  final StudentService _studentService = StudentService();
  String _searchQuery = "";

  List<Siswa> get _siswaList {
    return _studentService.getAllSiswa().where((s) => s.kelas == widget.kelas).toList();
  }

  List<Siswa> get _filteredSiswa {
    final list = _siswaList;
    if (_searchQuery.isEmpty) return list;
    final lowerQuery = _searchQuery.toLowerCase();
    return list.where((s) =>
      s.nama.toLowerCase().contains(lowerQuery) ||
      s.nisn.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        title: Text("Kelas ${widget.kelas}"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Card for Class
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.people, color: Color(0xFF10B981), size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total Siswa Kelas",
                          style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "${_siswaList.length} Siswa",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search Box inside the class list
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
                  hintText: "Cari nama atau NISN...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Students List
            Expanded(
              child: _filteredSiswa.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, color: Colors.grey[400], size: 48),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty ? "Belum ada siswa di kelas ini" : "Siswa tidak ditemukan",
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
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
                              subtitle: Text("NISN: ${siswa.nisn}"),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TambahSiswaPage(defaultKelas: widget.kelas),
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
    );
  }
}
