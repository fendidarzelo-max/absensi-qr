import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/system_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nipController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  String _selectedRole = "Admin";
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Offset? _mousePosition;
  late AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _nipController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama lengkap tidak boleh kosong';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username tidak boleh kosong';
    }
    if (value.length < 3) {
      return 'Username minimal 3 karakter';
    }
    return null;
  }

  String? _validateNip(String? value) {
    if (value == null || value.isEmpty) {
      return 'NIP tidak boleh kosong';
    }
    if (value.length < 3) {
      return 'NIP minimal 3 karakter';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null; // Email opsional
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != _passController.text) {
      return 'Password tidak cocok';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final systemService = SystemService();

      // ✅ Jika Firebase tersedia, HANYA gunakan Firebase (tidak jatuh ke PHP)
      if (systemService.isFirebaseAvailable) {
        try {
          final firestore = FirebaseFirestore.instance;
          final name = _nameController.text.trim();
          final password = _passController.text;

          if (_selectedRole == "Admin") {
            final username = _usernameController.text.trim();
            final email = _emailController.text.trim();

            // Check if username already exists
            final userDoc = await firestore.collection('admin').doc(username).get();
            if (userDoc.exists) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Username sudah terdaftar"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
              setState(() => _isLoading = false);
              return;
            }

            // Check if email already exists
            if (email.isNotEmpty) {
              final emailQuery = await firestore
                  .collection('admin')
                  .where('email', isEqualTo: email)
                  .get();
              if (emailQuery.docs.isNotEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Email sudah terdaftar"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
                setState(() => _isLoading = false);
                return;
              }
            }

            // Save account directly to Firebase Firestore
            await firestore.collection('admin').doc(username).set({
              'username': username,
              'email': email.isEmpty ? "$username@sekolah.sch.id" : email,
              'nama_lengkap': name,
              'role': 'Administrator Utama',
              'password': password,
              'foto': '',
            });
          } else {
            // Register/Activate Guru
            final nip = _nipController.text.trim();
            final guruDoc = await firestore.collection('guru').doc(nip).get();
            
            if (guruDoc.exists) {
              // Update existing teacher record (activate/claim account)
              await firestore.collection('guru').doc(nip).update({
                'nama': name,
                'password': password,
              });
            } else {
              // Create brand new teacher record
              await firestore.collection('guru').doc(nip).set({
                'nip': nip,
                'nama': name,
                'password': password,
                'mapel': '',
                'kelas': '',
                'status': 'Tidak Hadir',
                'jabatan': 'Guru Mata Pelajaran',
                'hakAkses': 'Guru',
                'agama': '',
                'jenisKelamin': '',
                'tanggalLahir': '',
                'pendidikanTerakhir': '',
                'jadwalMengajar': '{}',
                'qr_code': nip,
                'email': "$nip@sekolah.sch.id",
              });
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_selectedRole == "Admin"
                          ? "Pendaftaran akun admin berhasil! Silakan login."
                          : "Pendaftaran akun guru berhasil! Silakan login."),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } catch (e) {
          debugPrint("Firebase registration error: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text("Gagal mendaftar: ${e.toString().split(']').last.trim()}"),
                    ),
                  ],
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
        return; // Jangan lanjut ke PHP jika Firebase tersedia
      }

      // Fallback PHP backend (hanya jika Firebase tidak tersedia)
      try {
        if (_selectedRole == "Admin") {
          final Map<String, dynamic> requestBody = {
            'name': _nameController.text.trim(),
            'username': _usernameController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passController.text,
          };

          final response = await http
              .post(
                Uri.parse('${systemService.baseUrl}/register.php'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(requestBody),
              )
              .timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final resData = jsonDecode(response.body);
            if (resData['status'] == 'success') {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            resData['message'] ?? "Pendaftaran berhasil! Silakan login.",
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(resData['message'] ?? "Pendaftaran gagal"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }
          } else {
            throw Exception("Server error: ${response.statusCode}");
          }
        } else {
          // Register Guru via PHP
          final Map<String, dynamic> requestBody = {
            'name': _nameController.text.trim(),
            'nip': _nipController.text.trim(),
            'password': _passController.text,
          };

          final response = await http
              .post(
                Uri.parse('${systemService.baseUrl}/register_guru.php'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(requestBody),
              )
              .timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final resData = jsonDecode(response.body);
            if (resData['status'] == 'success') {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            resData['message'] ?? "Pendaftaran Guru berhasil! Silakan login.",
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(resData['message'] ?? "Pendaftaran gagal"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }
          } else {
            throw Exception("Server error: ${response.statusCode}");
          }
        }
      } catch (e) {
        debugPrint("Error pendaftaran: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Gagal terhubung ke database. Silakan pastikan server database aktif.",
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MouseRegion(
        onHover: (event) {
          setState(() {
            _mousePosition = event.localPosition;
          });
        },
        onExit: (_) {
          setState(() {
            _mousePosition = null;
          });
        },
        child: Stack(
          children: [
            // Background plexus teknologi interaktif (reused dari login_page.dart)
            TechInteractiveBackground(mousePosition: _mousePosition),

            // Tombol kembali
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF102C57)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),

            // Form Register
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo Animasi
                        AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, -4 + _logoController.value * 8),
                              child: child,
                            );
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            child: Image.asset(
                              'assets/logo_login.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF2196F3), Color(0xFF102C57)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.person_add_alt_1, size: 36, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Judul
                        const Text(
                          "Buat Akun Baru",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Pilihan Peran: Admin atau Guru
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedRole = "Admin";
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == "Admin"
                                          ? const Color(0xFF2196F3)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "Admin",
                                      style: TextStyle(
                                        color: _selectedRole == "Admin"
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedRole = "Guru";
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == "Guru"
                                          ? const Color(0xFF2196F3)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "Guru",
                                      style: TextStyle(
                                        color: _selectedRole == "Guru"
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Nama Lengkap
                              TextFormField(
                                controller: _nameController,
                                validator: _validateName,
                                decoration: _buildInputDecoration(
                                  hint: "Nama Lengkap",
                                  icon: Icons.person_outline_rounded,
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (_selectedRole == "Admin") ...[
                                // Username
                                TextFormField(
                                  controller: _usernameController,
                                  validator: _validateUsername,
                                  decoration: _buildInputDecoration(
                                    hint: "Username",
                                    icon: Icons.badge_outlined,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Email (Opsional)
                                TextFormField(
                                  controller: _emailController,
                                  validator: _validateEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _buildInputDecoration(
                                    hint: "Email (Opsional)",
                                    icon: Icons.alternate_email_rounded,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ] else ...[
                                // NIP
                                TextFormField(
                                  controller: _nipController,
                                  validator: _validateNip,
                                  keyboardType: TextInputType.number,
                                  decoration: _buildInputDecoration(
                                    hint: "NIP (Nomor Induk Pegawai)",
                                    icon: Icons.badge_outlined,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Password
                              TextFormField(
                                controller: _passController,
                                validator: _validatePassword,
                                obscureText: _obscurePassword,
                                decoration: _buildInputDecoration(
                                  hint: "Password",
                                  icon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.grey.shade500,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Konfirmasi Password
                              TextFormField(
                                controller: _confirmPassController,
                                validator: _validateConfirmPassword,
                                obscureText: _obscureConfirmPassword,
                                decoration: _buildInputDecoration(
                                  hint: "Konfirmasi Password",
                                  icon: Icons.lock_clock_outlined,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.grey.shade500,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Tombol Register
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Daftarkan Akun",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Link ke halaman login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Sudah memiliki akun? ",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                "Masuk disini",
                                style: TextStyle(
                                  color: Color(0xFF2196F3),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 15,
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.grey.shade500,
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 16,
      ),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF2196F3),
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.8,
        ),
      ),
    );
  }
}
