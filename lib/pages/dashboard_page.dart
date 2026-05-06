import 'package:flutter/material.dart';
import '../models/jadwal.dart';
import 'data_siswa_page.dart';
import 'data_kelas_page.dart';
import 'tambah_siswa_page.dart';
import 'absensi_qr_page.dart';
import 'jadwal_page.dart';
import 'administrasi_page.dart';
import 'kartu_pelajar_page.dart';
import 'ekspor_data_page.dart';
import 'login_page.dart';
import 'daftar_hadir_guru_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});


  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _searchQuery = "";

final Map<int, List<Jadwal>> _masterJadwal = {
    1: [
      const Jadwal(jam: "07:30", mapel: "Bahasa Arab", guru: "Ustadz Mansyur", kelas: "XI-C"),
      const Jadwal(jam: "09:00", mapel: "Fiqih", guru: "Ustadzah Maryam", kelas: "X-A"),
    ],
    2: [
      const Jadwal(jam: "07:30", mapel: "Tahfidz", guru: "Ustadz Zaid", kelas: "Semua Kelas"),
      const Jadwal(jam: "09:30", mapel: "Matematika", guru: "Ibu Rahma", kelas: "XI-B"),
    ],
    3: [
      const Jadwal(jam: "08:00", mapel: "Aqidah Akhlak", guru: "Ustadz Yusuf", kelas: "X-C"),
      const Jadwal(jam: "10:00", mapel: "Sejarah Islam", guru: "Ustadz Hamzah", kelas: "XII-A"),
    ],
  };

  List<Jadwal> get _currentJadwal {
    int day = DateTime.now().weekday;
    return _masterJadwal[day] ?? [const Jadwal(jam: "08:00", mapel: "Pembelajaran Umum", guru: "Staff Pengajar", kelas: "Regular")];
  }

  String get _currentDayName {
    List<String> names = ["", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"];
    return names[DateTime.now().weekday];
  }

void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
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
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 800;

          return Row(
            children: [
              if (isDesktop) _buildSidebar(),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 25,
                                  backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=Ustadz+Fauzi&background=10b981&color=fff'),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Ustadz Ahmad Fauzi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    Text("Administrator Utama", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ),
                                const Spacer(),
                                if (!isDesktop) IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
                              ],
                            ),
                            const SizedBox(height: 24),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                              ),
                              child: TextField(
                                onChanged: (val) => setState(() => _searchQuery = val),
                                decoration: const InputDecoration(
                                  hintText: "Cari data siswa, kelas, atau guru...",
                                  border: InputBorder.none,
                                  icon: Icon(Icons.search, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            Row(
                              children: [
                                _buildStatCard("Total Siswa", "1,240", Icons.people, Colors.blue),
                                const SizedBox(width: 16),
                                _buildStatCard("Total Kelas", "42", Icons.door_front_door, const Color(0xFF10B981)),
                              ],
                            ),
                            const SizedBox(height: 32),

                            const Text("Dashboard Utama", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildMenuGrid(isDesktop),

                            const SizedBox(height: 32),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Jadwal Mengajar ($_currentDayName)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const Text("Otomatis Terupdate", style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._currentJadwal.map((j) => _buildJadwalItem(j)).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school, color: Color(0xFF10B981)),
              SizedBox(width: 10),
              Text("SmartAbsen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          const SizedBox(height: 40),
          _sidebarItem(Icons.dashboard, "Dashboard", true, () {}),
          _sidebarItem(Icons.people, "Data Siswa", false, () => _navigateTo(const DataSiswaPage())),
           _sidebarItem(Icons.qr_code_scanner, "Absen Qr Siswa", false, () => _navigateTo(const AbsensiQRPage())),
_sidebarItem(Icons.badge, "Daftar Hadir Guru", false, () => _navigateTo(const DaftarHadirGuruPage())),
          _sidebarItem(Icons.calendar_month, "Jadwal", false, () => _navigateTo(const JadwalPage())),
          _sidebarItem(Icons.file_copy, "Administrasi", false, () => _navigateTo(const AdministrasiPage())),
          const Spacer(),
_sidebarItem(Icons.logout, "Keluar", false, () {
            _showLogoutConfirmation(context);
          }, isRed: true),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, bool active, VoidCallback onTap, {bool isRed = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? Colors.white : (isRed ? Colors.red : Colors.grey[600])),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: active ? Colors.white : (isRed ? Colors.red : Colors.black87), fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid(bool isDesktop) {
    final List<Map<String, dynamic>> menus = [
      {"icon": Icons.class_outlined, "label": "Data Kelas", "page": DataKelasPage()},

      {"icon": Icons.person_add_alt_1, "label": "Tambah Siswa", "page": const TambahSiswaPage()},
      {"icon": Icons.qr_code_2, "label": "Absensi QR Siswa", "page": const AbsensiQRPage()},
{"icon": Icons.badge, "label": "Daftar Hadir Guru", "page": const DaftarHadirGuruPage()},
      {"icon": Icons.badge, "label": "Kartu Pelajar", "page": const KartuPelajarPage()},
      {"icon": Icons.import_export, "label": "Ekspor Data", "page": const EksporDataPage()},
      {"icon": Icons.admin_panel_settings, "label": "Administrasi", "page": const AdministrasiPage()},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: menus.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () => _navigateTo(menus[index]['page']),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(menus[index]['icon'], color: const Color.fromARGB(255, 8, 56, 210), size: 30),
                const SizedBox(height: 8),
                Text(menus[index]['label'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildJadwalItem(Jadwal j) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF065F46),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(j.jam, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(j.mapel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("${j.guru} • Kelas ${j.kelas}", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Color.fromARGB(57, 2, 70, 255), size: 14),
        ],
      ),
    );
  }
}

