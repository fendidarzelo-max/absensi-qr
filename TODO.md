# TODO - Perubahan "Data Kelas" otomatis dari data siswa

## Checklist
- [x] Update `lib/pages/data_kelas_page.dart`
  - [x] Ganti `_kelasList` hardcode menjadi daftar kelas dinamis dari `StudentService.getAllSiswa()` (unique `siswa.kelas`)
  - [x] Kolom "Wali" tampilkan default `-`
  - [x] Pastikan jumlah siswa per kelas tetap benar
- [x] Jalankan `flutter analyze` dan `flutter test` untuk validasi

