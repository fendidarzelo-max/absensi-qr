import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/system_service.dart';
import '../models/siswa.dart';
import '../models/guru.dart';


class AbsensiQRPage extends StatefulWidget {
  final bool isGuru;
  const AbsensiQRPage({super.key, required this.isGuru});

  @override
  State<AbsensiQRPage> createState() => _AbsensiQRPageState();
}

class _AbsensiQRPageState extends State<AbsensiQRPage> {
  bool _isScanning = false;
  String _scanResult = "";
  bool _hasScanned = false;
  MobileScannerController? _scannerController;
  final SystemService _systemService = SystemService();
  final TextEditingController _simulateController = TextEditingController();
  Siswa? _scannedSiswa;
  Guru? _scannedGuru;
  bool _scanSuccess = false;
  String _scanErrorMsg = "";
  
  // Simulation list for ease of testing
  String? _selectedSimulateCode;
  int _selectedJam = 1;

  final StringBuffer _scannerBuffer = StringBuffer();

  bool _onGlobalKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        final scannedCode = _scannerBuffer.toString().trim();
        if (scannedCode.isNotEmpty) {
          _scannerBuffer.clear();
          _processScan(scannedCode);
        }
      } else {
        final char = event.character;
        if (char != null && RegExp(r'[a-zA-Z0-9]').hasMatch(char)) {
          _scannerBuffer.write(char);
        }
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    // Register listener for peripheral status
    _systemService.addListener(_onSystemStateChanged);
    HardwareKeyboard.instance.addHandler(_onGlobalKeyEvent);
  }

  @override
  void dispose() {
    _systemService.removeListener(_onSystemStateChanged);
    HardwareKeyboard.instance.removeHandler(_onGlobalKeyEvent);
    _scannerController?.dispose();
    _simulateController.dispose();
    super.dispose();
  }

  void _onSystemStateChanged() {
    if (mounted) setState(() {});
  }

  void _startScanning() {
    if (!_systemService.isPeripheralConnected) {
      _showErrorSnackBar("Scanner USB Terputus! Pastikan periferal terhubung.");
      return;
    }
    setState(() {
      _isScanning = true;
      _hasScanned = false;
      _scanResult = "";
      _scannedSiswa = null;
      _scannedGuru = null;
      _scanSuccess = false;
      _scanErrorMsg = "";
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    });
  }

  void _stopScanning() {
    _scannerController?.stop();
    setState(() {
      _isScanning = false;
    });
  }

  void _resetScan() {
    _scannerController?.dispose();
    setState(() {
      _scanResult = "";
      _hasScanned = false;
      _isScanning = false;
      _selectedSimulateCode = null;
      _simulateController.clear();
      _scannedSiswa = null;
      _scannedGuru = null;
      _scanSuccess = false;
      _scanErrorMsg = "";
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _hasScanned = true;
        _scannerController?.stop();
        _processScan(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _processScan(String code) async {
    final cleanCode = code.trim();
    
    // Reset state for new scan
    setState(() {
      _scannedSiswa = null;
      _scannedGuru = null;
      _scanSuccess = false;
      _scanErrorMsg = "";
      _scanResult = "";
    });

    // Validasi apakah terdaftar di database Guru/Siswa
    if (widget.isGuru) {
      final guruIndex = _systemService.guruList.indexWhere((g) => g.nip.trim() == cleanCode);
      if (guruIndex == -1) {
        if (!mounted) return;
        setState(() {
          _hasScanned = true;
          _isScanning = false;
          _scanSuccess = false;
          _scanErrorMsg = "Tidak terdaftar di database Guru.";
          _scanResult = "GAGAL!\n\nID: $cleanCode\nTidak terdaftar di database Guru.";
        });
        return;
      }
      _scannedGuru = _systemService.guruList[guruIndex];
    } else {
      final siswaIndex = _systemService.siswaList.indexWhere((s) => s.nisn.trim() == cleanCode);
      if (siswaIndex == -1) {
        if (!mounted) return;
        setState(() {
          _hasScanned = true;
          _isScanning = false;
          _scanSuccess = false;
          _scanErrorMsg = "Tidak terdaftar di database Siswa.";
          _scanResult = "GAGAL!\n\nID: $cleanCode\nTidak terdaftar di database Siswa.";
        });
        return;
      }
      _scannedSiswa = _systemService.siswaList[siswaIndex];
    }

    // Check maximum hours/sessions allowed for class before recording attendance
    if (!widget.isGuru && _scannedSiswa != null) {
      final s = _scannedSiswa!;
      if (s.kelas.isNotEmpty) {
        final maxHours = _systemService.getMaxHoursForKelas(s.kelas);
        if (_selectedJam > maxHours) {
          if (!mounted) return;
          setState(() {
            _hasScanned = true;
            _isScanning = false;
            _scanSuccess = false;
            _scanErrorMsg = "Kelas ini hanya sampai Jam Ke-$maxHours.";
            _scanResult = "GAGAL!\n\nNama: ${s.nama}\nKelas: ${s.kelasDisplay}\nKelas ini hanya sampai Jam Ke-$maxHours.";
          });
          return;
        }
      }
    }

    // Record in global state
    final success = await _systemService.recordAttendance(cleanCode, widget.isGuru, jamKe: _selectedJam);
    
    if (!mounted) return;
    setState(() {
      _hasScanned = true;
      _isScanning = false;
      _scanSuccess = success;
      if (success) {
        if (widget.isGuru) {
          _scanResult = "BERHASIL ABSEN GURU!\n\nNama: ${_scannedGuru?.nama}\nStatus: Terdaftar";
        } else {
          _scanResult = "BERHASIL ABSEN!\n\nNama: ${_scannedSiswa?.nama}\nKelas: ${_scannedSiswa?.kelasDisplay}\nID: $cleanCode\nStatus: Terdaftar";
        }
      } else {
        if (!_systemService.isPeripheralConnected) {
          _scanErrorMsg = "Scanner USB Terputus.";
          _scanResult = "GAGAL!\n\nScanner USB Terputus.";
        } else {
          _scanErrorMsg = "Tidak terdaftar di database.";
          _scanResult = "GAGAL!\n\nID: $cleanCode\nTidak terdaftar di database.";
        }
      }
    });
  }

  Widget _buildScanResultWidget() {
    final isSuccess = _scanSuccess;
    
    if (isSuccess) {
      final name = widget.isGuru ? (_scannedGuru?.nama ?? "") : (_scannedSiswa?.nama ?? "");
      final idText = widget.isGuru ? "NIP: ${_scannedGuru?.nip}" : "NISN: ${_scannedSiswa?.nisn}";
      
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF34D399), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF059669), size: 14),
                SizedBox(width: 4),
                Text(
                  "BERHASIL ABSEN",
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Photo/Avatar Frame
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF10B981), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ]
            ),
            child: widget.isGuru
                ? CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF102C57).withOpacity(0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "?",
                      style: const TextStyle(
                        fontSize: 24,
                        color: Color(0xFF102C57),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : _buildSiswaPhoto(_scannedSiswa),
          ),
          const SizedBox(height: 8),
          
          // Name and ID
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            idText,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          
          // Details Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                if (!widget.isGuru) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Kelas", style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                      Text(
                        _scannedSiswa?.kelasDisplay ?? "-",
                        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Divider(height: 8),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Jabatan", style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                      Text(
                        _scannedGuru?.jabatan ?? "-",
                        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Divider(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Jam Ke", style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    Text(
                      "$_selectedJam",
                      style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Error result
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Error Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error, color: Color(0xFFDC2626), size: 14),
                SizedBox(width: 4),
                Text(
                  "GAGAL ABSEN",
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Warning Circle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEF4444),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          
          // Error Message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _scanErrorMsg.isNotEmpty ? _scanErrorMsg : "Kode QR tidak terdaftar.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _scanResult.split('\n\n').last, // ID details
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSiswaPhoto(Siswa? s) {
    if (s != null && s.fotoPath != null && s.fotoPath!.isNotEmpty) {
      try {
        final file = File(s.fotoPath!);
        if (file.existsSync()) {
          return ClipOval(
            child: Image.file(
              file,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          );
        }
      } catch (e) {
        debugPrint("Error loading siswa photo: $e");
      }
    }
    return CircleAvatar(
      radius: 36,
      backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
      child: Text(
        (s?.nama.isNotEmpty == true) ? s!.nama[0].toUpperCase() : "?",
        style: const TextStyle(
          fontSize: 24,
          color: Color(0xFF10B981),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isGuru ? "Absensi Scan Guru" : "Absensi Scan Murid";
    final labelTipe = widget.isGuru ? "Guru / Staf" : "Siswa / Murid";
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102C57),
        foregroundColor: Colors.white,
        title: Text(title),
        elevation: 0,
        actions: [
          // Connection simulation toggle directly in the UI
          Row(
            children: [
              Text(
                _systemService.isPeripheralConnected ? "Scanner Active" : "Scanner Off", 
                style: const TextStyle(fontSize: 12),
              ),
              Switch(
                value: _systemService.isPeripheralConnected,
                activeThumbColor: const Color(0xFF10B981),
                inactiveThumbColor: Colors.red,
                onChanged: (val) {
                  _systemService.setPeripheralConnection(val);
                },
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Peripheral Status Info
              Container(
                width: 320,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _systemService.isPeripheralConnected 
                      ? const Color(0xFF10B981).withValues(alpha: 0.3) 
                      : Colors.red.withValues(alpha: 0.3)
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _systemService.isPeripheralConnected ? const Color(0xFF10B981) : Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _systemService.isPeripheralConnected ? const Color(0xFF10B981) : Colors.red,
                            blurRadius: 6,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _systemService.isPeripheralConnected 
                          ? "Hardware Scanner USB: Terhubung" 
                          : "Hardware Scanner USB: Terputus",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _systemService.isPeripheralConnected ? const Color(0xFF102C57) : Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Jam Absensi selector (only for students, since isGuru doesn't have it)
              if (!widget.isGuru) ...[
                const Text(
                  "Pilih Sesi Jam Absensi:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102C57),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [1, 2, 3].map((jam) {
                      final isSelected = _selectedJam == jam;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedJam = jam;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF102C57) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Jam Ke-$jam",
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Scanning Container
              Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _isScanning
                    ? Stack(
                        children: [
                          MobileScanner(
                            controller: _scannerController,
                            onDetect: _onDetect,
                          ),
                          // High-tech scanning overlay
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF102C57), width: 2),
                            ),
                          ),
                          const Center(
                            child: Icon(Icons.qr_code_scanner, size: 200, color: Colors.white24),
                          ),
                          // Simulated scanning animation line
                          const _ScanningLine(),
                        ],
                      )
                    : _scanResult.isNotEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildScanResultWidget(),
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text("Siap Memindai QR Code", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                              Text("Gunakan kamera atau simulasi di bawah", style: TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Scanning controls
              SizedBox(
                width: 320,
                height: 55,
                child: ElevatedButton(
                  onPressed: !_systemService.isPeripheralConnected
                    ? null
                    : (_isScanning 
                      ? (_hasScanned ? null : () { _stopScanning(); _resetScan(); })
                      : (_scanResult.isNotEmpty ? _resetScan : _startScanning)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF102C57),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(
                    _isScanning 
                      ? (_hasScanned ? "BERHASIL!" : "HENTIKAN") 
                      : (_scanResult.isNotEmpty ? "SCAN ULANG" : "MULAI CAMERA PEMINDAIAN"),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

              // Simulation Panel (Simulasi Scanner Hardware)
              Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.terminal, size: 18, color: Color(0xFF102C57)),
                        SizedBox(width: 8),
                        Text(
                          "Simulasi Scanner USB",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF102C57)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Pilih $labelTipe untuk menyimulasikan pembacaan scan hardware secara langsung.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _simulateController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: widget.isGuru ? "Masukkan NIP Guru" : "Masukkan NISN Siswa",
                        hintText: widget.isGuru ? "Contoh: 19850101201001" : "Contoh: 009822314",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (val) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _simulateController.text.trim().isEmpty || !_systemService.isPeripheralConnected
                          ? null
                          : () {
                              _processScan(_simulateController.text.trim());
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("KIRIM PEMINDAIAN SIMULASI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),

              if (_scanResult.isNotEmpty || _isScanning) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _resetScan,
                  child: const Text("Reset Tampilan", style: TextStyle(color: Color(0xFF102C57), fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanningLine extends StatefulWidget {
  const _ScanningLine();

  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 320).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: _animation.value,
          left: 0,
          right: 0,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: Colors.red,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.8),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
