import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/system_service.dart';

class CardColorScheme {
  final String name;
  final PdfColor primaryPdfColor;
  final PdfColor accentPdfColor;
  final Color primaryFlutterColor;
  final Color accentFlutterColor;

  const CardColorScheme({
    required this.name,
    required this.primaryPdfColor,
    required this.accentPdfColor,
    required this.primaryFlutterColor,
    required this.accentFlutterColor,
  });
}

const List<CardColorScheme> cardColorSchemes = [
  CardColorScheme(
    name: "Navy & Emas",
    primaryPdfColor: PdfColor.fromInt(0xFF102C57),
    accentPdfColor: PdfColor.fromInt(0xFFC5A880), // Gold
    primaryFlutterColor: Color(0xFF102C57),
    accentFlutterColor: Color(0xFFC5A880),
  ),
  CardColorScheme(
    name: "Emerald & Emas",
    primaryPdfColor: PdfColor.fromInt(0xFF0F5257),
    accentPdfColor: PdfColor.fromInt(0xFFC5A880), // Gold
    primaryFlutterColor: Color(0xFF0F5257),
    accentFlutterColor: Color(0xFFC5A880),
  ),
  CardColorScheme(
    name: "Burgundy & Emas",
    primaryPdfColor: PdfColor.fromInt(0xFF5C1A1B),
    accentPdfColor: PdfColor.fromInt(0xFFC5A880), // Gold
    primaryFlutterColor: Color(0xFF5C1A1B),
    accentFlutterColor: Color(0xFFC5A880),
  ),
  CardColorScheme(
    name: "Charcoal & Perak",
    primaryPdfColor: PdfColor.fromInt(0xFF2C3E50),
    accentPdfColor: PdfColor.fromInt(0xFFBDC3C7), // Silver/Grey
    primaryFlutterColor: Color(0xFF2C3E50),
    accentFlutterColor: Color(0xFFBDC3C7),
  ),
  CardColorScheme(
    name: "Biru & Emas",
    primaryPdfColor: PdfColor.fromInt(0xFF1A5276),
    accentPdfColor: PdfColor.fromInt(0xFFF1C40F), // Bright Gold
    primaryFlutterColor: Color(0xFF1A5276),
    accentFlutterColor: Color(0xFFF1C40F),
  ),
];

class CetakQRPage extends StatefulWidget {
  const CetakQRPage({super.key});

  @override
  State<CetakQRPage> createState() => _CetakQRPageState();
}

class _CetakQRPageState extends State<CetakQRPage> {
  final SystemService _systemService = SystemService();
  String _selectedType = "Siswa"; // Siswa or Guru
  String _searchQuery = "";
  String _exportFormat = "PDF"; // PDF or PNG
  final Set<String> _selectedIds = {};
  CardColorScheme _selectedScheme = cardColorSchemes[0]; // Default is Navy & Emas
  String _selectedClass = "Semua Kelas";

  List<String> get _classList {
    final classes = _systemService.siswaList
        .map((s) => s.kelas.trim())
        .where((k) => k.isNotEmpty)
        .toSet()
        .toList();
    classes.sort();
    return ["Semua Kelas", ...classes];
  }

  List<dynamic> get _filteredItems {
    if (_selectedType == "Siswa") {
      return _systemService.siswaList.where((s) {
        final matchesQuery = s.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.nisn.contains(_searchQuery) ||
            s.kelas.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesClass = _selectedClass == "Semua Kelas" || s.kelas.trim() == _selectedClass;
        return matchesQuery && matchesClass;
      }).toList();
    } else {
      return _systemService.guruList.where((g) =>
        g.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        g.nip.contains(_searchQuery)
      ).toList();
    }
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAllOnPage() {
    setState(() {
      for (var item in _filteredItems) {
        final String id = _selectedType == "Siswa" ? item.nisn : item.nip;
        _selectedIds.add(id);
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedIds.clear();
    });
  }

  List<dynamic> _getSelectedItems() {
    if (_selectedType == "Siswa") {
      return _systemService.siswaList.where((s) => _selectedIds.contains(s.nisn)).toList();
    } else {
      return _systemService.guruList.where((g) => _selectedIds.contains(g.nip)).toList();
    }
  }

  Future<void> _exportSelected() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Silakan pilih data $_selectedType terlebih dahulu"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await _exportAsPDF();
  }

  Future<void> _exportAsPDF() async {
    final pdf = pw.Document();
    final selectedItems = _getSelectedItems();
    const chunkSize = 9; // Fit 3 columns x 3 rows perfectly on A4

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_exportFormat == "PDF" ? "Menghasilkan PDF..." : "Menghasilkan PDF Polos..."),
              ],
            ),
          ),
        ),
      ),
    );

    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      debugPrint("Logo not found: $e");
    }

    final PdfColor primaryPdfColor = _selectedScheme.primaryPdfColor;
    final PdfColor accentPdfColor = _selectedScheme.accentPdfColor;

    try {
      for (var i = 0; i < selectedItems.length; i += chunkSize) {
        final chunk = selectedItems.sublist(
          i,
          i + chunkSize > selectedItems.length ? selectedItems.length : i + chunkSize,
        );

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.GridView(
                crossAxisCount: 3,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: chunk.map((item) {
                  final String name = item.nama;
                  final String id = _selectedType == "Siswa" ? item.nisn : item.nip;

                  if (_exportFormat == "PNG") {
                    // Plain design for PNG/Polos mode in A4 Sheet (Absolute Positioned)
                    return pw.Container(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        border: pw.Border.all(color: PdfColors.grey300, width: 1),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Stack(
                        children: [
                          // QR Code positioned in the upper center
                          pw.Positioned(
                            top: 25,
                            left: 0,
                            right: 0,
                            child: pw.Center(
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(4),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                                ),
                                child: pw.BarcodeWidget(
                                  data: id,
                                  barcode: pw.Barcode.qrCode(),
                                  width: 95,
                                  height: 95,
                                ),
                              ),
                            ),
                          ),
                          // Name & ID positioned at the bottom
                          pw.Positioned(
                            bottom: 25,
                            left: 10,
                            right: 10,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Text(
                                  name.toUpperCase(),
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                    color: PdfColors.black,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                  maxLines: 1,
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  "${_selectedType == 'Siswa' ? 'NISN' : 'NIP'}: $id",
                                  style: const pw.TextStyle(
                                    fontSize: 8.5,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Default Premium template using Absolute Positioning to prevent squishing overflow
                  return pw.Container(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      border: pw.Border.all(color: accentPdfColor, width: 1),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Stack(
                      children: [
                        // Decorative Top-left Navy semicircle
                        pw.Positioned(
                          top: 0,
                          left: 0,
                          child: pw.Container(
                            width: 25,
                            height: 25,
                            decoration: pw.BoxDecoration(
                              color: primaryPdfColor,
                              borderRadius: const pw.BorderRadius.only(
                                bottomRight: pw.Radius.circular(25),
                              ),
                            ),
                          ),
                        ),
                        // Decorative Top-right Navy semicircle
                        pw.Positioned(
                          top: 0,
                          right: 0,
                          child: pw.Container(
                            width: 25,
                            height: 25,
                            decoration: pw.BoxDecoration(
                              color: primaryPdfColor,
                              borderRadius: const pw.BorderRadius.only(
                                bottomLeft: pw.Radius.circular(25),
                              ),
                            ),
                          ),
                        ),
                        // Golden corner brackets
                        pw.Positioned(
                          top: 8,
                          left: 8,
                          child: pw.Container(
                            width: 8,
                            height: 8,
                            decoration: pw.BoxDecoration(
                              border: pw.Border(
                                top: pw.BorderSide(color: accentPdfColor, width: 1),
                                left: pw.BorderSide(color: accentPdfColor, width: 1),
                              ),
                            ),
                          ),
                        ),
                        pw.Positioned(
                          top: 8,
                          right: 8,
                          child: pw.Container(
                            width: 8,
                            height: 8,
                            decoration: pw.BoxDecoration(
                              border: pw.Border(
                                top: pw.BorderSide(color: accentPdfColor, width: 1),
                                right: pw.BorderSide(color: accentPdfColor, width: 1),
                              ),
                            ),
                          ),
                        ),
                        // Top Content Column (Header) - positioned absolutely
                        pw.Positioned(
                          top: 8,
                          left: 10,
                          right: 10,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              // School Logo
                              if (logoImage != null)
                                pw.Image(logoImage, width: 22, height: 22)
                              else
                                pw.SizedBox(width: 22, height: 22),
                              pw.SizedBox(height: 2),
                              // School Name
                              pw.Text(
                                _systemService.schoolName.toUpperCase(),
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 7,
                                  color: primaryPdfColor,
                                ),
                                textAlign: pw.TextAlign.center,
                                maxLines: 1,
                              ),
                              // Slogan
                              pw.Text(
                                "BERILMU - BERAKHLAK MULIA - BERPRESTASI",
                                style: pw.TextStyle(
                                  fontSize: 4.5,
                                  color: accentPdfColor,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.center,
                                maxLines: 1,
                              ),
                              pw.SizedBox(height: 3),
                              // Thin gold horizontal line
                              pw.Container(
                                height: 0.8,
                                color: accentPdfColor,
                              ),
                            ],
                          ),
                        ),
                        // QR Code centered - positioned absolutely
                        pw.Positioned(
                          top: 60,
                          left: 0,
                          right: 0,
                          child: pw.Center(
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(5),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: accentPdfColor, width: 1.2),
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                              ),
                              child: pw.BarcodeWidget(
                                data: id,
                                barcode: pw.Barcode.qrCode(),
                                width: 75,
                                height: 75,
                              ),
                            ),
                          ),
                        ),
                        // Navy bottom section anchored at the bottom
                        pw.Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: pw.Column(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              // Gold line separator
                              pw.Container(
                                height: 2,
                                color: accentPdfColor,
                              ),
                              pw.Container(
                                width: double.infinity,
                                decoration: pw.BoxDecoration(
                                  color: primaryPdfColor,
                                  borderRadius: const pw.BorderRadius.only(
                                    bottomLeft: pw.Radius.circular(7),
                                    bottomRight: pw.Radius.circular(7),
                                  ),
                                ),
                                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                child: pw.Column(
                                  mainAxisSize: pw.MainAxisSize.min,
                                  children: [
                                    pw.Text(
                                      _selectedType == "Siswa" ? "NAMA SISWA" : "NAMA GURU",
                                      style: pw.TextStyle(
                                        fontSize: 5.5,
                                        color: accentPdfColor,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.SizedBox(height: 1),
                                    pw.Text(
                                      name.toUpperCase(),
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 8,
                                        color: PdfColors.white,
                                      ),
                                      textAlign: pw.TextAlign.center,
                                      maxLines: 1,
                                    ),
                                    pw.SizedBox(height: 1),
                                    pw.Text(
                                      "${_selectedType == 'Siswa' ? 'NISN' : 'NIP'}: $id",
                                      style: const pw.TextStyle(
                                        fontSize: 6,
                                        color: PdfColors.white,
                                      ),
                                    ),
                                    pw.SizedBox(height: 1),
                                    pw.Text(
                                      "MADRASAH DIGITAL",
                                      style: pw.TextStyle(
                                        fontSize: 4.5,
                                        color: accentPdfColor,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context); // Close progress dialog
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: "QR_Code_Export_${_selectedType}_${_exportFormat == 'PDF' ? 'Premium' : 'Polos'}",
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mencetak PDF: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 750;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102C57),
        foregroundColor: Colors.white,
        title: const Text("Cetak QR Code"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Export Kartu QR",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102C57),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Pilih data untuk diunduh sebagai file PDF siap cetak",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildFormatToggle(),
                        const Spacer(),
                        _buildExportButton(),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Export Kartu QR",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF102C57),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Pilih data untuk diunduh sebagai file PDF siap cetak",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _buildFormatToggle(),
                    const SizedBox(width: 16),
                    _buildExportButton(),
                  ],
                ),

            const SizedBox(height: 24),

            // Color Selector Card
            _buildColorSchemeSelector(),

            const SizedBox(height: 24),

            // Selector & Search Bar Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                  )
                ],
              ),
              child: isMobile
                ? Column(
                    children: [
                      _buildTabSelector(),
                      if (_selectedType == "Siswa") ...[
                        const SizedBox(height: 12),
                        _buildClassDropdown(),
                      ],
                      const SizedBox(height: 12),
                      _buildSearchField(),
                    ],
                  )
                : Row(
                    children: [
                      _buildTabSelector(),
                      if (_selectedType == "Siswa") ...[
                        const SizedBox(width: 12),
                        _buildClassDropdown(),
                      ],
                      const Spacer(),
                      _buildSearchField(),
                    ],
                  ),
            ),

            const SizedBox(height: 20),

            // Selection Options Row
            _buildSelectionOptionsRow(),

            const SizedBox(height: 16),

            // Grid of items
            _buildGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSchemeSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pilihan Warna Desain Kartu",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF102C57),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Pilih warna desain kartu yang Anda inginkan (Tersedia 5 pilihan warna premium)",
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cardColorSchemes.map((scheme) {
              final isSelected = _selectedScheme.name == scheme.name;
              return InkWell(
                onTap: () => setState(() => _selectedScheme = scheme),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF102C57) : Colors.grey.withValues(alpha: 0.15),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 16,
                        child: Stack(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: scheme.primaryFlutterColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Positioned(
                              left: 8,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: scheme.accentFlutterColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        scheme.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isSelected ? const Color(0xFF102C57) : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _formatToggleButton("PDF", Icons.picture_as_pdf_rounded),
          _formatToggleButton("PNG", Icons.image_rounded),
        ],
      ),
    );
  }

  Widget _formatToggleButton(String format, IconData icon) {
    final isActive = _exportFormat == format;
    return InkWell(
      onTap: () => setState(() => _exportFormat = format),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
            : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.black87 : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              format,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return ElevatedButton.icon(
      onPressed: _exportSelected,
      icon: Icon(
        _exportFormat == "PDF" ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
        color: Colors.white,
        size: 18
      ),
      label: Text(
        "Export $_exportFormat (${_selectedIds.length})",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF102C57),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _tabItem("Siswa", Icons.people_outline_rounded),
        const SizedBox(width: 8),
        _tabItem("Guru", Icons.badge_outlined),
      ],
    );
  }

  Widget _tabItem(String type, IconData icon) {
    final isActive = _selectedType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedIds.clear();
          _selectedClass = "Semua Kelas";
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8EAF6) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFF102C57).withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? const Color(0xFF102C57) : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              type,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFF102C57) : Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassDropdown() {
    if (_selectedType != "Siswa") return const SizedBox.shrink();

    final classes = _classList;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClass,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedClass = newValue;
                // Clear selection to avoid mixing between classes
                _selectedIds.clear();
              });
            }
          },
          items: classes.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: MediaQuery.of(context).size.width < 750 ? double.infinity : 320,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: _selectedType == "Siswa"
                  ? "Cari siswa (nama/NISN/kelas)..."
                  : "Cari guru (nama/NIP)...",
                border: InputBorder.none,
                isDense: true,
                hintStyle: const TextStyle(fontSize: 13),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionOptionsRow() {
    return Row(
      children: [
        InkWell(
          onTap: _selectAllOnPage,
          child: const Text(
            "Pilih Semua di Halaman Ini",
            style: TextStyle(
              color: Color(0xFF102C57),
              fontWeight: FontWeight.bold,
              fontSize: 13,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: _deselectAll,
          child: Text(
            "Batalkan Semua $_selectedType",
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const Spacer(),
        Text(
          "Terpilih: ${_selectedIds.length} item",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    final items = _filteredItems;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                "Tidak ada data ${_selectedType == 'Siswa' ? 'siswa' : 'guru'} ditemukan",
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    final double width = MediaQuery.of(context).size.width;
    int crossAxisCount = 3;
    if (width < 600) {
      crossAxisCount = 1;
    } else if (width < 950) {
      crossAxisCount = 2;
    }

    final Color primaryColor = _selectedScheme.primaryFlutterColor;
    final Color accentColor = _selectedScheme.accentFlutterColor;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final String name = item.nama;
        final String id = _selectedType == "Siswa" ? item.nisn : item.nip;
        final isSelected = _selectedIds.contains(id);

        return InkWell(
          onTap: () => _toggleSelect(id),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                  ? const Color(0xFF102C57)
                  : accentColor.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: _exportFormat == "PNG"
                  ? Stack(
                      children: [
                        // Checkbox at the top right
                        Positioned(
                          top: 8,
                          right: 8,
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: isSelected,
                              activeColor: const Color(0xFF102C57),
                              checkColor: Colors.white,
                              side: BorderSide(color: Colors.grey[400]!, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) {
                                _toggleSelect(id);
                              },
                            ),
                          ),
                        ),
                        // Plain Content
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Spacer(),
                              // QR Code Image
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Image.network(
                                  "https://api.qrserver.com/v1/create-qr-code/?size=120x120&data=$id",
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const SizedBox(
                                      width: 90,
                                      height: 90,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF102C57),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code, size: 50, color: Colors.grey),
                                ),
                              ),
                              const Spacer(),
                              // Name
                              Text(
                                name.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              // ID
                              Text(
                                "${_selectedType == 'Siswa' ? 'NISN' : 'NIP'}: $id",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        // Top-left semicircle
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(32),
                              ),
                            ),
                          ),
                        ),
                        // Top-right semicircle
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(32),
                              ),
                            ),
                          ),
                        ),
                        // Corner brackets
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: accentColor, width: 1.5),
                                left: BorderSide(color: accentColor, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: accentColor, width: 1.5),
                                right: BorderSide(color: accentColor, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        // Checkbox at the top right (absolute position on top of everything)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: isSelected,
                              activeColor: primaryColor,
                              checkColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) {
                                _toggleSelect(id);
                              },
                            ),
                          ),
                        ),
                        // Main content
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 12),
                              // Logo Image
                              Image.asset(
                                'assets/logo.png',
                                width: 26,
                                height: 26,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 26, color: Colors.green),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _systemService.schoolName.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8,
                                  color: primaryColor,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "BERILMU - BERAKHLAK MULIA - BERPRESTASI",
                                style: TextStyle(
                                  fontSize: 5.5,
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 4),
                              // Gold line separator
                              Container(
                                height: 1,
                                color: accentColor,
                                margin: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              const Spacer(),
                              // QR Code Image
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: accentColor, width: 1.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Image.network(
                                  "https://api.qrserver.com/v1/create-qr-code/?size=120x120&data=$id",
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const SizedBox(
                                      width: 70,
                                      height: 70,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF102C57),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code, size: 50, color: Colors.grey),
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(height: 48), // Reserved space for bottom card overlay
                            ],
                          ),
                        ),
                        // Navy bottom section
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 2,
                                color: accentColor,
                              ),
                              Container(
                                width: double.infinity,
                                color: primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _selectedType == "Siswa" ? "NAMA SISWA" : "NAMA GURU",
                                      style: TextStyle(
                                        fontSize: 6,
                                        color: accentColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      name.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "${_selectedType == 'Siswa' ? 'NISN' : 'NIP'}: $id",
                                      style: const TextStyle(
                                        fontSize: 7.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      "MADRASAH DIGITAL",
                                      style: TextStyle(
                                        fontSize: 5.5,
                                        color: accentColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
