import 'package:flutter/material.dart';

class DataSiswaPage extends StatefulWidget {
  const DataSiswaPage({super.key});

  @override
  State<DataSiswaPage> createState() => _DataSiswaPageState();
}

class _DataSiswaPageState extends State<DataSiswaPage> {
  String _searchQuery = "";

  final List<Map<String, String>> _siswaList = [
    {"nama": "M. Zidan Al-Fatih", "nisn": "009822314", "kelas": "X-A", "ttl": "Bandung, 15 Januari 2008", "alamat": "Jl. Merdeka No. 10", "namaOrtu": "Ahmad Susanto"},
    {"nama": "Aisyah Putri", "nisn": "009822315", "kelas": "X-A", "ttl": "Jakarta, 20 Februari 2008", "alamat": "Jl. Sudirman No. 25", "namaOrtu": "Budi Santoso"},
    {"nama": "Ahmad Fauzan", "nisn": "009822316", "kelas": "X-B", "ttl": "Surabaya, 10 Maret 2008", "alamat": "Jl. Asia Afrika No. 5", "namaOrtu": "Hendra Wijaya"},
    {"nama": "Fatimah Az-Zahra", "nisn": "009822317", "kelas": "XI-A", "ttl": "Medan, 5 April 2007", "alamat": "Jl. Gatot Subroto No. 15", "namaOrtu": "Rahmat Hidayat"},
    {"nama": "Umar Bin Khattab", "nisn": "009822318", "kelas": "XI-B", "ttl": "Makassar, 12 Mei 2007", "alamat": "Jl. Pettarani No. 30", "namaOrtu": "Andi Pratama"},
    {"nama": "Khadijah Al-Kubra", "nisn": "009822319", "kelas": "XII-A", "ttl": "Bandung, 8 Juni 2006", "alamat": "Jl. Dago No. 45", "namaOrtu": "Dedi Kurniawan"},
    {"nama": "Ali Bin Abi Thalib", "nisn": "009822320", "kelas": "XII-B", "ttl": "Semarang, 25 Juli 2006", "alamat": "Jl. Ahmad Yani No. 60", "namaOrtu": "Fajar Nugraha"},
    {"nama": "Zainab Binti Ali", "nisn": "009822321", "kelas": "X-A", "ttl": "Yogyakarta, 14 Agustus 2008", "alamat": "Jl. Malioboro No. 20", "namaOrtu": "Galih Permana"},
    {"nama": "Bilal Bin Rabah", "nisn": "009822322", "kelas": "X-B", "ttl": "Denpasar, 30 September 2008", "alamat": "Jl. Ngurah Rai No. 8", "namaOrtu": "Made Surya"},
    {"nama": "Sumayyah Binti Khayyat", "nisn": "009822323", "kelas": "XI-A", "ttl": "Padang, 22 Oktober 2007", "alamat": "Jl. Pasar Baru No. 12", "namaOrtu": "Wendra Osman"},
  ];

  List<Map<String, String>> get _filteredSiswa {
    if (_searchQuery.isEmpty) return _siswaList;
    return _siswaList.where((s) =>
      s["nama"]!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      s["nisn"]!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      s["kelas"]!.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _showDetailSiswa(BuildContext context, Map<String, String> siswa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
              backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
              child: Text(
                siswa["nama"]![0],
                style: const TextStyle(
                  fontSize: 36,
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              siswa["nama"]!,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Kelas ${siswa["kelas"]}",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.badge_outlined, "NISN", siswa["nisn"]!),
                    _buildDetailRow(Icons.cake_outlined, "Tanggal Lahir", siswa["ttl"]!),
                    _buildDetailRow(Icons.home_outlined, "Alamat Orang Tua/Wali", siswa["alamat"]!),
                    _buildDetailRow(Icons.person_pin_outlined, "Nama Orang Tua/Wali", siswa["namaOrtu"]!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
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
              color: const Color(0xFF10B981).withOpacity(0.1),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        title: const Text("Data Siswa"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
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
                  hintText: "Cari nama, NISN, atau kelas...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _filteredSiswa.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final siswa = _filteredSiswa[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: InkWell(
                      onTap: () => _showDetailSiswa(context, siswa),
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                          child: Text(siswa["nama"]![0], style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                        ),
                        title: Text(siswa["nama"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("NISN: ${siswa["nisn"]} • Kelas ${siswa["kelas"]}"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
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
}
