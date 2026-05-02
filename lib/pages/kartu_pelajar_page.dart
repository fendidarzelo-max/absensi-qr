import 'package:flutter/material.dart';

class KartuPelajarPage extends StatelessWidget {
  const KartuPelajarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        title: const Text("Kartu Pelajar"),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                width: 350,
                height: 220,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF065F46), Color(0xFF10B981)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("KARTU PELAJAR MADRASAH", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        Container(
                          padding: const EdgeInsets.all(4),
                          color: Colors.white,
                          child: const Icon(Icons.qr_code, size: 40, color: Colors.black),
                        )
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white38),
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 40),
                        ),
                        const SizedBox(width: 15),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("M. Zidan Al-Fatih", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("NISN: 009822314", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            SizedBox(height: 5),
                            Text("KELAS X-A", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Text("SMART MADRASAH SYSTEM", style: TextStyle(color: Colors.white38, fontSize: 8, fontStyle: FontStyle.italic)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 350,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Mengunduh PDF...")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("EKSPOR PDF", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

