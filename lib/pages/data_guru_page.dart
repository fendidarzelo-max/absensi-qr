import 'package:flutter/material.dart';
import '../models/guru.dart';
import '../services/system_service.dart';

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
    final mapelController = TextEditingController(text: guru?.mapel ?? "");
    final kelasController = TextEditingController(text: guru?.kelas ?? "X-A");
    final jabatanController = TextEditingController(text: guru?.jabatan ?? "Guru Mata Pelajaran");
    String selectedStatus = guru?.status ?? "Tidak Hadir";
    String selectedRole = guru?.hakAkses ?? "Guru";

    final formKey = GlobalKey<FormState>();

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

                  TextFormField(
                    controller: mapelController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "Mata Pelajaran",
                      prefixIcon: const Icon(Icons.book),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? "Mapel tidak boleh kosong" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: kelasController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: "Kelas Binaan / Tugas",
                      prefixIcon: const Icon(Icons.class_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? "Kelas tidak boleh kosong" : null,
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
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: InputDecoration(
                            labelText: "Hak Akses",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: "Admin", child: Text("Admin")),
                            DropdownMenuItem(value: "Staf", child: Text("Staf")),
                            DropdownMenuItem(value: "Guru", child: Text("Guru")),
                          ],
                          onChanged: (val) => setModalState(() => selectedRole = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: InputDecoration(
                            labelText: "Status Kehadiran",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: "Hadir", child: Text("Hadir")),
                            DropdownMenuItem(value: "Izin", child: Text("Izin")),
                            DropdownMenuItem(value: "Sakit", child: Text("Sakit")),
                            DropdownMenuItem(value: "Alpha", child: Text("Alpha")),
                            DropdownMenuItem(value: "Tidak Hadir", child: Text("Tidak Hadir")),
                          ],
                          onChanged: (val) => setModalState(() => selectedStatus = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

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
                            status: selectedStatus,
                            jabatan: jabatanController.text,
                            hakAkses: selectedRole,
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
        return Colors.blueGrey;
    }
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
                            backgroundColor: const Color(0xFF102C57).withOpacity(0.1),
                            child: Text(
                              guru.nama.isNotEmpty ? guru.nama[0] : "?",
                              style: const TextStyle(color: Color(0xFF102C57), fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(guru.nama, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102C57))),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("NIP: ${guru.nip} • Kelas: ${guru.kelas}"),
                              Text("Mapel: ${guru.mapel} • Jabatan: ${guru.jabatan}"),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(guru.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      guru.status,
                                      style: TextStyle(color: _getStatusColor(guru.status), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "Akses: ${guru.hakAkses}",
                                      style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showFormGuru(context, guru: guru),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(context, guru),
                              ),
                            ],
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
