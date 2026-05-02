# TODO - Add Student Additional Fields

## Task: Menambahkan field data siswa (tanggal lahir, alamat wali, dll)

- [x] Analisis file yang relevan (siswa.dart, tambah_siswa_page.dart, data_siswa_page.dart)
- [x] Edit tambah_siswa_page.dart - Tambahkan form field untuk ttl, alamat, namaOrtu
- [x] Edit data_siswa_page.dart - Tampilkan detail saat diklik
- [x] Testing dan validasi

## Update yang sudah dilakukan:

### 1. tambah_siswa_page.dart
- Ditambahkan TextEditingController untuk:
  - `_ttlController` (Tanggal Lahir)
  - `_alamatController` (Alamat Orang Tua/Wali)
  - `_namaOrtuController` (Nama Orang Tua/Wali)
- Ditambahkan form fields:
  - Tanggal Lahir (text field dengan hint contoh)
  - Alamat Orang Tua/Wali (multiline text field)
  - Nama Orang Tua/Wali (text field)
- Ditambahkan dispose untuk controller baru

### 2. data_siswa_page.dart
- Ditambahkan data lengkap siswa (ttl, alamat, namaOrtu) ke daftar
- Ditambahkan fungsi `_showDetailSiswa()` untuk menampilkan bottom sheet detail
- Ditambahkan fungsi `_buildDetailRow()` untuk menampilkan info dengan icon
- Ditambahkan InkWell untuk listenable pada list item
- Bottom sheet menampilkan: NISN, Tanggal Lahir, Alamat, Nama Orang Tua/Wali
