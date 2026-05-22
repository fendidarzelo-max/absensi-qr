import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const AbsensiMadrasahApp());
}

class AbsensiMadrasahApp extends StatelessWidget {
  const AbsensiMadrasahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Absensi Madrasah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF102C57),
          primary: const Color(0xFF102C57),
          secondary: const Color(0xFF1D4ED8),
        ),
        fontFamily: 'Sans-Serif',
      ),
      home: const LoginPage(),
    );
  }
}