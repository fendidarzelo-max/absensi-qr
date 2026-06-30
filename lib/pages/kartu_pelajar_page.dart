import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final _nisController = TextEditingController();
  final _namaController = TextEditingController();
  final _ttlController = TextEditingController();
  final _alamatController = TextEditingController();
  final _namaOrtuController = TextEditingController();
  final _nsmController = TextEditingController();
  final _npsnController = TextEditingController();
  
  // Additional fields for Guru Card printing
  final _nipController = TextEditingController();
  final _jabatanController = TextEditingController();
  final _pendidikanController = TextEditingController();
  String _selectedGender = "Laki-laki";
  String _selectedAgama = "Islam";
  String _selectedType = "Siswa";
  
  final Map<String, String> _siswaNisMap = {};
  String _selectedKelas = "KLS I MI";
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();

  // Custom design settings
  bool _showDefaultHeader = false; // default false because our custom image has it
  bool _showDefaultFooter = false; // default false because our custom image has it
  bool _useDarkText = false;
  bool _useCustomMiftahulUlumTemplate = true;
  Uint8List? _customBackgroundBytes;
  
  List<String> get _kelasOptions {
    final List<String> predefined = [
      "KLS I MI", "KLS II MI", "KLS III MI", "KLS IV MI", "KLS V MI", "KLS VI MI",
      "KLS I MTS", "KLS II MTS", "KLS III MTS",
      "KLS I MA", "KLS II MA", "KLS III MA",
    ];
    
    final Set<String> uniqueKelas = {};
    for (var s in _systemService.siswaList) {
      final k = s.kelas.trim();
      if (k.isNotEmpty && !k.toUpperCase().startsWith('X') && !k.toUpperCase().contains('XI')) {
        uniqueKelas.add(k);
      }
    }
    
    uniqueKelas.addAll(predefined);
    if (_selectedKelas.isNotEmpty) {
      final k = _selectedKelas.trim().toUpperCase();
      if (!k.startsWith('X') && !k.contains('XI')) {
        uniqueKelas.add(_selectedKelas);
      }
    }
    
    final list = uniqueKelas.toList();
    list.sort((a, b) {
      final indexA = predefined.indexOf(a);
      final indexB = predefined.indexOf(b);
      if (indexA != -1 && indexB != -1) {
        return indexA.compareTo(indexB);
      } else if (indexA != -1) {
        return -1;
      } else if (indexB != -1) {
        return 1;
      }
      return a.compareTo(b);
    });
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadCardDesignSettings();
    // Default select first student if available
    if (_systemService.siswaList.isNotEmpty) {
      _selectSiswa(_systemService.siswaList.first);
    }
  }

  Future<void> _loadCardDesignSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _showDefaultHeader = prefs.getBool('card_show_header') ?? false; // default false
        _showDefaultFooter = prefs.getBool('card_show_footer') ?? false; // default false
        _useDarkText = prefs.getBool('card_use_dark_text') ?? false;
        _useCustomMiftahulUlumTemplate = prefs.getBool('card_use_miftahul_ulum') ?? true;
        _nsmController.text = prefs.getString('card_nsm') ?? "";
        _npsnController.text = prefs.getString('card_npsn') ?? "";
        
        final bgBase64 = prefs.getString('card_bg_base64');
        if (bgBase64 != null && bgBase64.isNotEmpty) {
          _customBackgroundBytes = base64Decode(bgBase64);
        }

        // Load NIS mapping
        final nisJson = prefs.getString('card_nis_map');
        if (nisJson != null) {
          final decoded = jsonDecode(nisJson) as Map<String, dynamic>;
          _siswaNisMap.clear();
          decoded.forEach((key, value) {
            _siswaNisMap[key] = value.toString();
          });
        }
        if (_nisnController.text.isNotEmpty) {
          _nisController.text = _siswaNisMap[_nisnController.text] ?? "";
        }
      });
    } catch (e) {
      debugPrint("Error loading card design: $e");
    }
  }

  Future<void> _saveCardDesignSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('card_show_header', _showDefaultHeader);
      await prefs.setBool('card_show_footer', _showDefaultFooter);
      await prefs.setBool('card_use_dark_text', _useDarkText);
      await prefs.setBool('card_use_miftahul_ulum', _useCustomMiftahulUlumTemplate);
      await prefs.setString('card_nsm', _nsmController.text);
      await prefs.setString('card_npsn', _npsnController.text);
      if (_customBackgroundBytes != null) {
        await prefs.setString('card_bg_base64', base64Encode(_customBackgroundBytes!));
      } else {
        await prefs.remove('card_bg_base64');
      }
    } catch (e) {
      debugPrint("Error saving card design: $e");
    }
  }

  Future<void> _saveNisMapping() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('card_nis_map', jsonEncode(_siswaNisMap));
    } catch (e) {
      debugPrint("Error saving NIS map: $e");
    }
  }

  @override
  void dispose() {
    _nisController.dispose();
    _nisnController.dispose();
    _namaController.dispose();
    _ttlController.dispose();
    _alamatController.dispose();
    _namaOrtuController.dispose();
    _nsmController.dispose();
    _npsnController.dispose();
    _nipController.dispose();
    _jabatanController.dispose();
    _pendidikanController.dispose();
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
      String cleanKelas = siswa.kelas.trim();
      if (cleanKelas.isEmpty || cleanKelas.toUpperCase().startsWith('X') || cleanKelas.toUpperCase().contains('XI')) {
        cleanKelas = "KLS I MI";
      }
      _selectedKelas = cleanKelas;
      _ttlController.text = siswa.ttl;
      
      // Format full address dynamically from structured fields
      String fullAlamat = siswa.alamat.trim();
      final List<String> rtrwParts = [];
      if (siswa.rt.isNotEmpty && siswa.rt != '-') {
        rtrwParts.add("RT. ${siswa.rt}");
      }
      if (siswa.rw.isNotEmpty && siswa.rw != '-') {
        rtrwParts.add("RW. ${siswa.rw}");
      }
      final String rtrwStr = rtrwParts.join(' / ');
      if (rtrwStr.isNotEmpty) {
        if (fullAlamat.isNotEmpty) {
          fullAlamat += " $rtrwStr";
        } else {
          fullAlamat = rtrwStr;
        }
      }
      if (siswa.desa.isNotEmpty && siswa.desa != '-') {
        fullAlamat += ", Ds. ${siswa.desa}";
      }
      _alamatController.text = fullAlamat;
      
      _namaOrtuController.text = siswa.namaOrtu;
      _selectedImageBytes = null; // Clear manual photo when changing student
      _nisController.text = _siswaNisMap[siswa.nisn] ?? ""; // Load NIS
    });
  }

  void _selectGuru(dynamic guru) {
    setState(() {
      _nipController.text = guru.nip;
      _namaController.text = guru.nama;
      _jabatanController.text = guru.jabatan;
      _ttlController.text = guru.tanggalLahir;
      _pendidikanController.text = guru.pendidikanTerakhir;
      _selectedGender = (guru.jenisKelamin != null && guru.jenisKelamin.isNotEmpty) ? guru.jenisKelamin : "Laki-laki";
      _selectedAgama = (guru.agama != null && guru.agama.isNotEmpty) ? guru.agama : "Islam";
      
      // Determine school level template from guru.kelas
      String level = "KLS I MI";
      final k = guru.kelas.toUpperCase();
      if (k.contains("MTS")) {
        level = "KLS I MTS";
      } else if (k.contains("MA")) {
        level = "KLS I MA";
      }
      _selectedKelas = level;
      
      _selectedImageBytes = null; // Clear manual photo when changing teacher
    });
  }


  Widget _buildInfoRow(String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(
            width: 12,
            child: Text(
              ":",
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getCardFrontAsset(String kelas) {
    if (_selectedType == "Guru") {
      return 'assets/card_front_guru.jpg';
    }
    final k = kelas.toUpperCase();
    if (k.contains('MI')) {
      return 'assets/card_front.jpg';
    } else if (k.contains('MTS')) {
      return 'assets/card_front_mts.jpg';
    } else if (k.contains('MA')) {
      return 'assets/card_front_ma.jpg';
    }
    return 'assets/card_front.jpg';
  }

  String _getCardBackAsset(String kelas) {
    if (_selectedType == "Guru") {
      return 'assets/card_back_guru.jpg';
    }
    final k = kelas.toUpperCase();
    if (k.contains('MI')) {
      return 'assets/card_back.jpg';
    } else if (k.contains('MTS')) {
      return 'assets/card_back_mts.jpg';
    } else if (k.contains('MA')) {
      return 'assets/card_back_ma.jpg';
    }
    return 'assets/card_back.jpg';
  }

  Widget _buildKartuBelajarFront() {
    final String nisVal = _nisController.text;
    final String nisnVal = _nisnController.text;
    final String namaVal = _namaController.text;
    final String ttlVal = _ttlController.text;
    final String alamatVal = _alamatController.text;
    final String kelasVal = _selectedKelas;

    // Guru values
    final String jabatanVal = _jabatanController.text;
    final String genderVal = _selectedGender;
    final String agamaVal = _selectedAgama;

    return Container(
      width: 350,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Background Image
            Image.asset(
              _getCardFrontAsset(kelasVal),
              width: 350,
              height: 220,
              fit: BoxFit.fill,
            ),

            // Student/Guru Photo Overlay (Rounded borders fitting inside template box)
            Positioned(
              left: 12,
              top: 88,
              width: 68,
              height: 90,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: _selectedImageBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_selectedImageBytes!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImageBytes == null
                    ? (_selectedType == "Siswa"
                        ? const Center(
                            child: Icon(Icons.person, color: Colors.white54, size: 30),
                          )
                        : null)
                    : null,
              ),
            ),

             // QR Code Overlay (Siswa only on front)
            if (_selectedType == "Siswa")
              Positioned(
                left: 300,
                top: 10,
                width: 38,
                height: 38,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(2),
                  child: Image.network(
                    "https://api.qrserver.com/v1/create-qr-code/?size=50x50&data=${nisnVal.isEmpty ? "0000" : nisnVal}",
                    fit: BoxFit.fill,
                    errorBuilder: (c, e, s) => const Icon(Icons.qr_code, size: 30, color: Colors.black),
                  ),
                ),
              ),

            // NSM/NPSN Overlays (Siswa only)
            if (_selectedType == "Siswa") ...[
              // NSM Overlay
              Positioned(
                left: 55,
                top: 39,
                child: Text(
                  "NSM: ${_nsmController.text}",
                  style: const TextStyle(
                    color: Color(0xFFFFE57F), // Yellow/gold text to match header theme
                    fontSize: 7.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // NPSN Overlay
              Positioned(
                left: 165,
                top: 39,
                child: Text(
                  "NPSN: ${_npsnController.text}",
                  style: const TextStyle(
                    color: Color(0xFFFFE57F), // Yellow/gold text to match header theme
                    fontSize: 7.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            // Student/Guru Name & Details Column
            Positioned(
              left: 95,
              top: 80,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaVal.isEmpty ? "-" : namaVal.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (_selectedType == "Siswa") ...[
                    _buildInfoRow("NIS", nisVal),
                    _buildInfoRow("NISN", nisnVal),
                    _buildInfoRow("Tempat/Tgl.Lahir", ttlVal),
                    _buildInfoRow("Alamat", alamatVal),
                    _buildInfoRow("Kelas", kelasVal),
                  ] else ...[
                    _buildInfoRow("Jabatan", jabatanVal),
                    _buildInfoRow("Tgl. Lahir", ttlVal),
                    _buildInfoRow("Jenis Kelamin", genderVal),
                    _buildInfoRow("Agama", agamaVal),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKartuBelajarBack() {
    final String nipVal = _nipController.text;
    return Container(
      width: 350,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Image.asset(
              _getCardBackAsset(_selectedKelas),
              width: 350,
              height: 220,
              fit: BoxFit.fill,
            ),
            if (_selectedType == "Guru")
              Positioned(
                left: 99,
                top: 85,
                width: 123,
                height: 102,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(6),
                  child: Image.network(
                    "https://api.qrserver.com/v1/create-qr-code/?size=100x100&data=${nipVal.isEmpty ? "0000" : nipVal}",
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const Icon(Icons.qr_code, size: 50, color: Colors.black),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKartuBelajar() {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      alignment: WrapAlignment.center,
      children: [
        Column(
          children: [
            const Text(
              "TAMPILAN DEPAN",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF102C57)),
            ),
            const SizedBox(height: 8),
            _buildKartuBelajarFront(),
          ],
        ),
        Column(
          children: [
            const Text(
              "TAMPILAN BELAKANG",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF102C57)),
            ),
            const SizedBox(height: 8),
            _buildKartuBelajarBack(),
          ],
        ),
      ],
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
          color: const Color(0xFF102C57).withValues(alpha: 0.08),
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

    pw.ImageProvider? bgImageProvider;
    if (_customBackgroundBytes != null) {
      bgImageProvider = pw.MemoryImage(_customBackgroundBytes!);
    }

    final String nisVal = _nisController.text;
    final String nisnVal = _nisnController.text;
    final String namaVal = _namaController.text;
    final String ttlVal = _ttlController.text;
    final String alamatVal = _alamatController.text;
    final String kelasVal = _selectedKelas;

    // Guru values
    final String nipVal = _nipController.text;
    final String jabatanVal = _jabatanController.text;
    final String genderVal = _selectedGender;
    final String agamaVal = _selectedAgama;

    final infoRow = (String label, String value, {int maxLines = 1}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4.0),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 90,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(
              width: 12,
              child: pw.Text(
                ":",
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value.isEmpty ? "-" : value,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                ),
                maxLines: maxLines,
              ),
            ),
          ],
        ),
      );
    };

    // Load templates
    pw.ImageProvider? frontAssetProvider;
    pw.ImageProvider? backAssetProvider;
    try {
      final frontBytes = await rootBundle.load(_getCardFrontAsset(kelasVal));
      final backBytes = await rootBundle.load(_getCardBackAsset(kelasVal));
      frontAssetProvider = pw.MemoryImage(frontBytes.buffer.asUint8List());
      backAssetProvider = pw.MemoryImage(backBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint("Error loading assets for PDF: $e");
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          if (frontAssetProvider != null && backAssetProvider != null) {
            // Render front and back stacked on a single A4 page
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  // Front Card
                  pw.Container(
                    width: 350,
                    height: 220,
                    decoration: pw.BoxDecoration(
                      image: pw.DecorationImage(
                        image: bgImageProvider ?? frontAssetProvider,
                        fit: pw.BoxFit.fill,
                      ),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
                    ),
                    child: pw.Stack(
                      children: [
                        // Photo
                        pw.Positioned(
                          left: 12,
                          top: 88,
                          child: pw.SizedBox(
                            width: 68,
                            height: 90,
                            child: pw.Container(
                              decoration: pw.BoxDecoration(
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                                image: imageProvider != null
                                    ? pw.DecorationImage(
                                        image: imageProvider,
                                        fit: pw.BoxFit.cover,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        // QR Code (Siswa only on front)
                        if (_selectedType == "Siswa")
                          pw.Positioned(
                            left: 300,
                            top: 10,
                            child: pw.SizedBox(
                              width: 38,
                              height: 38,
                              child: pw.Container(
                                color: PdfColors.white,
                                padding: const pw.EdgeInsets.all(2),
                                child: pw.BarcodeWidget(
                                  data: nisnVal.isEmpty ? "0000" : nisnVal,
                                  barcode: pw.Barcode.qrCode(),
                                  drawText: false,
                                ),
                              ),
                            ),
                          ),
                        // NSM/NPSN Overlays (Siswa only)
                        if (_selectedType == "Siswa") ...[
                          // NSM Overlay
                          pw.Positioned(
                            left: 55,
                            top: 39,
                            child: pw.Text(
                              "NSM: ${_nsmController.text}",
                              style: pw.TextStyle(
                                color: PdfColor.fromHex("#FFE57F"), // Light yellow/gold text
                                fontSize: 7.0,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          // NPSN Overlay
                          pw.Positioned(
                            left: 165,
                            top: 39,
                            child: pw.Text(
                              "NPSN: ${_npsnController.text}",
                              style: pw.TextStyle(
                                color: PdfColor.fromHex("#FFE57F"), // Light yellow/gold text
                                fontSize: 7.0,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        // Student/Guru Name & Details Column
                        pw.Positioned(
                          left: 95,
                          top: 80,
                          right: 12,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                namaVal.isEmpty ? "-" : namaVal.toUpperCase(),
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 12.5,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              pw.SizedBox(height: 8),
                              if (_selectedType == "Siswa") ...[
                                infoRow("NIS", nisVal),
                                infoRow("NISN", nisnVal),
                                infoRow("Tempat/Tgl.Lahir", ttlVal),
                                infoRow("Alamat", alamatVal),
                                infoRow("Kelas", kelasVal),
                              ] else ...[
                                infoRow("Jabatan", jabatanVal),
                                infoRow("Tgl. Lahir", ttlVal),
                                infoRow("Jenis Kelamin", genderVal),
                                infoRow("Agama", agamaVal),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 24),
                  // Back Card
                  pw.Container(
                    width: 350,
                    height: 220,
                    decoration: pw.BoxDecoration(
                      image: pw.DecorationImage(
                        image: backAssetProvider,
                        fit: pw.BoxFit.fill,
                      ),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
                    ),
                    child: _selectedType == "Guru"
                        ? pw.Stack(
                            children: [
                              pw.Positioned(
                                left: 99,
                                top: 85,
                                child: pw.SizedBox(
                                  width: 123,
                                  height: 102,
                                  child: pw.Container(
                                    color: PdfColors.white,
                                    padding: const pw.EdgeInsets.all(6),
                                    child: pw.BarcodeWidget(
                                      data: nipVal.isEmpty ? "0000" : nipVal,
                                      barcode: pw.Barcode.qrCode(),
                                      drawText: false,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ],
              ),
            );
          } else {
            return pw.Center(
              child: pw.Text("Gagal memuat template desain kartu."),
            );
          }
        },
      ),
    );

    final String prefix = _selectedType == "Siswa" ? 'Kartu_Pelajar' : 'Kartu_Guru';
    final fileName = _namaController.text.isEmpty ? prefix : '${prefix}_${_namaController.text}';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileName,
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
                  if (_systemService.siswaList.isNotEmpty) {
                    _selectSiswa(_systemService.siswaList.first);
                  }
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
                    "ID Card Siswa",
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
                  if (_systemService.guruList.isNotEmpty) {
                    _selectGuru(_systemService.guruList.first);
                  }
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
                    "ID Card Guru",
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

  @override
  Widget build(BuildContext context) {
    final siswaList = _systemService.siswaList;
    final guruList = _systemService.guruList;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102C57),
        foregroundColor: Colors.white,
        title: Text(_selectedType == "Siswa" ? "Cetak ID Card Siswa Massal" : "Cetak ID Card Guru Massal"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Type Selector (Siswa / Guru)
            _buildTypeSelector(),
            const SizedBox(height: 24),

            // Preview Card Section
            _buildKartuBelajar(),
            const SizedBox(height: 24),
            
            // Quick Select (Live Data)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedType == "Siswa" ? "Pilih Profil Siswa Aktif" : "Pilih Profil Guru Aktif",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedType == "Siswa"
                        ? "Muat cepat data dari basis data untuk mempratinjau kartu pelajar."
                        : "Muat cepat data dari basis data untuk mempratinjau kartu guru.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedType == "Siswa"
                        ? siswaList.map((siswa) {
                            final isSelected = _nisnController.text == siswa.nisn;
                            return ActionChip(
                              label: Text(siswa.nama, style: const TextStyle(fontSize: 12)),
                              onPressed: () => _selectSiswa(siswa),
                              backgroundColor: isSelected ? const Color(0xFF102C57) : const Color(0xFF102C57).withValues(alpha: 0.08),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF102C57),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            );
                          }).toList()
                        : guruList.map((guru) {
                            final isSelected = _nipController.text == guru.nip;
                            return ActionChip(
                              label: Text(guru.nama, style: const TextStyle(fontSize: 12)),
                              onPressed: () => _selectGuru(guru),
                              backgroundColor: isSelected ? const Color(0xFF102C57) : const Color(0xFF102C57).withValues(alpha: 0.08),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF102C57),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Form Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedType == "Siswa" ? "Detail Kredensial Siswa" : "Detail Kredensial Guru",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF102C57)),
                    ),
                    const SizedBox(height: 4),
                    const Text("Isi atau edit data untuk dicetak di kartu", style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
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
                    
                    if (_selectedType == "Siswa") ...[
                      // NIS Field
                      TextFormField(
                        controller: _nisController,
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          setState(() {
                            if (_nisnController.text.isNotEmpty) {
                              _siswaNisMap[_nisnController.text] = val;
                            }
                          });
                        },
                        decoration: InputDecoration(
                          labelText: "NIS",
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
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
                        key: ValueKey("kelas_${_selectedKelas}_${_nisnController.text}"),
                        initialValue: _selectedKelas,
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
                    ] else ...[
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
                      
                      // Template Madrasah Dropdown
                      DropdownButtonFormField<String>(
                        key: ValueKey("template_${_selectedKelas}_${_nipController.text}"),
                        initialValue: _selectedKelas.contains("MTS") ? "KLS I MTS" : (_selectedKelas.contains("MA") ? "KLS I MA" : "KLS I MI"),
                        decoration: InputDecoration(
                          labelText: "Unit Madrasah (Desain Template)",
                          prefixIcon: const Icon(Icons.school_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: "KLS I MI", child: Text("Madrasah Ibtidaiyah (MI)")),
                          DropdownMenuItem(value: "KLS I MTS", child: Text("Madrasah Tsanawiyah (MTs)")),
                          DropdownMenuItem(value: "KLS I MA", child: Text("Madrasah Aliyah (MA)")),
                        ],
                        onChanged: (val) => setState(() => _selectedKelas = val!),
                      ),
                      const SizedBox(height: 16),
                      
                      // Jabatan Field
                      TextFormField(
                        controller: _jabatanController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: "Jabatan",
                          prefixIcon: const Icon(Icons.work_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Tanggal Lahir Field
                      TextFormField(
                        controller: _ttlController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: "Tanggal Lahir",
                          prefixIcon: const Icon(Icons.cake_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Jenis Kelamin & Agama
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey("gender_${_selectedGender}_${_nipController.text}"),
                              initialValue: _selectedGender,
                              decoration: InputDecoration(
                                labelText: "Jenis Kelamin",
                                prefixIcon: const Icon(Icons.wc),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: const [
                                DropdownMenuItem(value: "Laki-laki", child: Text("Laki-laki")),
                                DropdownMenuItem(value: "Perempuan", child: Text("Perempuan")),
                              ],
                              onChanged: (val) => setState(() => _selectedGender = val!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey("agama_${_selectedAgama}_${_nipController.text}"),
                              initialValue: _selectedAgama,
                              decoration: InputDecoration(
                                labelText: "Agama",
                                prefixIcon: const Icon(Icons.church),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: const [
                                DropdownMenuItem(value: "Islam", child: Text("Islam")),
                                DropdownMenuItem(value: "Kristen", child: Text("Kristen")),
                                DropdownMenuItem(value: "Katolik", child: Text("Katolik")),
                                DropdownMenuItem(value: "Hindu", child: Text("Hindu")),
                                DropdownMenuItem(value: "Buddha", child: Text("Buddha")),
                                DropdownMenuItem(value: "Khonghucu", child: Text("Khonghucu")),
                                DropdownMenuItem(value: "Lainnya", child: Text("Lainnya")),
                              ],
                              onChanged: (val) => setState(() => _selectedAgama = val!),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    if (_selectedType == "Siswa") ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        "Informasi Madrasah (NSM & NPSN)",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102C57), fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nsmController,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                setState(() {});
                                _saveCardDesignSettings();
                              },
                              decoration: InputDecoration(
                                labelText: "NSM",
                                prefixIcon: const Icon(Icons.school_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _npsnController,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                setState(() {});
                                _saveCardDesignSettings();
                              },
                              decoration: InputDecoration(
                                labelText: "NPSN",
                                prefixIcon: const Icon(Icons.school_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                  if (_selectedType == "Siswa") {
                    if (_nisnController.text.isNotEmpty && _namaController.text.isNotEmpty) {
                      _siswaNisMap[_nisnController.text] = _nisController.text;
                      _saveNisMapping();

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
                          content: Text("Data Kartu Siswa disimpan!"),
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
                  } else {
                    if (_nipController.text.isNotEmpty && _namaController.text.isNotEmpty) {
                      final oldGuruIndex = _systemService.guruList.indexWhere((g) => g.nip == _nipController.text);
                      if (oldGuruIndex != -1) {
                        final updated = _systemService.guruList[oldGuruIndex].copyWith(
                          nama: _namaController.text,
                          jabatan: _jabatanController.text,
                          tanggalLahir: _ttlController.text,
                          jenisKelamin: _selectedGender,
                          agama: _selectedAgama,
                          pendidikanTerakhir: _systemService.guruList[oldGuruIndex].pendidikanTerakhir,
                          kelas: _selectedKelas,
                        );
                        _systemService.updateGuru(updated);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Data Kartu Guru disimpan!"),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Mohon isi NIP dan Nama terlebih dahulu"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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
