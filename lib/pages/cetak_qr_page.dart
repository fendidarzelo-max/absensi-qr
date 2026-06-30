import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/system_service.dart';
import '../models/siswa.dart';

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

  Widget _buildTypeSelector() {
    return Container(
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
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: const InputDecoration(
          hintText: "Cari berdasarkan nama atau ID...",
          border: InputBorder.none,
          icon: Icon(Icons.search, size: 20),
        ),
      ),
    );
  }

  Widget _buildEntityList(bool isMobile) {
    if (_selectedType == "Siswa") {
      final filteredList = _systemService.siswaList.where((s) =>
        s.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.nisn.contains(_searchQuery) ||
        s.kelas.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();

      if (filteredList.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text("Siswa tidak ditemukan", style: TextStyle(color: Colors.grey)),
          ),
        );
      }

      // Group by kelas
      final Map<String, List<Siswa>> grouped = {};
      for (var s in filteredList) {
        final cls = s.kelas.isEmpty ? "Tanpa Kelas" : s.kelas;
        grouped.putIfAbsent(cls, () => []).add(s);
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: ListView.builder(
          itemCount: grouped.keys.length,
          itemBuilder: (context, index) {
            final className = grouped.keys.elementAt(index);
            final siswaInClass = grouped[className]!;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              child: ExpansionTile(
                initiallyExpanded: _searchQuery.isNotEmpty || index == 0,
                shape: const Border(),
                title: Text(
                  className,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                ),
                leading: const Icon(Icons.class_outlined, color: Color(0xFF102C57)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102C57).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${siswaInClass.length} Siswa",
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                  ),
                ),
                children: siswaInClass.map((Siswa s) {
                  final isSelected = _selectedId == s.nisn;
                  return Column(
                    children: [
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? const Color(0xFF102C57) : Colors.grey[200],
                          radius: 16,
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                        title: Text(s.nama, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                        subtitle: Text("NISN: ${s.nisn}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        selected: isSelected,
                        selectedTileColor: const Color(0xFF102C57).withValues(alpha: 0.05),
                        onTap: () {
                          setState(() {
                            _selectedId = s.nisn;
                          });
                          if (isMobile) {
                            _showQRCodeBottomSheet(context, s.nisn, "${s.nama} (${s.kelas})");
                          }
                        },
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      );
    } else {
      final filteredList = _systemService.guruList.where((g) =>
        g.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        g.nip.contains(_searchQuery)
      ).toList();

      if (filteredList.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text("Guru tidak ditemukan", style: TextStyle(color: Colors.grey)),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: ListView.separated(
          itemCount: filteredList.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final g = filteredList[index];
            final isSelected = _selectedId == g.nip;
            return ListTile(
              leading: Icon(
                Icons.badge,
                color: isSelected ? const Color(0xFF102C57) : Colors.grey,
              ),
              title: Text(g.nama, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text("NIP: ${g.nip} • ${g.mapel}", style: const TextStyle(fontSize: 11)),
              selected: isSelected,
              selectedTileColor: const Color(0xFF102C57).withValues(alpha: 0.05),
              onTap: () {
                setState(() {
                  _selectedId = g.nip;
                });
                if (isMobile) {
                  _showQRCodeBottomSheet(context, g.nip, "${g.nama} (${g.mapel})");
                }
              },
            );
          },
        ),
      );
    }
  }

  void _showQRCodeBottomSheet(BuildContext context, String id, String fullName) {
    final nameOnly = fullName.contains(" (") ? fullName.split(" (").first : fullName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                _selectedType == "Siswa" ? "QR CODE SISWA" : "QR CODE GURU",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                nameOnly,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF102C57)),
                textAlign: TextAlign.center,
              ),
              Text(
                "ID: $id",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: Center(
                    child: Image.network(
                      "https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=$id",
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const CircularProgressIndicator(color: Color(0xFF102C57));
                      },
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code, size: 100),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _printQR(nameOnly, id);
                  },
                  icon: const Icon(Icons.print, color: Colors.white),
                  label: const Text("CETAK QR CODE", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF102C57),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQRPreviewPanel(String selectedName) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15)],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
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
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
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

    final bool isMobile = MediaQuery.of(context).size.width < 750;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102C57),
        foregroundColor: Colors.white,
        title: const Text("Cetak QR Code Kredensial"),
        elevation: 0,
      ),
      body: isMobile
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pilih Siswa / Guru",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                  ),
                  const SizedBox(height: 12),
                  _buildTypeSelector(),
                  const SizedBox(height: 12),
                  _buildSearchField(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildEntityList(isMobile),
                  ),
                ],
              ),
            )
          : Row(
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
                        _buildTypeSelector(),
                        const SizedBox(height: 16),
                        _buildSearchField(),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _buildEntityList(isMobile),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Right column: Preview QR Code
                Expanded(
                  flex: 3,
                  child: _buildQRPreviewPanel(selectedName),
                ),
              ],
            ),
    );
  }
}
