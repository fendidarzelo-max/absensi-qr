import 'package:flutter/material.dart';
import '../services/system_service.dart';

class HariLiburPage extends StatefulWidget {
  const HariLiburPage({super.key});

  @override
  State<HariLiburPage> createState() => _HariLiburPageState();
}

class _HariLiburPageState extends State<HariLiburPage> {
  final SystemService _systemService = SystemService();
  final _holidayNameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _systemService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _systemService.removeListener(_onStateChanged);
    _holidayNameController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF102C57),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addHoliday() {
    if (_holidayNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama libur tidak boleh kosong"), backgroundColor: Colors.red),
      );
      return;
    }

    _systemService.addHoliday(Holiday(
      nama: _holidayNameController.text,
      tanggal: _selectedDate,
    ));

    _holidayNameController.clear();
    setState(() {
      _selectedDate = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Hari Libur berhasil ditambahkan"), backgroundColor: Color(0xFF10B981)),
    );
  }

  String _formatDate(DateTime date) {
    final List<String> months = [
      "", "Januari", "Februari", "Maret", "April", "Mei", "Juni",
      "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ];
    return "${date.day} ${months[date.month]} ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final holidays = _systemService.holidays;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102C57),
        foregroundColor: Colors.white,
        title: const Text("Kalender Hari Libur"),
        elevation: 0,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Add Holiday Form
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.15)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Tambah Hari Libur",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF102C57)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Pencatatan tanggal libur agar mesin presensi menonaktifkan kalkulasi absensi pada hari tersebut.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    
                    TextField(
                      controller: _holidayNameController,
                      decoration: InputDecoration(
                        labelText: "Nama/Keterangan Hari Libur",
                        prefixIcon: const Icon(Icons.event),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Color(0xFF102C57)),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Tanggal Libur", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(_formatDate(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _addHoliday,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF102C57),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("TAMBAH HARI LIBUR", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right: Holiday list
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Daftar Libur Terdaftar",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF102C57)),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: holidays.isEmpty
                        ? const Center(child: Text("Belum ada hari libur terdaftar", style: TextStyle(color: Colors.grey)))
                        : ListView.separated(
                            itemCount: holidays.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final h = holidays[index];
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.redAccent,
                                  child: Icon(Icons.beach_access, color: Colors.white),
                                ),
                                title: Text(h.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(_formatDate(h.tanggal)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _systemService.deleteHoliday(index);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Hari Libur dihapus")),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
