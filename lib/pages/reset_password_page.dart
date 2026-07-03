import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/system_service.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  Offset? _mousePosition;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username atau NIP tidak boleh kosong';
    }
    if (value.trim().length < 3) {
      return 'Masukkan minimal 3 karakter';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Masukkan format email yang valid';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password baru tidak boleh kosong';
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
    if (value != _newPassController.text) {
      return 'Password konfirmasi tidak cocok';
    }
    return null;
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final newPassword = _newPassController.text;

      try {
        final systemService = SystemService();

        // 1. If Firebase is available, reset password directly in Firestore
        if (systemService.isFirebaseAvailable) {
          final firestore = FirebaseFirestore.instance;

          // Attempt to find in Admin first
          final adminSnapshot = await firestore.collection('admin').get();
          QueryDocumentSnapshot? targetDoc;
          String matchedRole = 'admin';

          for (var doc in adminSnapshot.docs) {
            final data = doc.data();
            final docEmail = (data['email'] as String? ?? '').toLowerCase();
            final docUsername = (data['username'] as String? ?? '').toLowerCase();
            final docNama = (data['nama_lengkap'] as String? ?? '').toLowerCase();

            if (docEmail == email.toLowerCase() &&
                (docUsername == username.toLowerCase() || docNama == username.toLowerCase())) {
              targetDoc = doc;
              matchedRole = 'admin';
              break;
            }
          }

          // If not found in Admin, search in Guru
          if (targetDoc == null) {
            final guruSnapshot = await firestore.collection('guru').get();
            for (var doc in guruSnapshot.docs) {
              final data = doc.data();
              final docEmail = (data['email'] as String? ?? '').toLowerCase();
              final docNip = (data['nip'] as String? ?? '').toLowerCase();
              final docNama = (data['nama_guru'] as String? ?? data['nama'] as String? ?? '').toLowerCase();

              if (docEmail == email.toLowerCase() &&
                  (docNip == username.toLowerCase() || docNama == username.toLowerCase())) {
                targetDoc = doc;
                matchedRole = 'guru';
                break;
              }
            }
          }

          if (targetDoc != null) {
            await targetDoc.reference.update({'password': newPassword});
          } else {
            throw Exception("Akun tidak ditemukan atau email tidak sesuai.");
          }

          // Sync to local database / PHP backend in background if they have it
          try {
            await http.post(
              Uri.parse('${systemService.baseUrl}/reset_password.php'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'username': username,
                'email': email,
                'role': matchedRole,
                'new_password': newPassword,
              }),
            ).timeout(const Duration(seconds: 3));
          } catch (e) {
            debugPrint("Sync reset password ke database gagal (diabaikan karena Firebase sukses): $e");
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(child: Text("Reset password berhasil di Firebase")),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.pop(context);
          }
          return;
        }

        // 2. Fallback to local PHP API / XAMPP if Firebase is not active
        final response = await http
            .post(
              Uri.parse('${systemService.baseUrl}/reset_password.php'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'username': username,
                'email': email,
                'new_password': newPassword,
              }),
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
                      const Icon(Icons.check_circle_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text(resData['message'] ?? "Reset password berhasil")),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
              Navigator.pop(context);
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text(resData['message'] ?? "Reset password gagal")),
                    ],
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        } else {
          throw Exception("Server error: ${response.statusCode}");
        }
      } catch (e) {
        debugPrint("Koneksi reset password gagal: $e");
        if (mounted) {
          String errorMessage = "Gagal terhubung ke database. Silakan periksa koneksi internet Anda.";
          if (e.toString().contains("tidak ditemukan") || e.toString().contains("tidak sesuai")) {
            errorMessage = e.toString().replaceAll("Exception: ", "");
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errorMessage)),
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

            // Konten Form Reset Password
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tombol Back
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(50),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_back_rounded, color: Colors.grey.shade700, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Kembali",
                                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Logo / Ikon Reset
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              size: 48,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Judul Halaman
                        const Text(
                          "Reset Password",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Masukkan detail akun Anda untuk memperbarui kata sandi.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),

                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Username / NIP Field
                              TextFormField(
                                controller: _usernameController,
                                validator: _validateUsername,
                                keyboardType: TextInputType.text,
                                style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
                                decoration: InputDecoration(
                                  hintText: "Username / NIP",
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    color: Colors.grey.shade500,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.8),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                validator: _validateEmail,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
                                decoration: InputDecoration(
                                  hintText: "Email Terdaftar",
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                                  prefixIcon: Icon(Icons.alternate_email_rounded, color: Colors.grey.shade500),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.8),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // New Password Field
                              TextFormField(
                                controller: _newPassController,
                                validator: _validateNewPassword,
                                obscureText: _obscureNewPass,
                                style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
                                decoration: InputDecoration(
                                  hintText: "Password Baru",
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                                  prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.grey.shade500),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: Colors.grey.shade500,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureNewPass = !_obscureNewPass;
                                      });
                                    },
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.8),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Confirm Password Field
                              TextFormField(
                                controller: _confirmPassController,
                                validator: _validateConfirmPassword,
                                obscureText: _obscureConfirmPass,
                                style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
                                decoration: InputDecoration(
                                  hintText: "Konfirmasi Password Baru",
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                                  prefixIcon: Icon(Icons.lock_rounded, color: Colors.grey.shade500),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: Colors.grey.shade500,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPass = !_obscureConfirmPass;
                                      });
                                    },
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.8),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Reset Password Button
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleResetPassword,
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
                                          "Reset Password",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
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
}
