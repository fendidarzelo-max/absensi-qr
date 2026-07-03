import 'package:flutter/material.dart';
import '../models/siswa.dart';
import '../services/student_service.dart';
import '../pages/tambah_siswa_page.dart';

class SiswaDetailModal {
  static void show(BuildContext context, Siswa siswa, {VoidCallback? onRefresh}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
              child: Text(
                (siswa.nama.isNotEmpty ? siswa.nama[0] : "?"),
                style: const TextStyle(
                  fontSize: 36,
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              siswa.nama,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Kelas ${siswa.kelasDisplay}",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.badge_outlined, "NISN", siswa.nisn),
                    _buildDetailRow(Icons.cake_outlined, "Tanggal Lahir", siswa.ttl),
                    _buildDetailRow(Icons.home_outlined, "Alamat Orang Tua/Wali", siswa.alamat),
                    _buildDetailRow(Icons.tag, "RT / RW", "RT. ${siswa.rt} / RW. ${siswa.rw}"),
                    _buildDetailRow(Icons.location_city_outlined, "Desa", siswa.desa),
                    _buildDetailRow(Icons.map_outlined, "Kecamatan", siswa.kecamatan),
                    _buildDetailRow(Icons.business_outlined, "Kabupaten", siswa.kabupaten),
                    _buildDetailRow(Icons.flag_outlined, "Provinsi", siswa.provinsi),
                    _buildDetailRow(Icons.person_pin_outlined, "Nama Orang Tua/Wali", siswa.namaOrtu),
                    _buildDetailRow(Icons.woman_outlined, "Nama Ibu Kandung", siswa.namaIbu),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Hapus Siswa"),
                            content: Text("Apakah Anda yakin ingin menghapus data siswa ${siswa.nama}?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("BATAL"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  StudentService().deleteSiswa(siswa.nisn);
                                  Navigator.pop(context); // close dialog
                                  Navigator.pop(context); // close bottom sheet
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Siswa ${siswa.nama} berhasil dihapus!"),
                                      backgroundColor: const Color(0xFFEF4444),
                                    ),
                                  );
                                  if (onRefresh != null) onRefresh();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("HAPUS"),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                      label: const Text("Hapus", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TambahSiswaPage(siswaToEdit: siswa),
                          ),
                        );
                        if (result == true && context.mounted) {
                          Navigator.pop(context); // Close bottom sheet
                          if (onRefresh != null) onRefresh();
                        }
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text("Edit Data", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
