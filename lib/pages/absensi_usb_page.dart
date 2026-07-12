import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/system_service.dart';
import '../models/guru.dart';

class AbsensiUsbPage extends StatefulWidget {
  const AbsensiUsbPage({super.key});

  @override
  State<AbsensiUsbPage> createState() => _AbsensiUsbPageState();
}

class _AbsensiUsbPageState extends State<AbsensiUsbPage> {
  final SystemService _systemService = SystemService();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isProcessing = false;
  String _statusMessage = "Siap memindai kartu Guru...";
  bool? _isSuccess;
  String _scannedName = "";
  String _scannedRole = "";
  String _scannedDetail = "";
  
  // List to display the recent scans in this session
  final List<Map<String, dynamic>> _sessionLogs = [];
  Timer? _resetTimer;
  Timer? _refocusTimer;

  @override
  void initState() {
    super.initState();
    _systemService.addListener(_onSystemStateChanged);
    
    // Auto-focus setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestAutofocus();
    });

    // Periodically ensure focus is kept
    _refocusTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_focusNode.hasFocus && !_isProcessing) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _refocusTimer?.cancel();
    _systemService.removeListener(_onSystemStateChanged);
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSystemStateChanged() {
    if (mounted) setState(() {});
  }

  void _requestAutofocus() {
    if (mounted) {
      _focusNode.requestFocus();
    }
  }

  Future<void> _handleInputSubmitted(String value) async {
    final cleanCode = value.trim();
    if (cleanCode.isEmpty) return;

    _inputController.clear();
    _focusNode.requestFocus();

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = "Memproses kehadiran Guru...";
      _isSuccess = null;
      _scannedName = "";
      _scannedRole = "";
      _scannedDetail = "";
    });

    _resetTimer?.cancel();

    // 1. Identify Guru
    final guru = _systemService.guruList.firstWhere(
      (g) => g.nip.trim() == cleanCode,
      orElse: () => Guru(nip: "", nama: "", mapel: "", kelas: "", status: ""),
    );

    if (guru.nip.isEmpty) {
      // Not registered or not a Guru
      _showResult(
        success: false,
        name: cleanCode,
        role: "Tidak Dikenal",
        detail: "NIP/ID Kartu tidak terdaftar di database Guru.",
        message: "ID Guru Tidak Terdaftar!",
      );
      return;
    }

    final name = guru.nama;
    final roleLabel = "Guru / Staf";
    final detailLabel = "Mapel: ${guru.mapel} | NIP: ${guru.nip}";

    // 2. Record Attendance for Guru (isGuru = true)
    final success = await _systemService.recordAttendance(cleanCode, true);

    if (success) {
      _showResult(
        success: true,
        name: name,
        role: roleLabel,
        detail: detailLabel,
        message: "Selamat Datang, Guru!",
      );
    } else {
      _showResult(
        success: false,
        name: name,
        role: roleLabel,
        detail: "Gagal melakukan absensi guru.",
        message: "Gagal Menyimpan Kehadiran!",
      );
    }
  }

  void _showResult({
    required bool success,
    required String name,
    required String role,
    required String detail,
    required String message,
  }) {
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _isSuccess = success;
      _scannedName = name;
      _scannedRole = role;
      _scannedDetail = detail;
      _statusMessage = message;

      // Add to session log list (at the top)
      _sessionLogs.insert(0, {
        "name": name,
        "role": role,
        "detail": detail,
        "time": DateTime.now(),
        "success": success,
      });

      // Keep only last 10 logs
      if (_sessionLogs.length > 10) {
        _sessionLogs.removeLast();
      }
    });

    // Reset screen after 3 seconds
    _resetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isSuccess = null;
          _scannedName = "";
          _scannedRole = "";
          _scannedDetail = "";
          _statusMessage = "Siap memindai kartu Guru...";
        });
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 750;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102C57),
        foregroundColor: Colors.white,
        title: const Text("Kiosk Absensi Guru (USB Scanner)"),
        elevation: 0,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text("Online (Firebase)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left side: Scanner portal (Interactive area)
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  // Kiosk UI Card
                  Container(
                    width: 450,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Portal Scanner Ring Graphic
                        _buildScannerGraphic(),
                        const SizedBox(height: 24),

                        // Input field (hidden/styled nicely)
                        _buildScannerInputField(),
                        const SizedBox(height: 24),

                        // Scan Result card
                        _buildResultCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right side: Real-time scan list
          if (!isMobile)
            Expanded(
              flex: 4,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Icon(Icons.history, color: Color(0xFF102C57)),
                          SCompositeIcon(width: 8),
                          Text(
                            "Log Absensi Guru Terbaru",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _sessionLogs.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.crop_free, size: 48, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text("Belum ada absensi masuk", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _sessionLogs.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final log = _sessionLogs[index];
                                final timeString = "${log['time'].hour.toString().padLeft(2, '0')}:${log['time'].minute.toString().padLeft(2, '0')}:${log['time'].second.toString().padLeft(2, '0')}";
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: log['success'] ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: log['success'] 
                                        ? const Color(0xFFDCFCE7) 
                                        : const Color(0xFFFEE2E2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: log['success'] ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                        radius: 16,
                                        child: Icon(
                                          log['success'] ? Icons.check : Icons.close, 
                                          color: Colors.white, 
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    log['name'],
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  timeString,
                                                  style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace'),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "${log['role']} • ${log['detail']}",
                                              style: TextStyle(color: Colors.grey[700], fontSize: 11),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
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
            ),
        ],
      ),
    );
  }

  Widget _buildScannerGraphic() {
    Color ringColor = const Color(0xFF1D4ED8); // default blue
    if (_isSuccess != null) {
      ringColor = _isSuccess! ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    } else if (_isProcessing) {
      ringColor = const Color(0xFFEAB308); // warning yellow
    }

    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor.withValues(alpha: 0.05),
        border: Border.all(
          color: ringColor,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: ringColor.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: _isProcessing
            ? const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEAB308)),
                ),
              )
            : Icon(
                _isSuccess == null
                    ? Icons.qr_code_scanner
                    : (_isSuccess! ? Icons.check_circle : Icons.error),
                size: 72,
                color: ringColor,
              ),
      ),
    );
  }

  Widget _buildScannerInputField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focusNode.hasFocus ? const Color(0xFF1D4ED8) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _inputController,
        focusNode: _focusNode,
        autofocus: true,
        showCursor: true,
        textInputAction: TextInputAction.done,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 2,
          color: Color(0xFF102C57),
        ),
        decoration: InputDecoration(
          hintText: "Sorot kartu Guru di sini...",
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 13,
            letterSpacing: 0,
            fontWeight: FontWeight.normal,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
          suffixIcon: Icon(
            Icons.keyboard,
            color: _focusNode.hasFocus ? const Color(0xFF1D4ED8) : Colors.grey,
          ),
        ),
        onSubmitted: _handleInputSubmitted,
      ),
    );
  }

  Widget _buildResultCard() {
    Color cardColor = const Color(0xFFF8FAFC);
    Color textColor = Colors.black87;
    IconData icon = Icons.info_outline;

    if (_isSuccess != null) {
      if (_isSuccess!) {
        cardColor = const Color(0xFFF0FDF4); // Green success
        textColor = const Color(0xFF15803D);
        icon = Icons.check_circle;
      } else {
        cardColor = const Color(0xFFFEF2F2); // Red failure
        textColor = const Color(0xFFB91C1C);
        icon = Icons.error;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isSuccess == null 
              ? Colors.grey.withValues(alpha: 0.15) 
              : (_isSuccess! ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2)),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (_scannedName.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text(
              _scannedName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF102C57),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF102C57).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _scannedRole,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF102C57),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _scannedDetail,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class SCompositeIcon extends StatelessWidget {
  final double width;
  const SCompositeIcon({super.key, required this.width});
  @override
  Widget build(BuildContext context) => SizedBox(width: width);
}
