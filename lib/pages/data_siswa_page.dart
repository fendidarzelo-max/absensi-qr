import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show File;
import '../models/siswa.dart';
import '../services/student_service.dart';
import '../services/system_service.dart';
import '../widgets/siswa_detail_modal.dart';
import '../utils/excel_helper.dart';
import '../utils/file_saver.dart';
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
          _buildActionButtons(context),
          const SizedBox(height: 16),
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

    List<Siswa> studentsInClass = [];
    Set<String> selectedNisns = {};

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
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Pilih kelas asal, masukkan kelas baru, lalu hilangkan centang pada murid yang tidak naik kelas (tetap di kelas lama).",
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
                                if (val != null) {
                                  studentsInClass = _studentService
                                      .getAllSiswa()
                                      .where((s) => s.kelas == val)
                                      .toList();
                                  selectedNisns = studentsInClass.map((s) => s.nisn).toSet();
                                } else {
                                  studentsInClass = [];
                                  selectedNisns = {};
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      if (selectedKelasAsal != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Pilih Siswa yang Naik (${selectedNisns.length}/${studentsInClass.length})",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                setModalState(() {
                                  if (selectedNisns.length == studentsInClass.length) {
                                    selectedNisns.clear();
                                  } else {
                                    selectedNisns = studentsInClass.map((s) => s.nisn).toSet();
                                  }
                                });
                              },
                              child: Text(
                                selectedNisns.length == studentsInClass.length ? "Kosongkan" : "Pilih Semua",
                                style: const TextStyle(fontSize: 12, color: Color(0xFF10B981)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: studentsInClass.isEmpty
                              ? const Center(child: Text("Tidak ada siswa", style: TextStyle(color: Colors.grey)))
                              : ListView.builder(
                                  itemCount: studentsInClass.length,
                                  itemBuilder: (context, idx) {
                                    final siswa = studentsInClass[idx];
                                    final isSelected = selectedNisns.contains(siswa.nisn);
                                    return CheckboxListTile(
                                      title: Text(siswa.nama, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      subtitle: Text("NISN: ${siswa.nisn}", style: const TextStyle(fontSize: 11)),
                                      value: isSelected,
                                      dense: true,
                                      activeColor: const Color(0xFF10B981),
                                      controlAffinity: ListTileControlAffinity.leading,
                                      onChanged: (bool? val) {
                                        setModalState(() {
                                          if (val == true) {
                                            selectedNisns.add(siswa.nisn);
                                          } else {
                                            selectedNisns.remove(siswa.nisn);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
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
                    if (selectedNisns.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Pilih minimal satu siswa untuk dinaikkan kelas"), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    
                    final targetClass = kelasBaruController.text.trim();
                    final listToPromote = selectedNisns.toList();
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
                      await _studentService.promoteSiswaClass(listToPromote, targetClass);
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

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Fitur Data Siswa (Excel)",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF102C57),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionButton(
                label: "Upload Excel",
                icon: Icons.upload_file_rounded,
                bgColor: const Color(0xFFE8F5E9),
                textColor: const Color(0xFF2E7D32),
                onPressed: _uploadExcel,
              ),
              _actionButton(
                label: "Ekspor Excel",
                icon: Icons.article_rounded,
                bgColor: const Color(0xFFE8EAF6),
                textColor: const Color(0xFF283593),
                onPressed: _exportExcel,
              ),
              _actionButton(
                label: "Hapus Semua",
                icon: Icons.delete_sweep_rounded,
                bgColor: const Color(0xFFFFEBEE),
                textColor: const Color(0xFFC62828),
                onPressed: _clearAllSiswa,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Future<void> _exportExcel() async {
    try {
      final List<int> bytes;
      if (_siswaList.isEmpty) {
        bytes = ExcelHelper.generateSiswaTemplate();
      } else {
        bytes = ExcelHelper.exportSiswaToExcel(_siswaList);
      }
      saveBytes(bytes, 'Data_Siswa_Ekspor.xlsx');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_siswaList.isEmpty
              ? "Template Excel berhasil diunduh (karena data kosong)"
              : "Data Siswa berhasil diekspor ke Excel"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengekspor data: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadExcel() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      List<int> bytes;
      if (kIsWeb) {
        if (file.bytes == null) {
          throw Exception("File bytes are null on web");
        }
        bytes = file.bytes!;
      } else {
        if (file.path == null) {
          throw Exception("File path is null on mobile/desktop");
        }
        bytes = await File(file.path!).readAsBytes();
      }

      final parsedList = ExcelHelper.parseSiswaExcel(bytes);
      if (parsedList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Tidak ada data siswa yang valid di dalam file Excel"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Konfirmasi Unggah Excel"),
          content: Text("Ditemukan ${parsedList.length} data siswa. Apakah Anda yakin ingin memasukkan data ini ke sistem? Data dengan NISN yang sama akan diperbarui."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("BATAL"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close confirm dialog

                // Show progress dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text("Mengimpor data siswa..."),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                int count = 0;
                try {
                  for (var s in parsedList) {
                    if (_siswaList.any((x) => x.nisn == s.nisn)) {
                      _studentService.updateSiswa(s);
                    } else {
                      _studentService.addSiswa(s);
                    }
                    count++;
                  }

                  if (mounted) {
                    Navigator.pop(context); // Close progress dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Berhasil mengimpor $count data siswa"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    setState(() {});
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // Close progress dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Gagal mengimpor: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: const Text("IMPOR"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _clearAllSiswa() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus Semua"),
        content: const Text(
          "Apakah Anda yakin ingin menghapus seluruh data siswa? Tindakan ini tidak dapat dibatalkan.",
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("BATAL"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

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
                await SystemService().clearAllSiswa();
                if (mounted) {
                  Navigator.pop(context); // Close progress
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Seluruh data siswa berhasil dihapus"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {});
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close progress
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal menghapus: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("HAPUS SEMUA"),
          ),
        ],
      ),
    );
  }
}

