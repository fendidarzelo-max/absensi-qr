import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show File;
import '../models/guru.dart';
import '../services/system_service.dart';
import '../utils/excel_helper.dart';
import '../utils/file_saver.dart';

class DataGuruPage extends StatefulWidget {
  const DataGuruPage({super.key});

  @override
  State<DataGuruPage> createState() => _DataGuruPageState();
}

class _DataGuruPageState extends State<DataGuruPage> {
  String _searchQuery = "";
  final SystemService _systemService = SystemService();

  List<Guru> get _guruList => _systemService.guruList;

  List<Guru> get _filteredGuru {
    if (_searchQuery.isEmpty) return _guruList;
    final lowerQuery = _searchQuery.toLowerCase();
    return _guruList.where((g) =>
      g.nama.toLowerCase().contains(lowerQuery) ||
      g.nip.toLowerCase().contains(lowerQuery) ||
      g.mapel.toLowerCase().contains(lowerQuery) ||
      g.jabatan.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  void _showFormGuru(BuildContext context, {Guru? guru}) {
    final isEdit = guru != null;
    final nipController = TextEditingController(text: guru?.nip ?? "");
    final namaController = TextEditingController(text: guru?.nama ?? "");
    final jabatanController = TextEditingController(text: guru?.jabatan ?? "Guru Mata Pelajaran");
    final mapelController = TextEditingController(text: guru?.mapel ?? "");
    final kelasController = TextEditingController(text: guru?.kelas ?? "");
    final tanggalLahirController = TextEditingController(text: guru?.tanggalLahir ?? "");
    final pendidikanController = TextEditingController(text: guru?.pendidikanTerakhir ?? "");
    String selectedGender = (guru?.jenisKelamin != null && (guru!.jenisKelamin == "Laki-laki" || guru.jenisKelamin == "Perempuan")) ? guru.jenisKelamin : "Laki-laki";
    String selectedAgama = (guru?.agama != null && ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Khonghucu', 'Lainnya'].contains(guru!.agama)) ? guru.agama : "Islam";

    final formKey = GlobalKey<FormState>();

    final Map<String, List<String>> scheduleMap = {};
    const List<String> daysOfWeek = ["Senin", "Selasa", "Rabu", "Kamis", "Sabtu", "Ahad"];
    for (var d in daysOfWeek) {
      scheduleMap[d] = [];
    }
    if (guru?.jadwalMengajar != null && guru!.jadwalMengajar!.isNotEmpty) {
      try {
        final decoded = jsonDecode(guru.jadwalMengajar!) as Map<String, dynamic>;
        decoded.forEach((key, val) {
          if (val is List) {
            scheduleMap[key] = val.map((e) => e.toString()).toList();
          }
        });
      } catch (e) {
        debugPrint("Error parsing jadwal: $e");
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isEdit ? "Edit Data Guru" : "Tambah Data Guru",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                  ),
                  const SizedBox(height: 20),
                  
                  TextFormField(
                    controller: nipController,
                    enabled: !isEdit,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "NIP (Nomor Induk Pegawai)",
                      prefixIcon: const Icon(Icons.badge),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? "NIP tidak boleh kosong" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: namaController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "Nama Lengkap",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? "Nama tidak boleh kosong" : null,
                  ),
                  const SizedBox(height: 16),

                  // Jenis Kelamin & Agama
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedGender,
                          decoration: InputDecoration(
                            labelText: "Jenis Kelamin",
                            prefixIcon: const Icon(Icons.wc),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: "Laki-laki", child: Text("Laki-laki")),
                            DropdownMenuItem(value: "Perempuan", child: Text("Perempuan")),
                          ],
                          onChanged: (val) => setModalState(() => selectedGender = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedAgama,
                          decoration: InputDecoration(
                            labelText: "Agama",
                            prefixIcon: const Icon(Icons.church),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: "Islam", child: Text("Islam")),
                            DropdownMenuItem(value: "Kristen", child: Text("Kristen")),
                            DropdownMenuItem(value: "Katolik", child: Text("Katolik")),
                            DropdownMenuItem(value: "Hindu", child: Text("Hindu")),
                            DropdownMenuItem(value: "Buddha", child: Text("Buddha")),
                            DropdownMenuItem(value: "Khonghucu", child: Text("Khonghucu")),
                            DropdownMenuItem(value: "Lainnya", child: Text("Lainnya")),
                          ],
                          onChanged: (val) => setModalState(() => selectedAgama = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tanggal Lahir & Pendidikan Terakhir
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: tanggalLahirController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Tanggal Lahir",
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setModalState(() {
                                final months = [
                                  "", "Januari", "Februari", "Maret", "April", "Mei", "Juni",
                                  "Juli", "Agustus", "September", "Oktober", "November", "Desember"
                                ];
                                tanggalLahirController.text = "${picked.day} ${months[picked.month]} ${picked.year}";
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: pendidikanController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: "Pendidikan Terakhir",
                            prefixIcon: const Icon(Icons.school),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: mapelController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "Mata Pelajaran (Mapel)",
                      prefixIcon: const Icon(Icons.book),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: kelasController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: "Wali Kelas / Kelas",
                      prefixIcon: const Icon(Icons.class_),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: jabatanController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "Jabatan",
                      prefixIcon: const Icon(Icons.work),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Jadwal Mengajar Harian (Tingkat)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF102C57)),
                  ),
                  const SizedBox(height: 10),
                  ...daysOfWeek.map((day) {
                    final selectedLevels = scheduleMap[day] ?? [];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 70,
                            child: Text(day, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          ...["MI", "MTS", "MA"].map((lvl) {
                            final isChecked = selectedLevels.contains(lvl);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(lvl, style: TextStyle(fontSize: 11, color: isChecked ? Colors.white : Colors.black87)),
                                selected: isChecked,
                                selectedColor: const Color(0xFF102C57),
                                checkmarkColor: Colors.white,
                                onSelected: (selected) {
                                  setModalState(() {
                                    if (selected) {
                                      selectedLevels.add(lvl);
                                    } else {
                                      selectedLevels.remove(lvl);
                                    }
                                    scheduleMap[day] = selectedLevels;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final newGuru = Guru(
                            nip: nipController.text,
                            nama: namaController.text,
                            mapel: mapelController.text,
                            kelas: kelasController.text,
                            status: guru?.status ?? "Tidak Hadir",
                            jabatan: jabatanController.text,
                            hakAkses: guru?.hakAkses ?? "Guru",
                            agama: selectedAgama,
                            jenisKelamin: selectedGender,
                            tanggalLahir: tanggalLahirController.text,
                            pendidikanTerakhir: pendidikanController.text,
                            jadwalMengajar: jsonEncode(scheduleMap),
                          );

                          setState(() {
                            if (isEdit) {
                              _systemService.updateGuru(newGuru);
                            } else {
                              _systemService.addGuru(newGuru);
                            }
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit ? "Data guru berhasil diubah" : "Data guru berhasil ditambahkan"),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF102C57),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isEdit ? "SIMPAN PERUBAHAN" : "TAMBAH GURU", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Guru guru) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Guru"),
        content: Text("Apakah Anda yakin ingin menghapus data ${guru.nama}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("BATAL"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _systemService.deleteGuru(guru.nip);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Data guru berhasil dihapus")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("HAPUS"),
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
        backgroundColor: const Color(0xFF102C57),
        foregroundColor: Colors.white,
        title: const Text("Master Data Guru"),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showFormGuru(context),
            icon: const Icon(Icons.add_circle_outline, size: 28),
          ),
        ],
      ),
      body: Padding(
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
                  hintText: "Cari NIP, nama, mapel, atau jabatan...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredGuru.isEmpty
                ? const Center(child: Text("Tidak ada data guru", style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    itemCount: _filteredGuru.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final guru = _filteredGuru[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF102C57).withValues(alpha: 0.1),
                              child: Text(
                                guru.nama.isNotEmpty ? guru.nama[0] : "?",
                                style: const TextStyle(color: Color(0xFF102C57), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    guru.nama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF102C57),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "NIP: ${guru.nip} • Kelamin: ${guru.jenisKelamin.isNotEmpty ? guru.jenisKelamin : '-'} • Agama: ${guru.agama.isNotEmpty ? guru.agama : '-'}",
                                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Lahir: ${guru.tanggalLahir.isNotEmpty ? guru.tanggalLahir : '-'} • Pend: ${guru.pendidikanTerakhir.isNotEmpty ? guru.pendidikanTerakhir : '-'}",
                                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Jabatan: ${guru.jabatan} • Mapel: ${guru.mapel.isNotEmpty ? guru.mapel : '-'} • Kelas: ${guru.kelas.isNotEmpty ? guru.kelas : '-'}",
                                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                  onPressed: () => _showFormGuru(context, guru: guru),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _confirmDelete(context, guru),
                                ),
                              ],
                            ),
                          ],
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
            "Fitur Data Guru (Excel)",
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
                onPressed: _clearAllGuru,
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
      if (_guruList.isEmpty) {
        bytes = ExcelHelper.generateGuruTemplate();
      } else {
        bytes = ExcelHelper.exportGuruToExcel(_guruList);
      }
      saveBytes(bytes, 'Data_Guru_Ekspor.xlsx');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_guruList.isEmpty
              ? "Template Excel Guru berhasil diunduh (karena data kosong)"
              : "Data Guru berhasil diekspor ke Excel"),
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

      final parsedList = ExcelHelper.parseGuruExcel(bytes);
      if (parsedList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Tidak ada data guru yang valid di dalam file Excel"),
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
          content: Text("Ditemukan ${parsedList.length} data guru. Apakah Anda yakin ingin memasukkan data ini ke sistem? Data dengan NIP yang sama akan diperbarui."),
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
                            Text("Mengimpor data guru..."),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                int count = 0;
                try {
                  for (var g in parsedList) {
                    if (_guruList.any((x) => x.nip == g.nip)) {
                      await _systemService.updateGuru(g);
                    } else {
                      await _systemService.addGuru(g);
                    }
                    count++;
                  }

                  if (mounted) {
                    Navigator.pop(context); // Close progress dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Berhasil mengimpor $count data guru"),
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
                backgroundColor: const Color(0xFF102C57),
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

  Future<void> _clearAllGuru() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus Semua"),
        content: const Text(
          "Apakah Anda yakin ingin menghapus seluruh data guru? Tindakan ini tidak dapat dibatalkan.",
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
                await _systemService.clearAllGuru();
                if (mounted) {
                  Navigator.pop(context); // Close progress
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Seluruh data guru berhasil dihapus"),
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
