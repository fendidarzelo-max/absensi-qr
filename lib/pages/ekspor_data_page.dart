import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/system_service.dart';
import '../utils/file_saver.dart';

class EksporDataPage extends StatefulWidget {
  const EksporDataPage({super.key});

  @override
  State<EksporDataPage> createState() => _EksporDataPageState();
}

class _EksporDataPageState extends State<EksporDataPage> {
  final SystemService _systemService = SystemService();
  String _selectedPeriod = "Hari Ini"; // Hari Ini, Bulan Ini, Kustom
  String _filterType = "Siswa"; // Semua, Siswa, Guru
  String _selectedKelas = "Semua Kelas";
  
  late int _selectedYear;
  late String _selectedMonth;

  final List<String> _monthsList = [
    "Januari", "Februari", "Maret", "April", "Mei", "Juni",
    "Juli", "Agustus", "September", "Oktober", "November", "Desember"
  ];

  List<int> get _years {
    final currentYear = DateTime.now().year;
    final Set<int> yearsSet = {2025, currentYear, _selectedYear};
    
    for (var log in _systemService.logs) {
      yearsSet.add(log.timestamp.year);
    }
    
    for (int y = currentYear; y <= currentYear + 20; y++) {
      yearsSet.add(y);
    }
    
    final sortedYears = yearsSet.toList()..sort();
    return sortedYears;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = _monthsList[now.month - 1];
  }

  String _formatDateIndo(DateTime date) {
    final List<String> months = [
      "", "Januari", "Februari", "Maret", "April", "Mei", "Juni",
      "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ];
    return "${date.day} ${months[date.month]} ${date.year}";
  }

  Widget _buildPeriodSelector({required bool isMobile}) {
    final dropdowns = [
      DropdownButton<String>(
        value: _selectedPeriod,
        items: const [
          DropdownMenuItem(value: "Hari Ini", child: Text("Hari Ini")),
          DropdownMenuItem(value: "Bulan Ini", child: Text("Bulan Ini")),
          DropdownMenuItem(value: "Kustom", child: Text("Kustom (Bulan & Tahun)")),
        ],
        onChanged: (val) {
          if (val != null) {
            setState(() {
              _selectedPeriod = val;
            });
          }
        },
      ),
      if (_selectedPeriod == "Kustom") ...[
        const SizedBox(width: 12),
        DropdownButton<int>(
          value: _selectedYear,
          items: _years.map((y) => DropdownMenuItem<int>(value: y, child: Text("$y"))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedYear = val;
              });
            }
          },
        ),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: _selectedMonth,
          items: _monthsList.map((m) => DropdownMenuItem<String>(value: m, child: Text(m))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedMonth = val;
              });
            }
          },
        ),
      ]
    ];

    if (isMobile) {
      return Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: dropdowns,
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: dropdowns,
      );
    }
  }

  String _getStudentStatusForDate(String nama, String dateStr, int jamKe) {
    final hasScanned = _systemService.logs.any(
      (l) => l.nama == nama && l.tipe == "Siswa" && l.tanggal == dateStr && l.jamKe == jamKe,
    );
    if (hasScanned) {
      final log = _systemService.logs.firstWhere(
        (l) => l.nama == nama && l.tipe == "Siswa" && l.tanggal == dateStr && l.jamKe == jamKe,
      );
      return log.status;
    }
    final schoolWasOpen = _systemService.logs.any((l) => l.tanggal == dateStr);
    if (schoolWasOpen) {
      return "Alfa";
    }
    return "";
  }

  Map<String, int> _getStudentStatusCounts(String name, List<AttendanceLog> logs) {
    int sakit = 0;
    int izin = 0;
    int alfa = 0;

    final studentLogs = logs.where((l) => l.nama == name && l.tipe == "Siswa").toList();
    final Map<String, String> dayStatuses = {};

    for (var log in studentLogs) {
      final current = dayStatuses[log.tanggal];
      if (current == null || log.status == "Hadir" || log.status == "Sakit" || log.status == "Izin") {
        dayStatuses[log.tanggal] = log.status;
      }
    }

    for (var status in dayStatuses.values) {
      if (status == "Sakit") {
        sakit++;
      } else if (status == "Izin") {
        izin++;
      }
    }

    final allDatesInPeriod = logs.map((l) => l.tanggal).toSet();
    for (var dateStr in allDatesInPeriod) {
      if (!dayStatuses.containsKey(dateStr)) {
        alfa++;
      }
    }

    return {"Sakit": sakit, "Izin": izin, "Alfa": alfa};
  }

  void _exportCSV(BuildContext context, String title, List<AttendanceLog> logsToExport) {
    // Build CSV string
    StringBuffer csvBuilder = StringBuffer();
    
    if (_filterType == "Siswa") {
      final students = _systemService.siswaList.where((s) {
        if (_selectedKelas != "Semua Kelas") {
          return s.kelas == _selectedKelas;
        }
        return true;
      }).toList();

      if (students.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak ada data untuk diekspor"), backgroundColor: Colors.red),
        );
        return;
      }

      // Title & School Information
      final String schoolName = _systemService.schoolName.toUpperCase();
      final String schoolYear = "2025-2026";
      final String kelasStr = _selectedKelas != "Semua Kelas" ? _selectedKelas : "Semua Kelas";
      final now = DateTime.now();
      final months = [
        "", "Januari", "Februari", "Maret", "April", "Mei", "Juni",
        "Juli", "Agustus", "September", "Oktober", "November", "Desember"
      ];
      final String bulanStr = _selectedPeriod != "Hari Ini" && _selectedPeriod != "Bulan Ini"
          ? _selectedPeriod
          : "${months[now.month]} ${now.year}";

      csvBuilder.writeln(",ABSENSI SISWA/SISWI,,,,,,,,,,,,,,,,,,,,,,,,");
      csvBuilder.writeln(",$schoolName,,,,,,,,,,,,,,,,,,,,,,,,");
      csvBuilder.writeln(",Tahun Pelajaran $schoolYear,,,,,,,,,,,,,,,,,,,,,,,,");
      csvBuilder.writeln(",Kelas : $kelasStr,,,,,,,,,,,,,,,,,,Bulan : $bulanStr");
      
      // Table Headers
      csvBuilder.writeln(",No,NISN,Nama Siswa,Senin,,,Selasa,,,Rabu,,,Kamis,,,Sabtu,,,Ahad,,,Keterangan,,");
      csvBuilder.writeln(",,,,Jam,,,Jam,,,Jam,,,Jam,,,Jam,,,Jam,,,S,I,A");
      csvBuilder.writeln(",,,,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,,,");

      // Find dates for the current week (Monday to Sunday)
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final dates = {
        "Senin": monday,
        "Selasa": monday.add(const Duration(days: 1)),
        "Rabu": monday.add(const Duration(days: 2)),
        "Kamis": monday.add(const Duration(days: 3)),
        "Sabtu": monday.add(const Duration(days: 5)),
        "Ahad": monday.add(const Duration(days: 6)),
      };

      int idx = 1;
      for (var s in students) {
        final rowItems = <String>[];
        rowItems.add("");
        rowItems.add(idx.toString());
        rowItems.add(s.nisn);
        rowItems.add(s.nama);

        // Populate days
        for (var dayName in ["Senin", "Selasa", "Rabu", "Kamis", "Sabtu", "Ahad"]) {
          final date = dates[dayName]!;
          final dateStr = _formatDateIndo(date);
          final maxHours = _systemService.getMaxHoursForKelas(s.kelas);

          for (int jam = 1; jam <= 3; jam++) {
            if (jam > maxHours) {
              rowItems.add("-");
            } else {
              final status = _getStudentStatusForDate(s.nama, dateStr, jam);
              if (status == "Hadir") {
                rowItems.add("H");
              } else if (status == "Izin") {
                rowItems.add("I");
              } else if (status == "Sakit") {
                rowItems.add("S");
              } else if (status == "Alfa") {
                rowItems.add("A");
              } else {
                rowItems.add("");
              }
            }
          }
        }

        // Totals for Keterangan (S, I, A)
        final counts = _getStudentStatusCounts(s.nama, logsToExport);
        rowItems.add(counts["Sakit"]!.toString());
        rowItems.add(counts["Izin"]!.toString());
        rowItems.add(counts["Alfa"]!.toString());

        csvBuilder.writeln(rowItems.map((val) => "\"$val\"").join(","));
        idx++;
      }
    } else {
      if (logsToExport.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak ada data untuk diekspor"), backgroundColor: Colors.red),
        );
        return;
      }

      csvBuilder.writeln("Tanggal,Waktu,Nama,Tipe,Kelas");
      for (var log in logsToExport) {
        csvBuilder.writeln("${log.tanggal},${log.waktu},\"${log.nama}\",${log.tipe},${log.kelas ?? "-"}");
      }
    }

    // Show export success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981)),
            const SizedBox(width: 10),
            Text("Ekspor $title Sukses"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Data berhasil diformat ke CSV (Excel) dengan layout rekap sekolah:"),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey[100],
                child: Text(csvBuilder.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("TUTUP"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              saveFile(
                csvBuilder.toString(),
                "Rekap_Absensi_${_selectedPeriod.replaceAll(' ', '_')}_${_filterType}_${DateTime.now().millisecondsSinceEpoch}.csv",
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("File CSV berhasil diunduh"),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF102C57), foregroundColor: Colors.white),
            child: const Text("UNDUH FILE"),
          ),
        ],
      ),
    );
  }

  Widget _buildOnScreenStatusIcon(String status) {
    if (status == "-") {
      return const Text("-", style: TextStyle(color: Colors.grey));
    }
    
    Color color;
    IconData icon;
    
    switch (status) {
      case "Hadir":
        color = const Color(0xFF1D4ED8);
        icon = Icons.check_circle;
        break;
      case "Izin":
        color = Colors.teal;
        icon = Icons.info;
        break;
      case "Sakit":
        color = Colors.amber[700]!;
        icon = Icons.sick;
        break;
      case "Alfa":
      default:
        color = Colors.redAccent;
        icon = Icons.cancel;
        break;
    }
    
    return Tooltip(
      message: status,
      child: Icon(icon, color: color, size: 20),
    );
  }

  pw.Widget _buildPdfStatusIcon(String status) {
    if (status == "-") {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text("-", style: const pw.TextStyle(color: PdfColors.grey)),
      );
    }
    if (status.isEmpty) {
      return pw.SizedBox();
    }
    
    PdfColor bgColor;
    PdfColor textColor;
    String text;
    
    switch (status) {
      case "Hadir":
        bgColor = PdfColors.blue100;
        textColor = PdfColors.blue800;
        text = "V";
        break;
      case "Izin":
        bgColor = PdfColors.teal100;
        textColor = PdfColors.teal800;
        text = "I";
        break;
      case "Sakit":
        bgColor = PdfColors.orange100;
        textColor = PdfColors.orange800;
        text = "S";
        break;
      case "Alfa":
      default:
        bgColor = PdfColors.red100;
        textColor = PdfColors.red800;
        text = "X";
        break;
    }
    
    return pw.Container(
      width: 14,
      height: 14,
      margin: const pw.EdgeInsets.symmetric(vertical: 3),
      decoration: pw.BoxDecoration(
        color: bgColor,
        shape: pw.BoxShape.circle,
      ),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: textColor,
          fontWeight: pw.FontWeight.bold,
          fontSize: 8,
        ),
      ),
    );
  }

  pw.Widget _buildPdfTableHeaderCell(String text, {double fontSize = 8}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildPdfTableCellText(String text, {double fontSize = 8}) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: fontSize),
      ),
    );
  }

  void _exportPDF(BuildContext context, String title, List<AttendanceLog> logsToExport) async {
    final bool isStudentFilter = _filterType == "Siswa";
    final String reportTitle;
    if (_filterType == "Siswa") {
      reportTitle = "ABSENSI SISWA/SISWI";
    } else if (_filterType == "Guru") {
      reportTitle = "KEHADIRAN GURU";
    } else {
      reportTitle = "LOG KEHADIRAN";
    }

    final students = _systemService.siswaList.where((s) {
      if (_selectedKelas != "Semua Kelas") {
        return s.kelas == _selectedKelas;
      }
      return true;
    }).toList();

    if (isStudentFilter ? students.isEmpty : logsToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada data untuk diekspor"), backgroundColor: Colors.red),
      );
      return;
    }

    final now = DateTime.now();
    final months = [
      "", "Januari", "Februari", "Maret", "April", "Mei", "Juni",
      "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ];
    final tanggalCetak = "${now.day} ${months[now.month]} ${now.year}";

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/logo_login.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      // Gracefully continue without logo if failed to load
    }

    final pdf = pw.Document();
    final pageFormat = isStudentFilter ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(24),
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              "Dicetak pada: $tanggalCetak | Halaman ${context.pageNumber} dari ${context.pagesCount}",
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Kop Surat
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 50,
                    height: 50,
                    margin: const pw.EdgeInsets.only(right: 16),
                    child: pw.Image(logoImage),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        _systemService.schoolName.toUpperCase(),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "NPSN: ${_systemService.schoolNpsn} | ${_systemService.schoolAddress}",
                        style: const pw.TextStyle(
                          fontSize: 8,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (logoImage != null)
                  pw.SizedBox(width: 50),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Container(height: 1.5, color: PdfColors.black),
            pw.SizedBox(height: 1),
            pw.Container(height: 0.5, color: PdfColors.black),
            pw.SizedBox(height: 12),

            // Judul Laporan
            pw.Center(
              child: pw.Text(
                reportTitle,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            pw.Center(
              child: pw.Text(
                "Tahun Pelajaran 2025-2026",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            
            // Kelas & Bulan Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Kelas : ${_selectedKelas != "Semua Kelas" ? _selectedKelas : "Semua Kelas"}",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                ),
                pw.Text(
                  "Bulan : ${_selectedPeriod != "Hari Ini" && _selectedPeriod != "Bulan Ini" ? _selectedPeriod : "${months[now.month]} ${now.year}"}",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // Tabel Data
            isStudentFilter
                ? pw.Table(
                    border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(20),  // No
                      1: pw.FixedColumnWidth(55),  // NISN
                      2: pw.FixedColumnWidth(150), // Nama Siswa
                      // 18 columns for days
                      3: pw.FixedColumnWidth(23), 4: pw.FixedColumnWidth(23), 5: pw.FixedColumnWidth(23),
                      6: pw.FixedColumnWidth(23), 7: pw.FixedColumnWidth(23), 8: pw.FixedColumnWidth(23),
                      9: pw.FixedColumnWidth(23), 10: pw.FixedColumnWidth(23), 11: pw.FixedColumnWidth(23),
                      12: pw.FixedColumnWidth(23), 13: pw.FixedColumnWidth(23), 14: pw.FixedColumnWidth(23),
                      15: pw.FixedColumnWidth(23), 16: pw.FixedColumnWidth(23), 17: pw.FixedColumnWidth(23),
                      18: pw.FixedColumnWidth(23), 19: pw.FixedColumnWidth(23), 20: pw.FixedColumnWidth(23),
                      // 3 columns for Keterangan (S, I, A)
                      21: pw.FixedColumnWidth(23), 22: pw.FixedColumnWidth(23), 23: pw.FixedColumnWidth(23),
                    },
                    children: [
                      // Header Row 1
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          _buildPdfTableHeaderCell("No", fontSize: 8),
                          _buildPdfTableHeaderCell("NISN", fontSize: 8),
                          _buildPdfTableHeaderCell("Nama Siswa", fontSize: 8),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell("Senin", fontSize: 8),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell("Selasa", fontSize: 8),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell("Rabu", fontSize: 8),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell("Kamis", fontSize: 8),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell("Sabtu", fontSize: 8),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell("Ahad", fontSize: 8),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell("Keterangan", fontSize: 8),
                          _buildPdfTableHeaderCell(""),
                        ],
                      ),
                      // Header Row 2
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell("Jam", fontSize: 7),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell("Jam", fontSize: 7),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell("Jam", fontSize: 7),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell("Jam", fontSize: 7),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell("Jam", fontSize: 7),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell("Jam", fontSize: 7),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell("S", fontSize: 7),
                          _buildPdfTableHeaderCell("I", fontSize: 7),
                          _buildPdfTableHeaderCell("A", fontSize: 7),
                        ],
                      ),
                      // Header Row 3
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell("1", fontSize: 7),
                          _buildPdfTableHeaderCell("2", fontSize: 7),
                          _buildPdfTableHeaderCell("3", fontSize: 7),
                          _buildPdfTableHeaderCell("1", fontSize: 7),
                          _buildPdfTableHeaderCell("2", fontSize: 7),
                          _buildPdfTableHeaderCell("3", fontSize: 7),
                          _buildPdfTableHeaderCell("1", fontSize: 7),
                          _buildPdfTableHeaderCell("2", fontSize: 7),
                          _buildPdfTableHeaderCell("3", fontSize: 7),
                          _buildPdfTableHeaderCell("1", fontSize: 7),
                          _buildPdfTableHeaderCell("2", fontSize: 7),
                          _buildPdfTableHeaderCell("3", fontSize: 7),
                          _buildPdfTableHeaderCell("1", fontSize: 7),
                          _buildPdfTableHeaderCell("2", fontSize: 7),
                          _buildPdfTableHeaderCell("3", fontSize: 7),
                          _buildPdfTableHeaderCell("1", fontSize: 7),
                          _buildPdfTableHeaderCell("2", fontSize: 7),
                          _buildPdfTableHeaderCell("3", fontSize: 7),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell(""),
                          _buildPdfTableHeaderCell(""),
                        ],
                      ),
                      // Data Rows
                      ...() {
                        int idx = 1;
                        final monday = now.subtract(Duration(days: now.weekday - 1));
                        final dates = {
                          "Senin": monday,
                          "Selasa": monday.add(const Duration(days: 1)),
                          "Rabu": monday.add(const Duration(days: 2)),
                          "Kamis": monday.add(const Duration(days: 3)),
                          "Sabtu": monday.add(const Duration(days: 5)),
                          "Ahad": monday.add(const Duration(days: 6)),
                        };

                        return students.map((s) {
                          final rowIdx = idx++;
                          
                          // Get student status counts for totals
                          final counts = _getStudentStatusCounts(s.nama, logsToExport);

                          return pw.TableRow(
                            children: [
                              _buildPdfTableCellText(rowIdx.toString()),
                              _buildPdfTableCellText(s.nisn),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                child: pw.Text(s.nama, style: const pw.TextStyle(fontSize: 8)),
                              ),
                              // Days mapping
                              ...() {
                                final widgets = <pw.Widget>[];
                                for (var dayName in ["Senin", "Selasa", "Rabu", "Kamis", "Sabtu", "Ahad"]) {
                                  final date = dates[dayName]!;
                                  final dateStr = _formatDateIndo(date);
                                  final maxHours = _systemService.getMaxHoursForKelas(s.kelas);

                                  for (int jam = 1; jam <= 3; jam++) {
                                    if (jam > maxHours) {
                                      widgets.add(
                                        pw.Container(
                                          alignment: pw.Alignment.center,
                                          child: pw.Text("-", style: const pw.TextStyle(color: PdfColors.grey, fontSize: 8)),
                                        ),
                                      );
                                    } else {
                                      final status = _getStudentStatusForDate(s.nama, dateStr, jam);
                                      widgets.add(
                                        pw.Container(
                                          alignment: pw.Alignment.center,
                                          child: _buildPdfStatusIcon(status),
                                        ),
                                      );
                                    }
                                  }
                                }
                                return widgets;
                              }(),
                              // Totals (S, I, A)
                              _buildPdfTableCellText(counts["Sakit"]!.toString()),
                              _buildPdfTableCellText(counts["Izin"]!.toString()),
                              _buildPdfTableCellText(counts["Alfa"]!.toString()),
                            ],
                          );
                        }).toList();
                      }(),
                    ],
                  )
                : pw.TableHelper.fromTextArray(
                    headers: ["Tanggal", "Waktu", "Nama Lengkap", "Tipe", "Kelas"],
                    data: logsToExport.map((l) => [l.tanggal, l.waktu, l.nama, l.tipe, l.kelas ?? "-"]).toList(),
                    border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    cellHeight: 25,
                  ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: "Rekap_Absensi_${DateTime.now().millisecondsSinceEpoch}",
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Filtered logs
    List<AttendanceLog> filteredLogs = _systemService.logs;

    // Filter by period
    if (_selectedPeriod == "Hari Ini") {
      filteredLogs = filteredLogs.where((l) => 
        l.timestamp.year == now.year && 
        l.timestamp.month == now.month && 
        l.timestamp.day == now.day
      ).toList();
    } else if (_selectedPeriod == "Bulan Ini") {
      filteredLogs = filteredLogs.where((l) => 
        l.timestamp.year == now.year && 
        l.timestamp.month == now.month
      ).toList();
    } else {
      final parts = _selectedPeriod.split(" ");
      if (parts.length == 2) {
        final monthStr = parts[0];
        final yearStr = parts[1];
        final yearVal = int.tryParse(yearStr);
        
        final monthsList = [
          "", "Januari", "Februari", "Maret", "April", "Mei", "Juni",
          "Juli", "Agustus", "September", "Oktober", "November", "Desember"
        ];
        
        final monthIdx = monthsList.indexOf(monthStr);
        if (monthIdx != -1 && yearVal != null) {
          filteredLogs = filteredLogs.where((l) => 
            l.timestamp.year == yearVal && 
            l.timestamp.month == monthIdx
          ).toList();
        }
      }
    }

    if (_filterType == "Siswa") {
      filteredLogs = filteredLogs.where((l) => l.tipe == "Siswa").toList();
      if (_selectedKelas != "Semua Kelas") {
        filteredLogs = filteredLogs.where((l) => l.kelas == _selectedKelas).toList();
      }
    } else if (_filterType == "Guru") {
      filteredLogs = filteredLogs.where((l) => l.tipe == "Guru").toList();
    }

    final bool isMobile = MediaQuery.of(context).size.width < 750;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102C57),
        foregroundColor: Colors.white,
        title: const Text("Rekap Laporan & Analitik"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Rekap Laporan Absensi",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                      ),
                      const SizedBox(height: 8),
                      _buildPeriodSelector(isMobile: true),
                    ],
                  )
                : Row(
                    children: [
                      const Text(
                        "Rekap Laporan Absensi",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                      ),
                      const Spacer(),
                      _buildPeriodSelector(isMobile: false),
                    ],
                  ),
            const SizedBox(height: 20),

            // Metrics cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: "Total Scan Masuk",
                    value: "${filteredLogs.length}",
                    icon: Icons.qr_code,
                    color: const Color(0xFF102C57),
                  ),
                ),
                if (!isMobile) ...[
                  const Spacer(),
                  const Spacer(),
                  const Spacer(),
                ],
              ],
            ),
            const SizedBox(height: 32),

            // Export panel
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pusat Ekspor Spreadsheet & PDF",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF102C57)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Pilih format ekspor berkas data kehadiran untuk audit dan arsip laporan.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  isMobile
                      ? Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _exportCSV(context, "Absensi", filteredLogs),
                                icon: const Icon(Icons.table_chart, color: Color(0xFF102C57)),
                                label: const Text("Ekspor CSV (Excel)", style: TextStyle(fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF102C57)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _exportPDF(context, "Absensi", filteredLogs),
                                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                                label: const Text("Ekspor PDF Resmi", style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF102C57),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _exportCSV(context, "Absensi", filteredLogs),
                                icon: const Icon(Icons.table_chart, color: Color(0xFF102C57)),
                                label: const Text("Ekspor CSV (Excel)", style: TextStyle(fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF102C57)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _exportPDF(context, "Absensi", filteredLogs),
                                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                                label: const Text("Ekspor PDF Resmi", style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF102C57),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Daftar Absensi Terbaru",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF102C57)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ["Semua", "Siswa", "Guru"].map((type) {
                          final isSelected = _filterType == type;
                          return ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _filterType = type;
                                  if (type != "Siswa") {
                                    _selectedKelas = "Semua Kelas";
                                  }
                                });
                              }
                            },
                            selectedColor: const Color(0xFF102C57).withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF102C57) : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Text(
                        "Daftar Absensi Terbaru",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF102C57)),
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 8,
                        children: ["Semua", "Siswa", "Guru"].map((type) {
                          final isSelected = _filterType == type;
                          return ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _filterType = type;
                                  if (type != "Siswa") {
                                    _selectedKelas = "Semua Kelas";
                                  }
                                });
                              }
                            },
                            selectedColor: const Color(0xFF102C57).withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF102C57) : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
            if (_filterType == "Siswa") ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Filter Kelas:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF102C57))),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedKelas,
                    items: ["Semua Kelas", ..._systemService.siswaList.map((s) => s.kelas).toSet()].map((kelas) {
                      return DropdownMenuItem<String>(
                        value: kelas,
                        child: Text(kelas),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedKelas = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: filteredLogs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox, color: Colors.grey, size: 40),
                          SizedBox(height: 12),
                          Text("Belum ada data absensi untuk filter ini", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                : (_selectedPeriod == "Hari Ini" && _filterType == "Siswa")
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(const Color(0xFF102C57).withValues(alpha: 0.05)),
                            columns: const [
                              DataColumn(label: Text("Nama Lengkap", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102C57)))),
                              DataColumn(label: Text("Kelas", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102C57)))),
                              DataColumn(label: Center(child: Text("1", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102C57))))),
                              DataColumn(label: Center(child: Text("2", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102C57))))),
                              DataColumn(label: Center(child: Text("3", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102C57))))),
                            ],
                            rows: (() {
                              final students = _systemService.siswaList.where((s) {
                                if (_selectedKelas != "Semua Kelas") {
                                  return s.kelas == _selectedKelas;
                                }
                                return true;
                              }).toList();
                              
                              return students.map((s) {
                                final status1 = _systemService.getSiswaStatus(s.nisn, jamKe: 1);
                                final maxHours = _systemService.getMaxHoursForKelas(s.kelas);
                                final status2 = maxHours >= 2 ? _systemService.getSiswaStatus(s.nisn, jamKe: 2) : "-";
                                final status3 = maxHours >= 3 ? _systemService.getSiswaStatus(s.nisn, jamKe: 3) : "-";
                                
                                return DataRow(
                                  cells: [
                                    DataCell(Text(s.nama, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(Text(s.kelas)),
                                    DataCell(Center(child: _buildOnScreenStatusIcon(status1))),
                                    DataCell(Center(child: _buildOnScreenStatusIcon(status2))),
                                    DataCell(Center(child: _buildOnScreenStatusIcon(status3))),
                                  ],
                                );
                              }).toList();
                            })(),
                          ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredLogs.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: log.tipe == "Siswa" ? Colors.blue.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
                              child: Icon(
                                log.tipe == "Siswa" ? Icons.school : Icons.badge,
                                color: log.tipe == "Siswa" ? Colors.blue : Colors.amber[800],
                                size: 20,
                              ),
                            ),
                            title: Text(log.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Tanggal: ${log.tanggal} • Waktu: ${log.waktu} • Tipe: ${log.tipe}"),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF102C57))),
        ],
      ),
    );
  }
}
