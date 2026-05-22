import 'package:flutter/material.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!value.contains('@')) {
      return 'Masukkan email yang valid';
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

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // Simulate secure authorization handshake delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF102C57), // Sleek Navy Blue
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ===== BAGIAN LOGO YANG DIUBAH =====
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.mosque, size: 0),
                      Image.asset( 
                        'assets/logo.png', // <--- Sesuaikan dengan nama folder YAML
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 60, color: Color(0xFF102C57));
                        },
                      ),
                    ],
                  ),
                ),
                // ===================================
                const SizedBox(height: 20),
                const Text(
                  "Absensi Madrasah",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Gerbang Pengendali Admin Madrasah",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        validator: _validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF102C57)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Color(0xFF102C57), width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passController,
                        validator: _validatePassword,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF102C57)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Color(0xFF102C57), width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF102C57),
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
                      : const Text("MASUK SEKARANG", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}