import 'package:flutter/material.dart';
import '../services/system_service.dart';

class IdentitasSekolahPage extends StatefulWidget {
  const IdentitasSekolahPage({super.key});

  @override
  State<IdentitasSekolahPage> createState() => _IdentitasSekolahPageState();
}

class _IdentitasSekolahPageState extends State<IdentitasSekolahPage> {
  final SystemService _systemService = SystemService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _npsnController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _systemService.schoolName);
    _npsnController = TextEditingController(text: _systemService.schoolNpsn);
    _addressController = TextEditingController(text: _systemService.schoolAddress);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _npsnController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102C57),
        foregroundColor: Colors.white,
        title: const Text("Identitas Sekolah"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Color(0xFF102C57),
                            child: Icon(Icons.school, size: 45, color: Colors.white),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Konfigurasi Parameter Sekolah",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                          ),
                          Text(
                            "Edit info dasar institusi untuk cetak laporan & ID Card",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Nama Sekolah",
                        prefixIcon: const Icon(Icons.location_city),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? "Nama sekolah tidak boleh kosong" : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _npsnController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "NPSN (Nomor Pokok Sekolah Nasional)",
                        prefixIcon: const Icon(Icons.badge),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? "NPSN tidak boleh kosong" : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Alamat Sekolah",
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? "Alamat sekolah tidak boleh kosong" : null,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _systemService.updateSchoolIdentity(
                              name: _nameController.text,
                              npsn: _npsnController.text,
                              address: _addressController.text,
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Identitas Sekolah berhasil diperbarui!"),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF102C57),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("SIMPAN IDENTITAS", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
