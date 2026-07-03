import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/system_service.dart';

class IdentitasSekolahPage extends StatefulWidget {
  const IdentitasSekolahPage({super.key});

  @override
  State<IdentitasSekolahPage> createState() => _IdentitasSekolahPageState();
}

class _IdentitasSekolahPageState extends State<IdentitasSekolahPage> with SingleTickerProviderStateMixin {
  final SystemService _systemService = SystemService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _npsnController;
  late TextEditingController _addressController;

  // Real-time server diagnostics state
  Timer? _pingTimer;
  bool _isServerConnected = false;
  int _pingLatency = 0;
  bool _isPinging = false;
  bool _isSyncing = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _systemService.schoolName);
    _npsnController = TextEditingController(text: _systemService.schoolNpsn);
    _addressController = TextEditingController(text: _systemService.schoolAddress);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pingServer();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _pingServer();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _npsnController.dispose();
    _addressController.dispose();
    _pingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pingServer() async {
    if (_isPinging) return;
    if (mounted) setState(() => _isPinging = true);
    
    final stopwatch = Stopwatch()..start();
    try {
      if (_systemService.isFirebaseAvailable) {
        // Ping Firebase Firestore by getting metadata/school doc
        await FirebaseFirestore.instance.collection('metadata').doc('school').get().timeout(const Duration(seconds: 3));
        stopwatch.stop();
        if (mounted) {
          setState(() {
            _isServerConnected = true;
            _pingLatency = stopwatch.elapsedMilliseconds;
          });
        }
      } else {
        // Fallback to local server ping
        final response = await http
            .get(Uri.parse('${_systemService.baseUrl}/get_school_identity.php'))
            .timeout(const Duration(seconds: 3));
        stopwatch.stop();
        if (mounted) {
          setState(() {
            _isServerConnected = response.statusCode == 200;
            _pingLatency = stopwatch.elapsedMilliseconds;
          });
        }
      }
    } catch (_) {
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _isServerConnected = false;
          _pingLatency = 0;
        });
      }
    } finally {
      if (mounted) setState(() => _isPinging = false);
    }
  }

  Future<void> _triggerManualSync() async {
    if (_isSyncing) return;
    if (mounted) setState(() => _isSyncing = true);

    await _systemService.refresh();
    await _pingServer();

    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(_isServerConnected ? Icons.cloud_done : Icons.cloud_off, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_isServerConnected 
                    ? "Sinkronisasi berhasil! Data terhubung dengan server."
                    : "Sinkronisasi selesai menggunakan cache lokal (Server Offline)."),
              ),
            ],
          ),
          backgroundColor: _isServerConnected ? const Color(0xFF10B981) : Colors.amber[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102C57),
        foregroundColor: Colors.white,
        title: const Text("Identitas Sekolah & Diagnostik Server"),
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 950;
          
          final formWidget = Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15)],
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              'assets/logo_login.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF047857)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.trending_up_rounded,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Konfigurasi Parameter Sekolah",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                        ),
                        const Text(
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
                      labelText: "Nama Sekolah / Madrasah",
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
                      labelText: "Alamat Lengkap Sekolah",
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? "Alamat sekolah tidak boleh kosong" : null,
                  ),
                  const SizedBox(height: 20),



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
          );

          final diagnosticWidget = Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15)],
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Diagnostik
                const Row(
                  children: [
                    Icon(Icons.analytics_outlined, color: Color(0xFF1D4ED8), size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Diagnostik Server Real-time",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _systemService.isFirebaseAvailable 
                      ? "Status koneksi aplikasi ke Firebase Cloud Database"
                      : "Status koneksi aplikasi ke server database online",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Card Koneksi Real-time
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isServerConnected 
                        ? const Color(0xFFD1FAE5).withValues(alpha: 0.3)
                        : const Color(0xFFFEE2E2).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isServerConnected 
                          ? const Color(0xFF10B981).withValues(alpha: 0.2)
                          : const Color(0xFFEF4444).withValues(alpha: 0.2)
                    ),
                  ),
                  child: Row(
                    children: [
                      // Pulsing Status Dot
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: 0.4 + (_pulseController.value * 0.6),
                            child: Transform.scale(
                              scale: 0.9 + (_pulseController.value * 0.2),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isServerConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            boxShadow: [
                              BoxShadow(
                                color: (_isServerConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isServerConnected 
                                  ? (_systemService.isFirebaseAvailable ? "KONEKSI FIREBASE AKTIF" : "KONEKSI AKTIF (ONLINE)") 
                                  : "KONEKSI TERPUTUS (OFFLINE)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _isServerConnected ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isServerConnected 
                                  ? (_systemService.isFirebaseAvailable ? "Terhubung ke Firebase Cloud Firestore" : "Terhubung ke database online")
                                  : (_systemService.isFirebaseAvailable ? "Database Firebase tidak merespon" : "Server database online tidak merespon"),
                              style: TextStyle(
                                fontSize: 11,
                                color: _isServerConnected ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isServerConnected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${_pingLatency} ms",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Detail Server
                const Text(
                  "Parameter Server & API",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                ),
                const SizedBox(height: 12),
                if (!_systemService.isFirebaseAvailable) ...[
                  _buildDiagnosticRow("IP Server Database", _systemService.ipAddress, Icons.dns),
                  _buildDiagnosticRow("Base API URL", _systemService.baseUrl, Icons.link),
                ],
                _buildDiagnosticRow("Metode Sinkronisasi", "Auto Polling (5 Detik)", Icons.sync_alt),
                const SizedBox(height: 24),

                // Data local cache status
                const Text(
                  "Data Ter-Cache Lokal (Offline)",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDataCounter("Siswa", _systemService.siswaList.length, Icons.people_outline)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDataCounter("Guru", _systemService.guruList.length, Icons.badge_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDataCounter("Log Absen", _systemService.logs.length, Icons.history)),
                  ],
                ),
                const SizedBox(height: 32),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isPinging ? null : _pingServer,
                        icon: _isPinging 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.network_check),
                        label: const Text("TEST PING", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSyncing ? null : _triggerManualSync,
                        icon: _isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.sync),
                        label: const Text("SINKRONKAN", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: formWidget),
                          const SizedBox(width: 24),
                          Expanded(flex: 5, child: diagnosticWidget),
                        ],
                      )
                    : Column(
                        children: [
                          formWidget,
                          const SizedBox(height: 24),
                          diagnosticWidget,
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCounter(String label, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF102C57)),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
