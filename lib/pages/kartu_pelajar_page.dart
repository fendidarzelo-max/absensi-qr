import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/siswa.dart';
import '../services/system_service.dart';

class KartuPelajarPage extends StatefulWidget {
  const KartuPelajarPage({super.key});

  @override
  State<KartuPelajarPage> createState() => _KartuPelajarPageState();
}

class _KartuPelajarPageState extends State<KartuPelajarPage> {
  final SystemService _systemService = SystemService();
  final _formKey = GlobalKey<FormState>();
  final _nisnController = TextEditingController();
  final _namaController = TextEditingController();
  final _ttlController = TextEditingController();
  final _alamatController = TextEditingController();
  final _namaOrtuController = TextEditingController();
  
  String _selectedKelas = "X-A";
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();
  
  final List<String> _kelasOptions = ["X-A", "X-B", "X-C", "XI-A", "XI-B", "XI-C", "XII-A", "XII-B"];

  @override
  void initState() {
    super.initState();
    // Default select first student if available
    if (_systemService.siswaList.isNotEmpty) {
      _selectSiswa(_systemService.siswaList.first);
    }
  }

  @override
  void dispose() {
    _nisnController.dispose();
    _namaController.dispose();
    _ttlController.dispose();
    _alamatController.dispose();
    _namaOrtuController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 500, maxHeight: 500);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _selectedImageBytes = bytes);
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, maxWidth: 500, maxHeight: 500);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _selectedImageBytes = bytes);
    }
  }

  void _selectSiswa(Siswa siswa) {
    setState(() {
      _nisnController.text = siswa.nisn;
      _namaController.text = siswa.nama;
      _selectedKelas = siswa.kelas;
      _ttlController.text = siswa.ttl;
      _alamatController.text = siswa.alamat;
      _namaOrtuController.text = siswa.namaOrtu;
      _selectedImageBytes = null; // Clear manual photo when changing student
    });
  }

  Widget _buildKartuBelajar() {
    return Container(
      width: 350,
      height: 220,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102C57), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "KARTU PELAJAR MADRASAH",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    _systemService.schoolName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(4),
                color: Colors.white,
                child: Image.network(
                  "https://api.qrserver.com/v1/create-qr-code/?size=40x40&data=${_nisnController.text.isEmpty ? "0000" : _nisnController.text}",
                  width: 36,
                  height: 36,
                  errorBuilder: (c, e, s) => const Icon(Icons.qr_code, size: 36, color: Colors.black),
                ),
              )
            ],
          ),
          const Spacer(),
          
          // Photo and Info Row
          Row(
            children: [
              // Student Photo
              Container(
                width: 65,
                height: 85,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white38),
                  image: _selectedImageBytes != null
                    ? DecorationImage(
                        image: MemoryImage(_selectedImageBytes!),
                        fit: BoxFit.cover,
                      )
                    : null,
                ),
                child: _selectedImageBytes == null
                  ? const Icon(Icons.person, color: Colors.white, size: 40)
                  : null,
              ),
              const SizedBox(width: 15),
              
              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _namaController.text.isEmpty ? "Nama Siswa" : _namaController.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _nisnController.text.isEmpty ? "NISN: -" : "NISN: ${_nisnController.text}",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "KELAS $_selectedKelas",
                        style: const TextStyle(
                          color: Color(0xFF102C57),
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Footer
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              "SMART MADRASAH SYSTEM",
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 8,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Pilih Foto Siswa", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(Icons.camera_alt, "Kamera", _takePhoto),
                _buildImageOption(Icons.photo_library, "Galeri", _pickImage),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF102C57).withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF102C57)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Menyiapkan PDF...")),
    );

    final pdf = pw.Document();

    pw.ImageProvider? imageProvider;
    if (_selectedImageBytes != null) {
      imageProvider = pw.MemoryImage(_selectedImageBytes!);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Container(
              width: 350,
              height: 220,
              decoration: const pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [PdfColor.fromInt(0xFF102C57), PdfColor.fromInt(0xFF1D4ED8)],
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                ),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(20)),
              ),
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "KARTU PELAJAR MADRASAH",
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            _systemService.schoolName.toUpperCase(),
                            style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        color: PdfColors.white,
                        width: 40,
                        height: 40,
                        child: pw.BarcodeWidget(
                          data: _nisnController.text.isEmpty ? "00000" : _nisnController.text,
                          barcode: pw.Barcode.qrCode(),
                          width: 30,
                          height: 30,
                          drawText: false,
                        ),
                      )
                    ],
                  ),
                  pw.Spacer(),
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 65,
                        height: 85,
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0x3DFFFFFF),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                          border: pw.Border.all(color: const PdfColor.fromInt(0x61FFFFFF)),
                        ),
                        child: imageProvider != null
                            ? pw.ClipRRect(
                                horizontalRadius: 10,
                                verticalRadius: 10,
                                child: pw.Image(imageProvider, fit: pw.BoxFit.cover),
                              )
                            : pw.Center(
                                child: pw.Text("FOTO", style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                              ),
                      ),
                      pw.SizedBox(width: 15),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              _namaController.text.isEmpty ? "Nama Siswa" : _namaController.text,
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              _nisnController.text.isEmpty ? "NISN: -" : "NISN: ${_nisnController.text}",
                              style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.amber,
                                borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
                              ),
                              child: pw.Text(
                                "KELAS $_selectedKelas",
                                style: const pw.TextStyle(
                                  color: PdfColor.fromInt(0xFF102C57),
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Align(
                    alignment: pw.Alignment.bottomRight,
                    child: pw.Text(
                      "SMART MADRASAH SYSTEM",
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 8,
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );

    final fileName = _namaController.text.isEmpty ? 'Kartu_Pelajar' : 'Kartu_Pelajar_${_namaController.text}';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final siswaList = _systemService.siswaList;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102C57),
        foregroundColor: Colors.white,
        title: const Text("Cetak Kartu Siswa Massal"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Preview Card Section
            _buildKartuBelajar(),
            const SizedBox(height: 24),
            
            // Quick Select Student (Live Data)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Pilih Profil Siswa Aktif", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102C57))),
                  const SizedBox(height: 4),
                  Text("Muat cepat data dari basis data untuk mempratinjau kartu pelajar.", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: siswaList.map((siswa) {
                      final isSelected = _nisnController.text == siswa.nisn;
                      return ActionChip(
                        label: Text(siswa.nama, style: const TextStyle(fontSize: 12)),
                        onPressed: () => _selectSiswa(siswa),
                        backgroundColor: isSelected ? const Color(0xFF102C57) : const Color(0xFF102C57).withOpacity(0.08),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF102C57), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Form Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Detail Kredensial Siswa", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF102C57))),
                    const SizedBox(height: 4),
                    Text("Isi atau edit data untuk dicetak di kartu", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 20),
                    
                    // Photo Picker
                    Center(
                      child: GestureDetector(
                        onTap: _showImagePickerDialog,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                            image: _selectedImageBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(_selectedImageBytes!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          ),
                          child: _selectedImageBytes == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: Colors.grey[400], size: 30),
                                  const SizedBox(height: 4),
                                  Text("Foto", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                ],
                              )
                            : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // NISN Field
                    TextFormField(
                      controller: _nisnController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: "NISN",
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Nama Field
                    TextFormField(
                      controller: _namaController,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: "Nama Lengkap",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Kelas Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedKelas,
                      decoration: InputDecoration(
                        labelText: "Kelas",
                        prefixIcon: const Icon(Icons.class_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _kelasOptions.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                      onChanged: (val) => setState(() => _selectedKelas = val!),
                    ),
                    const SizedBox(height: 16),
                    
                    // TTL Field
                    TextFormField(
                      controller: _ttlController,
                      decoration: InputDecoration(
                        labelText: "Tempat, Tanggal Lahir",
                        prefixIcon: const Icon(Icons.cake_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Alamat Field
                    TextFormField(
                      controller: _alamatController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Alamat",
                        prefixIcon: const Icon(Icons.home_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Nama Orang Tua Field
                    TextFormField(
                      controller: _namaOrtuController,
                      decoration: InputDecoration(
                        labelText: "Nama Orang Tua / Wali",
                        prefixIcon: const Icon(Icons.people_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            SizedBox(
              width: 350,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (_nisnController.text.isNotEmpty && _namaController.text.isNotEmpty) {
                    // Update student in local database
                    final oldSiswaIndex = _systemService.siswaList.indexWhere((s) => s.nisn == _nisnController.text);
                    if (oldSiswaIndex != -1) {
                      final updated = _systemService.siswaList[oldSiswaIndex].copyWith(
                        nama: _namaController.text,
                        kelas: _selectedKelas,
                        ttl: _ttlController.text,
                        alamat: _alamatController.text,
                        namaOrtu: _namaOrtuController.text,
                      );
                      _systemService.updateSiswa(updated);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Data Kartu disimpan!"),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Mohon isi NISN dan Nama terlebih dahulu"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF102C57),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("SIMPAN PERUBAHAN DATA KARTU", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 350,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: _exportPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("EKSPOR DAN PRATINJAU PDF", style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF102C57),
                  side: const BorderSide(color: Color(0xFF102C57)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
