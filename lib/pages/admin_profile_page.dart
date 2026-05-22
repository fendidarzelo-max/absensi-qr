import 'package:flutter/material.dart';
import '../services/system_service.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final SystemService _systemService = SystemService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _roleController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _systemService.adminName);
    _roleController = TextEditingController(text: _systemService.adminRole);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102C57),
        foregroundColor: Colors.white,
        title: const Text("Profil Admin"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 500),
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
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                          radius: 50,
                          backgroundColor: Color(0xFF102C57),
                          child: Icon(Icons.person, color: Colors.white, size: 50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _systemService.adminName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                    ),
                    Text(
                      _systemService.adminRole,
                      style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Nama Lengkap Admin",
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? "Nama tidak boleh kosong" : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _roleController,
                      decoration: InputDecoration(
                        labelText: "Jabatan / Role",
                        prefixIcon: const Icon(Icons.shield),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? "Role tidak boleh kosong" : null,
                    ),
                    const SizedBox(height: 20),

                    // Read-only email
                    TextFormField(
                      initialValue: "admin@sekolah.sch.id",
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: "Email Sistem (Read-only)",
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _systemService.updateAdminProfile(
                                name: _nameController.text,
                                role: _roleController.text,
                              );
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Profil admin berhasil diperbarui"),
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
                        child: const Text("SIMPAN PERUBAHAN", style: TextStyle(fontWeight: FontWeight.bold)),
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
