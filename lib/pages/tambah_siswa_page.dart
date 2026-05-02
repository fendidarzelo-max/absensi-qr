import 'package:flutter/material.dart';

class TambahSiswaPage extends StatefulWidget {
  const TambahSiswaPage({super.key});

  @override
  State<TambahSiswaPage> createState() => _TambahSiswaPageState();
}

class _TambahSiswaPageState extends State<TambahSiswaPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _nisnController = TextEditingController();
  final _ttlController = TextEditingController();
  final _alamatController = TextEditingController();
  final _namaOrtuController = TextEditingController();
  String _selectedKelas = "X-A";
  bool _isLoading = false;

  final List<String> _kelasOptions = ["X-A", "X-B", "X-C", "XI-A", "XI-B", "XI-C", "XII-A", "XII-B"];

  String? _validateNama(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.length < 3) {
      return 'Nama minimal 3 karakter';
    }
    return null;
  }

  String? _validateNisn(String? value) {
    if (value == null || value.isEmpty) {
      return 'NISN tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'NISN minimal 6 digit';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'NISN harus angka';
    }
    return null;
  }

  void _handleSimpan() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // Simulate save delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Siswa ${_namaController.text} berhasil ditambahkan!"),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          Navigator.pop(context);
        }
      });
    }
  }

@override
  void dispose() {
    _namaController.dispose();
    _nisnController.dispose();
    _ttlController.dispose();
    _alamatController.dispose();
    _namaOrtuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        title: const Text("Tambah Siswa"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Formulir Pendaftaran Siswa", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("Lengkapi data diri siswa baru", style: TextStyle(color: Colors.grey[600])),
const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _namaController,
                      validator: _validateNama,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Nama Lengkap",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nisnController,
                      validator: _validateNisn,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "NISN",
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
DropdownButtonFormField<String>(
                      value: _selectedKelas,
                      decoration: InputDecoration(
                        labelText: "Kelas",
                        prefixIcon: const Icon(Icons.class_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _kelasOptions.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                      onChanged: (val) => setState(() => _selectedKelas = val!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ttlController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Tanggal Lahir",
                        hintText: "Contoh: Bandung, 15 Januari 2008",
                        prefixIcon: const Icon(Icons.cake_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _alamatController,
                      textCapitalization: TextCapitalization.words,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Alamat Orang Tua/Wali",
                        hintText: "Contoh: Jl. Merdeka No. 10",
                        prefixIcon: const Icon(Icons.home_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _namaOrtuController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Nama Orang Tua/Wali",
                        hintText: "Contoh: Ahmad",
                        prefixIcon: const Icon(Icons.person_pin_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSimpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("SIMPAN DATA", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

