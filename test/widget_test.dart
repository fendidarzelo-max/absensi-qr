import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:absensi/main.dart';
import 'package:absensi/models/guru.dart';
import 'package:absensi/models/siswa.dart';
import 'package:absensi/models/jadwal.dart';

void main() {
  group('App Tests', () {
    testWidgets('App loads login page smoke test', (WidgetTester tester) async {
      await tester.pumpWidget(const AbsensiMadrasahApp());

      expect(find.text('Absensi Madrasah'), findsOneWidget);
      expect(find.byIcon(Icons.mosque), findsOneWidget);
    });

    testWidgets('Login form has required fields', (WidgetTester tester) async {
      await tester.pumpWidget(const AbsensiMadrasahApp());

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('MASUK SEKARANG'), findsOneWidget);
    });
  });

  group('Model Tests', () {
    test('Guru copyWith works correctly', () {
      const guru = Guru(
        nip: "123",
        nama: "Test Guru",
        mapel: "Matematika",
        kelas: "X-A",
        status: "Hadir",
      );

      final updated = guru.copyWith(status: "Izin");

      expect(updated.status, "Izin");
      expect(updated.nama, "Test Guru");
      expect(updated.nip, "123");
    });

    test('Guru toJson and fromJson works correctly', () {
      const guru = Guru(
        nip: "123",
        nama: "Test Guru",
        mapel: "Matematika",
        kelas: "X-A",
        status: "Hadir",
      );

      final json = guru.toJson();
      final restored = Guru.fromJson(json);

      expect(restored.nip, guru.nip);
      expect(restored.nama, guru.nama);
      expect(restored.status, guru.status);
    });

test('Siswa copyWith works correctly', () {
      const siswa = Siswa(
        nisn: "123456",
        nama: "Test Siswa",
        kelas: "X-A",
        ttl: "Bandung, 1 Jan 2008",
        alamat: "Jl. Test",
        namaOrtu: "Bpk. Test",
        namaIbu: "Ibu Test",
        desa: "Test Desa",
        kecamatan: "Test Kec",
        kabupaten: "Test Kab",
        provinsi: "Test Prov",
        rt: "01",
        rw: "02",
      );

      final updated = siswa.copyWith(kelas: "XI-A");

      expect(updated.kelas, "XI-A");
      expect(updated.nama, "Test Siswa");
    });

    test('Jadwal copyWith works correctly', () {
      const jadwal = Jadwal(
        jam: "07:30",
        mapel: "Matematika",
        guru: "Pak Budi",
        kelas: "X-A",
      );

      final updated = jadwal.copyWith(kelas: "X-B");

      expect(updated.kelas, "X-B");
      expect(updated.mapel, "Matematika");
    });

    test('Jadwal toJson and fromJson works correctly', () {
      const jadwal = Jadwal(
        jam: "07:30",
        mapel: "Matematika",
        guru: "Pak Budi",
        kelas: "X-A",
      );

      final json = jadwal.toJson();
      final restored = Jadwal.fromJson(json);

      expect(restored.jam, jadwal.jam);
      expect(restored.mapel, jadwal.mapel);
      expect(restored.guru, jadwal.guru);
    });
  });

  group('Equality Tests', () {
    test('Guru equality by NIP', () {
      const guru1 = Guru(
        nip: "123",
        nama: "Guru 1",
        mapel: "Matematika",
        kelas: "X-A",
        status: "Hadir",
      );

      const guru2 = Guru(
        nip: "123",
        nama: "Different Name",
        mapel: "Bahasa",
        kelas: "X-B",
        status: "Izin",
      );

      expect(guru1 == guru2, true);
    });
  });
}
