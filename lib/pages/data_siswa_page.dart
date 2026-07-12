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
                            subtitle: Text("NISN: ${siswa.nisn} • Kelas ${siswa.kelasDisplay}"),
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

  void _showPromotionDialog(BuildContext context) {
    String? selectedKelasAsal;
    final TextEditingController kelasBaruController = TextEditingController();
    final classes = _studentService.getAllSiswa().map((s) => s.kelas).toSet().toList();
    classes.sort();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.trending_up, color: Color(0xFF10B981)),
                  SizedBox(width: 8),
                  Text("Kenaikan Kelas Massal"),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Fitur ini memindahkan semua siswa dari satu kelas ke kelas baru secara sekaligus.",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    const Text("Pilih Kelas Asal", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedKelasAsal,
                          hint: const Text("Pilih kelas..."),
                          isExpanded: true,
                          items: classes.map((String val) {
                            return DropdownMenuItem<String>(
                              value: val,
                              child: Text(val),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setModalState(() {
                              selectedKelasAsal = val;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Nama Kelas Baru", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: kelasBaruController,
                      decoration: InputDecoration(
                        hintText: "Contoh: 8A, 9B, atau LULUS",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("BATAL", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (selectedKelasAsal == null || kelasBaruController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Harap isi kelas asal dan kelas baru"), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    
                    final targetClass = kelasBaruController.text.trim();
                    Navigator.pop(context);
                    
                    // Show progress dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    );

                    try {
                      await _studentService.promoteSiswaClass(selectedKelasAsal!, targetClass);
                      if (context.mounted) {
                        Navigator.pop(context); // Close progress dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Berhasil memindahkan siswa"), backgroundColor: Colors.green),
                        );
                        setState(() {});
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context); // Close progress dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Gagal memproses: $e"), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text("PROSES"),
                ),
              ],
            );
          },
        );
      },
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
          actions: [
            IconButton(
              icon: const Icon(Icons.trending_up, color: Colors.white),
              tooltip: "Kenaikan Kelas Massal",
              onPressed: () => _showPromotionDialog(context),
            ),
            const SizedBox(width: 8),
          ],
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
