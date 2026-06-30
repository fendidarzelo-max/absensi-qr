import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../models/siswa.dart';
import '../models/guru.dart';

class AttendanceLog {
  final String waktu;
  final String tanggal;
  final DateTime timestamp;
  final String nama;
  final String tipe; // Siswa, Guru
  final String status; // Tepat Waktu, Terlambat, Hadir, Sakit, Izin, Alfa
  final String? kelas;
  final int? jamKe;

  const AttendanceLog({
    required this.waktu,
    required this.tanggal,
    required this.timestamp,
    required this.nama,
    required this.tipe,
    required this.status,
    this.kelas,
    this.jamKe,
  });

  Map<String, dynamic> toJson() {
    return {
      'waktu': waktu,
      'tanggal': tanggal,
      'timestamp': timestamp.toIso8601String(),
      'nama': nama,
      'tipe': tipe,
      'status': status,
      'kelas': kelas,
      'jam_ke': jamKe,
    };
  }

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      waktu: json['waktu'] as String,
      tanggal: json['tanggal'] as String? ?? "",
      timestamp: DateTime.parse(json['timestamp'] as String),
      nama: json['nama'] as String,
      tipe: json['tipe'] as String,
      status: json['status'] as String,
      kelas: json['kelas'] as String?,
      jamKe: json['jam_ke'] as int?,
    );
  }
}

class Holiday {
  final String nama;
  final DateTime tanggal;

  const Holiday({required this.nama, required this.tanggal});

  Map<String, dynamic> toJson() {
    return {'nama': nama, 'tanggal': tanggal.toIso8601String()};
  }

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      nama: json['nama'] as String,
      tanggal: DateTime.parse(json['tanggal'] as String),
    );
  }
}

class SystemService extends ChangeNotifier {
  static final SystemService _instance = SystemService._internal();
  factory SystemService() => _instance;

  SystemService._internal() {
    _initIpAndLoad();
  }

  // IP Address & API Base Configuration
  static String? _customIpAddress;
  String get ipAddress =>
      _customIpAddress ??
      (kIsWeb
          ? "localhost"
          : (defaultTargetPlatform == TargetPlatform.android
                ? "10.0.2.2"
                : "localhost"));

  String get baseUrl => "http://$ipAddress/absensi_api";

  Future<void> setCustomIp(String ip) async {
    _customIpAddress = ip.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_ip_address', _customIpAddress!);
    } catch (_) {}
    notifyListeners();
    await refresh();
  }

  Future<void> _initIpAndLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customIpAddress = prefs.getString('custom_ip_address');
      _schoolName = prefs.getString('school_name') ?? _schoolName;
      _schoolNpsn = prefs.getString('school_npsn') ?? _schoolNpsn;
      _schoolAddress = prefs.getString('school_address') ?? _schoolAddress;
      _schoolLogoPath = prefs.getString('school_logo_path') ?? _schoolLogoPath;
      _adminId = prefs.getInt('admin_id') ?? _adminId;
      _adminName = prefs.getString('admin_name') ?? _adminName;
      _adminRole = prefs.getString('admin_role') ?? _adminRole;
      _adminUsername = prefs.getString('admin_username') ?? _adminUsername;
      _adminEmail = prefs.getString('admin_email') ?? _adminEmail;
      _adminFoto = prefs.getString('admin_foto') ?? _adminFoto;
    } catch (_) {}
    await refresh();
  }

  // School Identity
  String _schoolName = "Madrasah Digital";
  String _schoolNpsn = "20219384";
  String _schoolAddress = "Pancor, Ketapang, Sampang, Jawa Timur";
  String? _schoolLogoPath;

  // Peripheral Diagnostic
  bool _isPeripheralConnected = true;

  // Admin Profile
  int _adminId = 1;
  String _adminName = "BUNG FENDY DZ";
  String _adminRole = "Administrator Utama";
  String _adminUsername = "admin";
  String _adminEmail = "admin@sekolah.sch.id";
  String _adminFoto = "";
  Uint8List? _cachedAdminFotoBytes;
  String? _lastDecodedFotoStr;

  // Master Lists
  final List<Siswa> _siswaList = [];
  final List<Guru> _guruList = [];
  final List<AttendanceLog> _logs = [];
  final List<Holiday> _holidays = [];

  // Getters
  String get schoolName => _schoolName;
  String get schoolNpsn => _schoolNpsn;
  String get schoolAddress => _schoolAddress;
  String? get schoolLogoPath => _schoolLogoPath;
  bool get isPeripheralConnected => _isPeripheralConnected;
  int get adminId => _adminId;
  String get adminName => _adminName;
  String get displayName {
    if (_adminUsername.contains('@')) {
      return _adminUsername;
    }
    if (_adminEmail.contains('@') && !_adminEmail.endsWith('@sekolah.sch.id') && !_adminEmail.startsWith('admin@')) {
      return _adminEmail;
    }
    return _adminName;
  }
  String get adminRole => _adminRole;
  String get adminUsername => _adminUsername;
  String get adminEmail => _adminEmail;
  String get adminFoto {
    if (_adminFoto.isNotEmpty) {
      return _adminFoto;
    }
    return adminGravatarUrl;
  }

  String get adminGravatarUrl {
    if (_adminEmail.isEmpty) return "";
    final email = _adminEmail.trim().toLowerCase();
    final bytes = utf8.encode(email);
    final digest = md5.convert(bytes);
    return 'https://www.gravatar.com/avatar/$digest?s=200&d=mp';
  }

  Uint8List? get adminFotoBytes {
    if (_adminFoto.isEmpty || _adminFoto.startsWith('http://') || _adminFoto.startsWith('https://')) {
      return null;
    }
    if (_lastDecodedFotoStr == _adminFoto && _cachedAdminFotoBytes != null) {
      return _cachedAdminFotoBytes;
    }
    try {
      _cachedAdminFotoBytes = base64Decode(_adminFoto);
      _lastDecodedFotoStr = _adminFoto;
      return _cachedAdminFotoBytes;
    } catch (e) {
      return null;
    }
  }

  List<Siswa> get siswaList => List.unmodifiable(_siswaList);
  List<Guru> get guruList => List.unmodifiable(_guruList);
  List<AttendanceLog> get logs => List.unmodifiable(_logs);
  List<Holiday> get holidays => List.unmodifiable(_holidays);

  // Load All Data from MySQL Database
  // Load All Data from MySQL Database in Parallel
  Future<void> refresh() async {
    try {
      // Run all HTTP requests concurrently to avoid network bottlenecks
      final results = await Future.wait([
        http
            .get(Uri.parse('$baseUrl/get_school_identity.php'))
            .timeout(const Duration(seconds: 3)),
        http
            .get(Uri.parse('$baseUrl/get_admin.php?id=$_adminId'))
            .timeout(const Duration(seconds: 3)),
        http
            .get(Uri.parse('$baseUrl/get_siswa.php'))
            .timeout(const Duration(seconds: 3)),
        http
            .get(Uri.parse('$baseUrl/get_guru.php'))
            .timeout(const Duration(seconds: 3)),
        http
            .get(Uri.parse('$baseUrl/get_logs.php'))
            .timeout(const Duration(seconds: 3)),
        http
            .get(Uri.parse('$baseUrl/get_holidays.php'))
            .timeout(const Duration(seconds: 3)),
        http
            .get(Uri.parse('$baseUrl/get_siswa_statuses.php'))
            .timeout(const Duration(seconds: 3)),
      ]);

      final schoolRes = results[0];
      final adminRes = results[1];
      final siswaRes = results[2];
      final guruRes = results[3];
      final logsRes = results[4];
      final holidaysRes = results[5];
      final statusRes = results[6];

      if (schoolRes.statusCode == 200) {
        final data = jsonDecode(schoolRes.body);
        _schoolName = data['nama'] ?? _schoolName;
        _schoolNpsn = data['npsn'] ?? _schoolNpsn;
        _schoolAddress = data['alamat'] ?? _schoolAddress;
        _schoolLogoPath = data['logo'];
      }

      if (adminRes.statusCode == 200) {
        final data = jsonDecode(adminRes.body);
        _adminName = data['nama'] ?? _adminName;
        _adminRole = data['role'] ?? _adminRole;
        _adminUsername = data['username'] ?? _adminUsername;
        _adminEmail = data['email'] ?? _adminEmail;
        _adminFoto = data['foto'] ?? _adminFoto;
      }

      if (siswaRes.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(siswaRes.body);
        _siswaList.clear();
        _siswaList.addAll(decoded.map((item) => Siswa.fromJson(item)).toList());
      }

      if (guruRes.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(guruRes.body);
        _guruList.clear();
        _guruList.addAll(decoded.map((item) => Guru.fromJson(item)).toList());
      }

      if (logsRes.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(logsRes.body);
        _logs.clear();
        _logs.addAll(
          decoded.map((item) => AttendanceLog.fromJson(item)).toList(),
        );
      }

      if (holidaysRes.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(holidaysRes.body);
        _holidays.clear();
        _holidays.addAll(
          decoded.map((item) => Holiday.fromJson(item)).toList(),
        );
      }

      if (statusRes.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(statusRes.body);
        _siswaStatuses.clear();
        decoded.forEach((key, value) {
          _siswaStatuses[key] = value.toString();
        });
      }

      notifyListeners();
    } catch (e) {
      debugPrint(
        "Gagal memuat data dari database MySQL: $e. Menggunakan cache lokal.",
      );
      await _loadFromPrefsFallback();
    }
  }

  // Fallback to local SharedPreferences
  Future<void> _loadFromPrefsFallback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _schoolName = prefs.getString('school_name') ?? _schoolName;
      _schoolNpsn = prefs.getString('school_npsn') ?? _schoolNpsn;
      _schoolAddress = prefs.getString('school_address') ?? _schoolAddress;
      _schoolLogoPath = prefs.getString('school_logo_path') ?? _schoolLogoPath;
      _adminId = prefs.getInt('admin_id') ?? _adminId;
      _adminName = prefs.getString('admin_name') ?? _adminName;
      _adminRole = prefs.getString('admin_role') ?? _adminRole;
      _adminUsername = prefs.getString('admin_username') ?? _adminUsername;
      _adminEmail = prefs.getString('admin_email') ?? _adminEmail;
      _adminFoto = prefs.getString('admin_foto') ?? _adminFoto;

      final siswaJson = prefs.getString('siswa_list');
      final guruJson = prefs.getString('guru_list');
      final logsJson = prefs.getString('logs_list');
      final holidaysJson = prefs.getString('holidays_list');
      final statusesJson = prefs.getString('siswa_statuses');

      if (siswaJson != null) {
        final List<dynamic> decoded = jsonDecode(siswaJson);
        _siswaList.clear();
        _siswaList.addAll(decoded.map((item) => Siswa.fromJson(item)).toList());
      } else {
        _siswaList.clear();
      }
      if (guruJson != null) {
        final List<dynamic> decoded = jsonDecode(guruJson);
        _guruList.clear();
        _guruList.addAll(decoded.map((item) => Guru.fromJson(item)).toList());
      } else {
        _guruList.clear();
      }
      if (logsJson != null) {
        final List<dynamic> decoded = jsonDecode(logsJson);
        _logs.clear();
        _logs.addAll(
          decoded.map((item) => AttendanceLog.fromJson(item)).toList(),
        );
      }
      if (holidaysJson != null) {
        final List<dynamic> decoded = jsonDecode(holidaysJson);
        _holidays.clear();
        _holidays.addAll(
          decoded.map((item) => Holiday.fromJson(item)).toList(),
        );
      } else {
        _holidays.clear();
        _holidays.addAll(_defaultHolidaysList());
      }
      if (statusesJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(statusesJson);
        _siswaStatuses.clear();
        decoded.forEach((key, value) {
          _siswaStatuses[key] = value.toString();
        });
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveToPrefsFallback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('school_name', _schoolName);
      await prefs.setString('school_npsn', _schoolNpsn);
      await prefs.setString('school_address', _schoolAddress);
      if (_schoolLogoPath != null) {
        await prefs.setString('school_logo_path', _schoolLogoPath!);
      }
      await prefs.setInt('admin_id', _adminId);
      await prefs.setString('admin_name', _adminName);
      await prefs.setString('admin_role', _adminRole);
      await prefs.setString('admin_username', _adminUsername);
      await prefs.setString('admin_email', _adminEmail);
      await prefs.setString('admin_foto', _adminFoto);

      final siswaJson = jsonEncode(_siswaList.map((s) => s.toJson()).toList());
      final guruJson = jsonEncode(_guruList.map((g) => g.toJson()).toList());
      final logsJson = jsonEncode(_logs.map((l) => l.toJson()).toList());
      final holidaysJson = jsonEncode(
        _holidays.map((h) => h.toJson()).toList(),
      );
      final statusesJson = jsonEncode(_siswaStatuses);

      await prefs.setString('siswa_list', siswaJson);
      await prefs.setString('guru_list', guruJson);
      await prefs.setString('logs_list', logsJson);
      await prefs.setString('holidays_list', holidaysJson);
      await prefs.setString('siswa_statuses', statusesJson);
    } catch (_) {}
  }

  Future<void> updateSchoolIdentity({
    required String name,
    required String npsn,
    required String address,
    String? logoPath,
  }) async {
    _schoolName = name;
    _schoolNpsn = npsn;
    _schoolAddress = address;
    _schoolLogoPath = logoPath;
    notifyListeners();
    _saveToPrefsFallback();

    try {
      await http.post(
        Uri.parse('$baseUrl/update_school_identity.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama': name,
          'npsn': npsn,
          'alamat': address,
          'logo': logoPath,
        }),
      );
    } catch (e) {
      debugPrint("Gagal update identitas sekolah: $e");
    }
  }

  void togglePeripheralConnection() {
    _isPeripheralConnected = !_isPeripheralConnected;
    notifyListeners();
  }

  void setPeripheralConnection(bool value) {
    _isPeripheralConnected = value;
    notifyListeners();
  }

  Future<void> updateAdminProfile({
    required String name,
    required String role,
    String? username,
    int? id,
    String? email,
    String? foto,
    bool syncToBackend = true,
  }) async {
    _adminName = name;
    _adminRole = role;
    if (username != null) {
      _adminUsername = username;
    }
    if (id != null) {
      _adminId = id;
    }
    if (email != null) {
      _adminEmail = email;
    }
    if (foto != null) {
      _adminFoto = foto;
    }
    notifyListeners();
    _saveToPrefsFallback(); // Async local cache

    if (!syncToBackend) return;

    // Fire the network call in the background without blocking the UI transition
    http
        .post(
          Uri.parse('$baseUrl/update_admin.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id': _adminId,
            'nama': name,
            'role': role,
            'username': _adminUsername,
            'email': _adminEmail,
            'foto': _adminFoto,
          }),
        )
        .then((response) {
          if (response.statusCode != 200) {
            debugPrint(
              "Sinkronisasi profil admin backend mengembalikan status: ${response.statusCode}",
            );
          }
        })
        .catchError((e) {
          debugPrint("Gagal sinkronisasi profil admin ke backend: $e");
        });
  }

  // Siswa CRUD
  Future<void> addSiswa(Siswa siswa) async {
    _siswaList.add(siswa);
    notifyListeners();
    _saveToPrefsFallback();

    try {
      await http.post(
        Uri.parse('$baseUrl/add_siswa.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(siswa.toJson()),
      );
      refresh();
    } catch (e) {
      debugPrint("Gagal tambah siswa: $e");
    }
  }

  Future<void> updateSiswa(Siswa siswa) async {
    final index = _siswaList.indexWhere((s) => s.nisn == siswa.nisn);
    if (index != -1) {
      _siswaList[index] = siswa;
      notifyListeners();
      _saveToPrefsFallback();
    }

    try {
      await http.post(
        Uri.parse('$baseUrl/update_siswa.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(siswa.toJson()),
      );
      refresh();
    } catch (e) {
      debugPrint("Gagal update siswa: $e");
    }
  }

  Future<void> deleteSiswa(String nisn) async {
    _siswaList.removeWhere((s) => s.nisn == nisn);
    notifyListeners();
    _saveToPrefsFallback();

    try {
      await http.post(
        Uri.parse('$baseUrl/delete_siswa.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nisn': nisn}),
      );
      refresh();
    } catch (e) {
      debugPrint("Gagal hapus siswa: $e");
    }
  }

  // Guru CRUD
  Future<void> addGuru(Guru guru) async {
    _guruList.add(guru);
    notifyListeners();
    _saveToPrefsFallback();

    try {
      await http.post(
        Uri.parse('$baseUrl/add_guru.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(guru.toJson()),
      );
      refresh();
    } catch (e) {
      debugPrint("Gagal tambah guru: $e");
    }
  }

  Future<void> updateGuru(Guru guru) async {
    final index = _guruList.indexWhere((g) => g.nip == guru.nip);
    if (index != -1) {
      _guruList[index] = guru;
      notifyListeners();
      _saveToPrefsFallback();
    }

    try {
      await http.post(
        Uri.parse('$baseUrl/update_guru.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(guru.toJson()),
      );
      refresh();
    } catch (e) {
      debugPrint("Gagal update guru: $e");
    }
  }

  Future<void> deleteGuru(String nip) async {
    _guruList.removeWhere((g) => g.nip == nip);
    notifyListeners();
    _saveToPrefsFallback();

    try {
      await http.post(
        Uri.parse('$baseUrl/delete_guru.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nip': nip}),
      );
      refresh();
    } catch (e) {
      debugPrint("Gagal hapus guru: $e");
    }
  }

  // Holidays CRUD
  Future<void> addHoliday(Holiday holiday) async {
    _holidays.add(holiday);
    _holidays.sort((a, b) => a.tanggal.compareTo(b.tanggal));
    notifyListeners();
    _saveToPrefsFallback();

    try {
      await http.post(
        Uri.parse('$baseUrl/add_holiday.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(holiday.toJson()),
      );
      refresh();
    } catch (e) {
      debugPrint("Gagal tambah hari libur: $e");
    }
  }

  Future<void> deleteHoliday(int index) async {
    if (index >= 0 && index < _holidays.length) {
      final holiday = _holidays[index];
      _holidays.removeAt(index);
      notifyListeners();
      _saveToPrefsFallback();

      try {
        await http.post(
          Uri.parse('$baseUrl/delete_holiday.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'tanggal': holiday.tanggal.toIso8601String()}),
        );
        refresh();
      } catch (e) {
        debugPrint("Gagal hapus hari libur: $e");
      }
    }
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
  }

  String _formatDate(DateTime dt) {
    final months = [
      "",
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember",
    ];
    return "${dt.day} ${months[dt.month]} ${dt.year}";
  }

  int getMaxHoursForKelas(String kelas) {
    final clean = kelas.toUpperCase().trim();
    if (clean.contains("MI")) {
      if (clean.contains("VI") || clean.contains("6")) {
        return 3;
      }
      if (clean.contains("I") || 
          clean.contains("V") || 
          clean.contains("1") ||
          clean.contains("2") ||
          clean.contains("3") ||
          clean.contains("4") ||
          clean.contains("5")) {
        return 2;
      }
    }
    return 3;
  }

  // Attendance scan logger
  Future<bool> recordAttendance(String code, bool isGuru, {int jamKe = 1}) async {
    if (!_isPeripheralConnected) {
      return false;
    }

    final cleanCode = code.trim();
    final now = DateTime.now();
    final timeStr = _formatTime(now);
    final dateStr = _formatDate(now);

    String status = "Hadir";

    // Optimistic local UI update
    if (isGuru) {
      final index = _guruList.indexWhere(
        (g) =>
            g.nip.trim() == cleanCode ||
            g.nama.trim().toLowerCase() == cleanCode.toLowerCase(),
      );
      if (index != -1) {
        final guru = _guruList[index];
        _logs.insert(
          0,
          AttendanceLog(
            waktu: timeStr,
            tanggal: dateStr,
            timestamp: now,
            nama: guru.nama,
            tipe: "Guru",
            status: status,
            kelas: null,
            jamKe: null,
          ),
        );
        _guruList[index] = guru.copyWith(status: "Hadir");
        notifyListeners();
      }
    } else {
      final index = _siswaList.indexWhere(
        (s) =>
            s.nisn.trim() == cleanCode ||
            s.nama.trim().toLowerCase() == cleanCode.toLowerCase(),
      );
      if (index != -1) {
        final siswa = _siswaList[index];
        _logs.insert(
          0,
          AttendanceLog(
            waktu: timeStr,
            tanggal: dateStr,
            timestamp: now,
            nama: siswa.nama,
            tipe: "Siswa",
            status: status,
            kelas: siswa.kelas,
            jamKe: jamKe,
          ),
        );
        notifyListeners();
      }
    }

    // Server Sync
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/record_attendance.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': cleanCode, 'isGuru': isGuru, 'jam_ke': jamKe}),
      );
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['status'] == 'success' || resData['status'] == 'info') {
          await refresh();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Gagal record attendance: $e");
    }

    if (isGuru) {
      return _guruList.any(
        (g) =>
            g.nip.trim() == cleanCode ||
            g.nama.trim().toLowerCase() == cleanCode.toLowerCase(),
      );
    } else {
      return _siswaList.any(
        (s) =>
            s.nisn.trim() == cleanCode ||
            s.nama.trim().toLowerCase() == cleanCode.toLowerCase(),
      );
    }
  }

  Future<void> clearLogs() async {
    _logs.clear();
    for (var i = 0; i < _guruList.length; i++) {
      _guruList[i] = _guruList[i].copyWith(status: "Tidak Hadir");
    }
    notifyListeners();
    _saveToPrefsFallback();

    try {
      await http.post(Uri.parse('$baseUrl/clear_logs.php'));
      refresh();
    } catch (e) {
      debugPrint("Gagal membersihkan log: $e");
    }
  }

  // Student status management
  final Map<String, String> _siswaStatuses = {};

  String getSiswaStatus(String nisn, {int jamKe = 1}) {
    final index = _siswaList.indexWhere((s) => s.nisn == nisn);
    if (index == -1) return "Alfa";
    final siswa = _siswaList[index];
    final todayStr = _formatDate(DateTime.now());
    final hasScanned = _logs.any(
      (l) => l.nama == siswa.nama && l.tipe == "Siswa" && l.tanggal == todayStr && l.jamKe == jamKe,
    );
    if (hasScanned) return "Hadir";
    return _siswaStatuses["$nisn-$jamKe"] ?? "Alfa";
  }

  Future<void> setSiswaStatus(String nisn, String status, {int jamKe = 1}) async {
    final index = _siswaList.indexWhere((s) => s.nisn == nisn);
    if (index == -1) return;
    final siswa = _siswaList[index];

    // Optimistic UI updates
    if (status == "Hadir") {
      final todayStr = _formatDate(DateTime.now());
      final hasScanned = _logs.any(
        (l) =>
            l.nama == siswa.nama && l.tipe == "Siswa" && l.tanggal == todayStr && l.jamKe == jamKe,
      );
      if (!hasScanned) {
        final now = DateTime.now();
        _logs.insert(
          0,
          AttendanceLog(
            waktu: _formatTime(now),
            tanggal: _formatDate(now),
            timestamp: now,
            nama: siswa.nama,
            tipe: "Siswa",
            status: "Hadir",
            kelas: siswa.kelas,
            jamKe: jamKe,
          ),
        );
      }
      _siswaStatuses["$nisn-$jamKe"] = "Hadir";
    } else {
      final todayStr = _formatDate(DateTime.now());
      _logs.removeWhere(
        (l) =>
            l.nama == siswa.nama && l.tipe == "Siswa" && l.tanggal == todayStr && l.jamKe == jamKe,
      );
      _siswaStatuses["$nisn-$jamKe"] = status;
    }
    notifyListeners();
    _saveToPrefsFallback();

    // Call API
    try {
      await http.post(
        Uri.parse('$baseUrl/set_siswa_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nisn': nisn, 'status': status, 'jam_ke': jamKe}),
      );
      refresh();
    } catch (e) {
      debugPrint("Gagal set status siswa: $e");
    }
  }

  int getSiswaHadirCount({int jamKe = 1}) {
    final todayStr = _formatDate(DateTime.now());
    return _logs
        .where(
          (l) =>
              l.tipe == "Siswa" && l.status == "Hadir" && l.tanggal == todayStr && l.jamKe == jamKe,
        )
        .map((l) => l.nama)
        .toSet()
        .length;
  }

  int getSiswaIzinCount({int jamKe = 1}) {
    int count = 0;
    for (var s in _siswaList) {
      if (getMaxHoursForKelas(s.kelas) >= jamKe) {
        if (getSiswaStatus(s.nisn, jamKe: jamKe) == "Izin") {
          count++;
        }
      }
    }
    return count;
  }

  int getSiswaSakitCount({int jamKe = 1}) {
    int count = 0;
    for (var s in _siswaList) {
      if (getMaxHoursForKelas(s.kelas) >= jamKe) {
        if (getSiswaStatus(s.nisn, jamKe: jamKe) == "Sakit") {
          count++;
        }
      }
    }
    return count;
  }

  int getSiswaAlfaCount({int jamKe = 1}) {
    int count = 0;
    for (var s in _siswaList) {
      if (getMaxHoursForKelas(s.kelas) >= jamKe) {
        if (getSiswaStatus(s.nisn, jamKe: jamKe) == "Alfa") {
          count++;
        }
      }
    }
    return count;
  }

  int getSiswaTidakHadirCount({int jamKe = 1}) {
    int totalEligible = _siswaList.where((s) => getMaxHoursForKelas(s.kelas) >= jamKe).length;
    return totalEligible - getSiswaHadirCount(jamKe: jamKe);
  }

  int getGuruHadirCount() {
    final todayStr = _formatDate(DateTime.now());
    return _logs
        .where(
          (l) =>
              l.tipe == "Guru" && l.status == "Hadir" && l.tanggal == todayStr,
        )
        .map((l) => l.nama)
        .toSet()
        .length;
  }



  List<Holiday> _defaultHolidaysList() {
    return [
      Holiday(nama: "Tahun Baru Masehi", tanggal: DateTime(2026, 1, 1)),
      Holiday(nama: "Hari Raya Nyepi", tanggal: DateTime(2026, 3, 19)),
      Holiday(nama: "Wafat Isa Al-Masih", tanggal: DateTime(2026, 4, 3)),
      Holiday(
        nama: "Hari Raya Idul Fitri 1447 H",
        tanggal: DateTime(2026, 4, 18),
      ),
      Holiday(nama: "Hari Buruh Internasional", tanggal: DateTime(2026, 5, 1)),
    ];
  }
}
