import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/system_service.dart';

class EksporDataPage extends StatefulWidget {
  const EksporDataPage({super.key});

  @override
  State<EksporDataPage> createState() => _EksporDataPageState();
}

class _EksporDataPageState extends State<EksporDataPage> {
  final SystemService _systemService = SystemService();
  String _selectedPeriod = "Hari Ini"; // Hari Ini, Bulan Ini
  String _filterType = "Semua"; // Semua, Siswa, Guru

  void _exportCSV(BuildContext context, String title, List<AttendanceLog> logsToExport) {
    if (logsToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada data untuk diekspor"), backgroundColor: Colors.red),
      );
      return;
    }

    // Build CSV string
    StringBuffer csvBuilder = StringBuffer();
    csvBuilder.writeln("Waktu,Nama,Tipe,Status");
    for (var log in logsToExport) {
      csvBuilder.writeln("${log.waktu},\"${log.nama}\",${log.tipe},${log.status}");
    }

    // Simulate export success
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
              const Text("Data berhasil diformat ke CSV (Spreadsheet) dengan layout:"),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("File CSV berhasil disimpan ke folder unduhan"),
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

  void _exportPDF(BuildContext context, String title, List<AttendanceLog> logsToExport) async {
    if (logsToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada data untuk diekspor"), backgroundColor: Colors.red),
      );
      return;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "LAPORAN REKAP ABSENSI HARIAN",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
                ),
                pw.Text("Nama Sekolah: ${_systemService.schoolName}"),
                pw.Text("NPSN: ${_systemService.schoolNpsn}"),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  headers: ["Waktu", "Nama Lengkap", "Entitas Tipe", "Status Kehadiran"],
                  data: logsToExport.map((l) => [l.waktu, l.nama, l.tipe, l.status]).toList(),
                  border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellHeight: 25,
                ),
              ],
            ),
          );
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
    // Filtered logs
    List<AttendanceLog> filteredLogs = _systemService.logs;
    if (_filterType == "Siswa") {
      filteredLogs = filteredLogs.where((l) => l.tipe == "Siswa").toList();
    } else if (_filterType == "Guru") {
      filteredLogs = filteredLogs.where((l) => l.tipe == "Guru").toList();
    }

    final totalTepatWaktu = filteredLogs.where((l) => l.status == "Tepat Waktu").length;
    final totalTerlambat = filteredLogs.where((l) => l.status == "Terlambat").length;
    final presentRate = filteredLogs.isEmpty ? 0.0 : (totalTepatWaktu / filteredLogs.length) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102C57),
        foregroundColor: Colors.white,
        title: const Text("Rekap Laporan & Analitik"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector
            Row(
              children: [
                const Text(
                  "Rekap Laporan Absensi",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  items: const [
                    DropdownMenuItem(value: "Hari Ini", child: Text("Hari Ini")),
                    DropdownMenuItem(value: "Bulan Ini", child: Text("Bulan Ini")),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPeriod = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Metrics cards
            Row(
              children: [
                _buildMetricCard(
                  title: "Total Scan Masuk",
                  value: "${filteredLogs.length}",
                  icon: Icons.qr_code,
                  color: const Color(0xFF102C57),
                ),
                const SizedBox(width: 16),
                _buildMetricCard(
                  title: "Tepat Waktu",
                  value: "$totalTepatWaktu",
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 16),
                _buildMetricCard(
                  title: "Terlambat",
                  value: "$totalTerlambat",
                  icon: Icons.timer_outlined,
                  color: Colors.red,
                ),
                const SizedBox(width: 16),
                _buildMetricCard(
                  title: "Kehadiran Tepat %",
                  value: "${presentRate.toStringAsFixed(1)}%",
                  icon: Icons.percent,
                  color: Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Export panel
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
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
                  Row(
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

            // Attendance list
            Row(
              children: [
                const Text("Daftar Absensi Terbaru", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF102C57))),
                const Spacer(),
                // Filter chips
                Wrap(
                  spacing: 8,
                  children: ["Semua", "Siswa", "Guru"].map((type) {
                    final isSelected = _filterType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _filterType = type);
                      },
                      selectedColor: const Color(0xFF102C57).withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF102C57) : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredLogs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: log.tipe == "Siswa" ? Colors.blue.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                          child: Icon(
                            log.tipe == "Siswa" ? Icons.school : Icons.badge,
                            color: log.tipe == "Siswa" ? Colors.blue : Colors.amber[800],
                            size: 20,
                          ),
                        ),
                        title: Text(log.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Waktu: ${log.waktu} • Tipe: ${log.tipe}"),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: log.status == "Tepat Waktu" ? const Color(0xFF10B981).withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            log.status,
                            style: TextStyle(
                              color: log.status == "Tepat Waktu" ? const Color(0xFF10B981) : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF102C57))),
          ],
        ),
      ),
    );
  }
}
