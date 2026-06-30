import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/system_service.dart';
import 'absensi_qr_page.dart';
import 'cetak_qr_page.dart';
import 'data_siswa_page.dart';
import 'data_guru_page.dart';
import 'ekspor_data_page.dart';
import 'identitas_sekolah_page.dart';
import 'kartu_pelajar_page.dart';
import 'hari_libur_page.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final SystemService _systemService = SystemService();
  int _currentMenuIndex = 0;
  late Timer _clockTimer;
  String _timeString = "";
  String _dateString = "";
  int totalSiswaHadir = 0;
  int totalGuruHadir = 0;
  final int _currentJam = 1;

  Future<void> ambilDataDashboard() async {
    final url = Uri.parse('http://localhost/absensi_api/get_dashboard.php');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          totalSiswaHadir = data['siswa_hadir'];
          totalGuruHadir = data['guru_hadir'];
        });
      }
    } catch (e) {
      debugPrint("Error ambil data: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _systemService.addListener(_onSystemStateChanged);
    _updateClock();
    ambilDataDashboard();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateClock();
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _systemService.removeListener(_onSystemStateChanged);
    super.dispose();
  }

  void _onSystemStateChanged() {
    if (mounted) setState(() {});
  }

  void _updateClock() {
    final now = DateTime.now();

    // Format Time: 14:39:47
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final timeStr = "$hh:$mm:$ss";

    // Format Date: Senin, 11 Mei 2026
    final days = [
      "",
      "Senin",
      "Selasa",
      "Rabu",
      "Kamis",
      "Jumat",
      "Sabtu",
      "Minggu",
    ];
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

    final dayName = days[now.weekday];
    final monthName = months[now.month];
    final dateStr = "$dayName, ${now.day} $monthName ${now.year}";

    if (mounted) {
      setState(() {
        _timeString = timeStr;
        _dateString = dateStr;
      });
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Keluar"),
        content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("BATAL"),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              if (mounted) {
                navigator.pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text("KELUAR"),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBody() {
    switch (_currentMenuIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const AbsensiQRPage(isGuru: false);
      case 2:
        return const AbsensiQRPage(isGuru: true);
      case 3:
        return const CetakQRPage();
      case 4:
        return const DataSiswaPage();
      case 5:
        return const DataGuruPage();
      case 6:
        return const EksporDataPage();
      case 7:
        return const KartuPelajarPage();
      case 8:
        return const HariLiburPage();
      case 9:
        return const IdentitasSekolahPage();
      default:
        return _buildDashboardContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF102C57),
          child: _buildSidebarContent(isDrawer: true),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 950;

          return Row(
            children: [
              if (isDesktop)
                Container(
                  width: 280,
                  color: const Color(0xFF102C57),
                  child: _buildSidebarContent(isDrawer: false),
                ),
              Expanded(
                child: Column(
                  children: [
                    // Mobile Top Bar
                    if (!isDesktop)
                      AppBar(
                        backgroundColor: const Color(0xFF102C57),
                        foregroundColor: Colors.white,
                        title: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.asset(
                                'assets/logo_login.png',
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _systemService.schoolName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        elevation: 0,
                      ),
                    Expanded(child: _buildActiveBody()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebarContent({required bool isDrawer}) {
    final menuItems = [
      {"icon": Icons.dashboard, "label": "Dashboard"},
      {"icon": Icons.qr_code_scanner, "label": "Absensi Scan murid"},
      {"icon": Icons.badge, "label": "Absensi Scan guru"},
      {"icon": Icons.qr_code, "label": "Cetak QR"},
      {"icon": Icons.people, "label": "Data Siswa"},
      {"icon": Icons.person, "label": "Data Guru"},
      {"icon": Icons.analytics, "label": "Rekap Laporan"},
      {"icon": Icons.credit_card, "label": "Cetak ID Card"},
      {"icon": Icons.calendar_month, "label": "Hari Libur"},
      {"icon": Icons.settings, "label": "Identitas Sekolah"},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Name Header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/logo_login.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.school,
                          color: Color(0xFF102C57),
                          size: 18,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _systemService.schoolName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Admin Profile Card in Sidebar (Static)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  backgroundImage: _systemService.adminFoto.isNotEmpty
                      ? ((_systemService.adminFoto.startsWith('http://') ||
                                _systemService.adminFoto.startsWith(
                                  'https://',
                                ))
                            ? NetworkImage(_systemService.adminFoto)
                            : (_systemService.adminFotoBytes != null
                                  ? MemoryImage(
                                      _systemService.adminFotoBytes!,
                                    )
                                  : null))
                      : null,
                  child: _systemService.adminFoto.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 18,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _systemService.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _systemService.adminRole,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Navigation Menu List
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = _currentMenuIndex == index;
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1D4ED8)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    visualDensity: VisualDensity.compact,
                    leading: Icon(
                      item["icon"] as IconData,
                      color: isSelected ? Colors.white : Colors.white70,
                      size: 20,
                    ),
                    title: Text(
                      item["label"] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      if (isDrawer) {
                        Navigator.pop(context);
                      }
                      setState(() {
                        _currentMenuIndex = index;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const Divider(color: Colors.white24),

          // Logout Item
          ListTile(
            visualDensity: VisualDensity.compact,
            leading: const Icon(
              Icons.logout,
              color: Colors.redAccent,
              size: 20,
            ),
            title: const Text(
              "Keluar (Logout)",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            onTap: () {
              if (isDrawer) {
                Navigator.pop(context);
              }
              _showLogoutConfirmation(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminAvatar({double radius = 24}) {
    bool isUrl =
        _systemService.adminFoto.startsWith('http://') ||
        _systemService.adminFoto.startsWith('https://');
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF102C57), width: 1.5),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF102C57),
        backgroundImage: _systemService.adminFoto.isNotEmpty
            ? (isUrl
                  ? NetworkImage(_systemService.adminFoto)
                  : (_systemService.adminFotoBytes != null
                        ? MemoryImage(_systemService.adminFotoBytes!)
                        : null))
            : null,
        child: _systemService.adminFoto.isEmpty
            ? Icon(Icons.person, color: Colors.white, size: radius)
            : null,
      ),
    );
  }

  Widget _buildDashboardContent() {
    final now = DateTime.now();
    final recentLogs = _systemService.logs.where((l) {
      return l.timestamp.year == now.year &&
             l.timestamp.month == now.month &&
             l.timestamp.day == now.day;
    }).take(10).toList();
    final bool isMobile = MediaQuery.of(context).size.width < 750;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Header Welcome and Date/Time Widget
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildAdminAvatar(radius: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Selamat Datang, ${_systemService.displayName}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF102C57),
                                ),
                              ),
                              Text(
                                _systemService.adminRole,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _dateString,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF102C57),
                            ),
                          ),
                          Text(
                            _timeString,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _buildAdminAvatar(radius: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Selamat Datang, ${_systemService.displayName}",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF102C57),
                                  ),
                                ),
                                Text(
                                  _systemService.adminRole,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _dateString,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF102C57),
                            ),
                          ),
                          Text(
                            _timeString,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 24),

          // Row 2: KPI Cards
          isMobile
              ? Column(
                  children: [
                    _buildKPICard(
                      title: "Siswa Hadir",
                      value: "${_systemService.getSiswaHadirCount(jamKe: 1)}",
                      subtitle: "Klik untuk kelola Alfa, Sakit, Izin",
                      icon: Icons.people,
                      color: const Color(0xFF1D4ED8),
                      onTap: _showStudentAttendanceDetails,
                    ),
                    const SizedBox(height: 16),
                    _buildKPICard(
                      title: "Guru Hadir",
                      value: "${_systemService.getGuruHadirCount()}",
                      subtitle: "Guru ter-scan masuk hari ini",
                      icon: Icons.badge,
                      color: const Color(0xFF10B981),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildKPICard(
                        title: "Siswa Hadir",
                        value: "${_systemService.getSiswaHadirCount(jamKe: 1)}",
                        subtitle: "Klik untuk kelola Alfa, Sakit, Izin",
                        icon: Icons.people,
                        color: const Color(0xFF1D4ED8),
                        onTap: _showStudentAttendanceDetails,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildKPICard(
                        title: "Guru Hadir",
                        value: "${_systemService.getGuruHadirCount()}",
                        subtitle: "Guru ter-scan masuk hari ini",
                        icon: Icons.badge,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 32),

          // Row 3: Bottom grid with Logs Table and Diagnostics Info
          isMobile
              ? Column(
                  children: [
                    _buildLogTable(recentLogs, isMobile),
                    const SizedBox(height: 24),
                    _buildDiagnosticInfo(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildLogTable(recentLogs, isMobile),
                    ),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: _buildDiagnosticInfo()),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildLogTable(List<dynamic> recentLogs, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Log Absensi Terbaru",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF102C57),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentMenuIndex = 6; // Go to Rekap Laporan
                  });
                },
                child: const Text(
                  "Lihat Semua",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          recentLogs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          color: Colors.grey[400],
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Belum ada data absensi hari ini",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : isMobile
              ? ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentLogs.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final log = recentLogs[index];
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              (log.tipe == "Siswa"
                                      ? Colors.blue
                                      : Colors.amber[800])!
                                  .withValues(alpha: 0.1),
                          child: Icon(
                            log.tipe == "Siswa" ? Icons.school : Icons.badge,
                            color: log.tipe == "Siswa"
                                ? Colors.blue
                                : Colors.amber[800],
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.nama,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF102C57),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${log.tipe} • ${log.waktu}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (log.status == "Hadir"
                                        ? const Color(0xFF10B981)
                                        : Colors.red)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            log.status,
                            style: TextStyle(
                              fontSize: 11,
                              color: log.status == "Hadir"
                                  ? const Color(0xFF10B981)
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
              : Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(2.5),
                    2: FlexColumnWidth(1.2),
                    3: FlexColumnWidth(1.5),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "WAKTU",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "NAMA",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "TIPE",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "STATUS",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...recentLogs.map(
                      (log) => TableRow(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.1),
                              width: 0.5,
                            ),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              log.waktu,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              log.nama,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF102C57),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              log.tipe,
                              style: TextStyle(
                                fontSize: 12,
                                color: log.tipe == "Siswa"
                                    ? Colors.blue
                                    : Colors.amber[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              log.status,
                              style: TextStyle(
                                fontSize: 12,
                                color: log.status == "Hadir"
                                    ? const Color(0xFF10B981)
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Informasi Sistem & Diagnostik",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF102C57),
            ),
          ),
          const SizedBox(height: 16),

          // Device guidance instructions
          const Text(
            "Instruksi Operasional Perangkat:",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Pastikan scanner QR Code terhubung dengan benar ke port USB untuk proses absensi yang lancar.",
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 20),

          // Database engine label
          _buildDiagnosticRow("Database Engine", "MySQL (Server)"),
          const Divider(height: 24),

          // Peripheral status label with glow circle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Status Periferal USB",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _systemService.isPeripheralConnected
                          ? const Color(0xFF10B981)
                          : Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _systemService.isPeripheralConnected
                              ? const Color(0xFF10B981)
                              : Colors.red,
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _systemService.isPeripheralConnected
                        ? "Terhubung"
                        : "Terputus",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _systemService.isPeripheralConnected
                          ? const Color(0xFF10B981)
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mini button to toggle hardware scanner status directly
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () {
                _systemService.togglePeripheralConnection();
              },
              icon: Icon(
                _systemService.isPeripheralConnected
                    ? Icons.usb_off
                    : Icons.usb,
                size: 14,
                color: _systemService.isPeripheralConnected
                    ? Colors.red
                    : const Color(0xFF10B981),
              ),
              label: Text(
                _systemService.isPeripheralConnected
                    ? "Simulasikan Putus"
                    : "Simulasikan Sambung",
                style: TextStyle(
                  fontSize: 11,
                  color: _systemService.isPeripheralConnected
                      ? Colors.red
                      : const Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _systemService.isPeripheralConnected
                      ? Colors.red
                      : const Color(0xFF10B981),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentAttendanceDetails() {
    String selectedFilter = "Alfa";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            int selectedJam = _currentJam;
            final filteredStudents = _systemService.siswaList.where((siswa) {
              if (_systemService.getMaxHoursForKelas(siswa.kelas) < selectedJam) {
                return false;
              }
              return _systemService.getSiswaStatus(siswa.nisn, jamKe: selectedJam) ==
                  selectedFilter;
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  const Icon(Icons.people, color: Color(0xFF102C57), size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Detail & Status Kehadiran",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF102C57),
                          ),
                        ),
                        Text(
                          "Atur status alfa, sakit, izin, atau hadir",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Jam selector inside Modal
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF102C57).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [1, 2, 3].map((jam) {
                          final isSelected = selectedJam == jam;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedJam = jam;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF102C57) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    "Jam Ke-$jam",
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : const Color(0xFF102C57),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF102C57).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildModalStatButton(
                            label: "Hadir",
                            value: _systemService.getSiswaHadirCount(jamKe: selectedJam),
                            color: const Color(0xFF1D4ED8),
                            isSelected: selectedFilter == "Hadir",
                            onTap: () {
                              setModalState(() {
                                selectedFilter = "Hadir";
                              });
                            },
                          ),
                          _buildModalStatButton(
                            label: "Sakit",
                            value: _systemService.getSiswaSakitCount(jamKe: selectedJam),
                            color: Colors.amber[700]!,
                            isSelected: selectedFilter == "Sakit",
                            onTap: () {
                              setModalState(() {
                                selectedFilter = "Sakit";
                              });
                            },
                          ),
                          _buildModalStatButton(
                            label: "Izin",
                            value: _systemService.getSiswaIzinCount(jamKe: selectedJam),
                            color: Colors.teal,
                            isSelected: selectedFilter == "Izin",
                            onTap: () {
                              setModalState(() {
                                selectedFilter = "Izin";
                              });
                            },
                          ),
                          _buildModalStatButton(
                            label: "Alfa",
                            value: _systemService.getSiswaAlfaCount(jamKe: selectedJam),
                            color: Colors.redAccent,
                            isSelected: selectedFilter == "Alfa",
                            onTap: () {
                              setModalState(() {
                                selectedFilter = "Alfa";
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: filteredStudents.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 48,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.grey[400],
                                      size: 40,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Tidak ada siswa dengan status $selectedFilter",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredStudents.length,
                                itemBuilder: (context, index) {
                                  final siswa = filteredStudents[index];
                                  final currentStatus = _systemService
                                      .getSiswaStatus(siswa.nisn, jamKe: selectedJam);

                                  Color statusColor;
                                  switch (currentStatus) {
                                    case "Hadir":
                                      statusColor = const Color(0xFF1D4ED8);
                                      break;
                                    case "Sakit":
                                      statusColor = Colors.amber[700]!;
                                      break;
                                    case "Izin":
                                      statusColor = Colors.teal;
                                      break;
                                    default:
                                      statusColor = Colors.redAccent;
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.withValues(
                                          alpha: 0.15,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: const Color(
                                            0xFF102C57,
                                          ).withValues(alpha: 0.08),
                                          child: Text(
                                            siswa.nama.substring(0, 1),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Color(0xFF102C57),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                siswa.nama,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                "Kelas ${siswa.kelas} • NISN ${siswa.nisn}",
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          height: 36,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: currentStatus,
                                              icon: Icon(
                                                Icons.arrow_drop_down,
                                                color: statusColor,
                                                size: 18,
                                              ),
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                              onChanged: (String? newStatus) {
                                                if (newStatus != null) {
                                                  setState(() {
                                                    _systemService
                                                        .setSiswaStatus(
                                                          siswa.nisn,
                                                          newStatus,
                                                          jamKe: selectedJam,
                                                        );
                                                  });
                                                  setModalState(() {});
                                                }
                                              },
                                              items:
                                                  <String>[
                                                    'Hadir',
                                                    'Sakit',
                                                    'Izin',
                                                    'Alfa',
                                                  ].map<
                                                    DropdownMenuItem<String>
                                                  >((String value) {
                                                    return DropdownMenuItem<
                                                      String
                                                    >(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalStatButton({
    required String label,
    required int value,
    required Color color,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$value",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected || onTap == null ? color : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected || onTap == null ? color : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onTap != null)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.arrow_drop_down,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF102C57),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF102C57),
          ),
        ),
      ],
    );
  }
}
