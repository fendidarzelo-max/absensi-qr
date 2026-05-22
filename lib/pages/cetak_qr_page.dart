import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/system_service.dart';

class CetakQRPage extends StatefulWidget {
  const CetakQRPage({super.key});

  @override
  State<CetakQRPage> createState() => _CetakQRPageState();
}

class _CetakQRPageState extends State<CetakQRPage> {
  final SystemService _systemService = SystemService();
  String _selectedType = "Siswa"; // Siswa or Guru
  String? _selectedId; // NISN or NIP
  String _searchQuery = "";

  void _printQR(String name, String id) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Small label format for QR code
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  _systemService.schoolName.toUpperCase(),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.BarcodeWidget(
                  data: id,
                  barcode: pw.Barcode.qrCode(),
                  width: 120,
                  height: 120,
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  name,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  "$_selectedType ID: $id",
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: "QR_Code_$name",
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the list based on type
    final List<MapEntry<String, String>> items = [];
    if (_selectedType == "Siswa") {
      final filteredList = _systemService.siswaList.where((s) =>
        s.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.nisn.contains(_searchQuery)
      ).toList();
      for (var s in filteredList) {
        items.add(MapEntry(s.nisn, "${s.nama} (${s.kelas})"));
      }
    } else {
      final filteredList = _systemService.guruList.where((g) =>
        g.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        g.nip.contains(_searchQuery)
      ).toList();
      for (var g in filteredList) {
        items.add(MapEntry(g.nip, "${g.nama} (${g.mapel})"));
      }
    }

    // Selected item name lookup
    String selectedName = "";
    if (_selectedId != null) {
      if (_selectedType == "Siswa") {
        final matches = _systemService.siswaList.where((s) => s.nisn == _selectedId);
        if (matches.isNotEmpty) selectedName = matches.first.nama;
      } else {
        final matches = _systemService.guruList.where((g) => g.nip == _selectedId);
        if (matches.isNotEmpty) selectedName = matches.first.nama;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102C57),
        foregroundColor: Colors.white,
        title: const Text("Cetak QR Code Kredensial"),
        elevation: 0,
      ),
      body: Row(
        children: [
          // Left column: list of entities
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pilih Siswa / Guru",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                  ),
                  const SizedBox(height: 12),
                  // Segmented control (Siswa / Guru)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedType = "Siswa";
                                _selectedId = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedType == "Siswa" ? const Color(0xFF102C57) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  "Siswa",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedType == "Siswa" ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedType = "Guru";
                                _selectedId = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedType == "Guru" ? const Color(0xFF102C57) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  "Guru / Staf",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedType == "Guru" ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search field
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.15)),
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: "Cari berdasarkan nama atau ID...",
                        border: InputBorder.none,
                        icon: Icon(Icons.search, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // List
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isSelected = _selectedId == item.key;
                          return ListTile(
                            leading: Icon(
                              _selectedType == "Siswa" ? Icons.school : Icons.badge,
                              color: isSelected ? const Color(0xFF102C57) : Colors.grey,
                            ),
                            title: Text(item.value, style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text("ID: ${item.key}", style: const TextStyle(fontSize: 11)),
                            selected: isSelected,
                            selectedTileColor: const Color(0xFF102C57).withOpacity(0.05),
                            onTap: () {
                              setState(() {
                                _selectedId = item.key;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right column: Preview QR Code
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: _selectedId == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Pilih Siswa atau Guru\nuntuk melihat QR Code",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedType == "Siswa" ? "QR CODE SISWA" : "QR CODE GURU",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF102C57)),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "ID: $_selectedId",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 32),
                      
                      // QR Image Render
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: SizedBox(
                          width: 180,
                          height: 180,
                          child: Center(
                            child: RepaintBoundary(
                              child: Container(
                                color: Colors.white,
                                child: Image.network(
                                  "https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=$_selectedId",
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const CircularProgressIndicator(color: Color(0xFF102C57));
                                  },
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code, size: 100),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _printQR(selectedName, _selectedId!),
                          icon: const Icon(Icons.print, color: Colors.white),
                          label: const Text("CETAK QR CODE", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF102C57),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
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
}
