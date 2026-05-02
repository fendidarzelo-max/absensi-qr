import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AbsensiQRPage extends StatefulWidget {
  const AbsensiQRPage({super.key});

  @override
  State<AbsensiQRPage> createState() => _AbsensiQRPageState();
}

class _AbsensiQRPageState extends State<AbsensiQRPage> {
  bool _isScanning = false;
  String _scanResult = "";
  bool _hasScanned = false;
  MobileScannerController? _scannerController;

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _hasScanned = false;
      _scanResult = "";
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
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _hasScanned = true;
        _scannerController?.stop();
        
        final String code = barcode.rawValue!;
        // Parse QR code format: "Nama|Kelas" or just display the code
        List<String> parts = code.split('|');
        String displayText = parts.length >= 2 
          ? "Berhasil!\n${parts[0]}\nKelas ${parts[1]}"
          : "Berhasil!\n$code";
        
        setState(() {
          _scanResult = displayText;
        });
        break;
      }
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        title: const Text("Absensi Siswa QR"),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _isScanning
                    ? MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                      )
                    : _scanResult.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 60),
                              const SizedBox(height: 12),
                              Text(
                                _scanResult,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey),
                              SizedBox(height: 12),
                              Text("Siap Memindai", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 280,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isScanning 
                    ? (_hasScanned ? null : () { _stopScanning(); _resetScan(); })
                    : (_scanResult.isNotEmpty ? _resetScan : _startScanning),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(
                    _isScanning 
                      ? (_hasScanned ? "BERHASIL!" : "HENTIKAN") 
                      : (_scanResult.isNotEmpty ? "SCAN ULANG" : "MULAI PEMINDAIAN"),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (_scanResult.isNotEmpty || _isScanning) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _resetScan,
                  child: const Text("Reset"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
