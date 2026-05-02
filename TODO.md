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
  - `_desaController` (Desa)
  - `_kecamatanController` (Kecamatan)
  - `_kabupatenController` (Kabupaten)
  - `_provinsiController` (Provinsi)
  - `_namaIbuController` (Nama Ibu Kandung)
- Ditambahkan form fields:
  - Tanggal Lahir (text field dengan hint contoh)
  - Alamat Orang Tua/Wali (multiline text field)
  - Nama Orang Tua/Wali (text field)
  - Nama Ibu Kandung (text field)
  - Desa (text field)
  - Kecamatan (text field)
  - Kabupaten (text field)
  - Provinsi (text field)
- Ditambahkan dispose untuk controller baru

### 2. data_siswa_page.dart
- Ditambahkan data lengkap siswa ke daftar:
  - ttl (tanggal lahir)
  - alamat
  - namaOrtu (nama orang tua/wali)
  - namaIbu (nama ibu kandung)
  - desa
  - kecamatan
  - kabupaten
  - provinsi
- Ditambahkan fungsi `_showDetailSiswa()` untuk menampilkan bottom sheet detail
- Ditambahkan fungsi `_buildDetailRow()` untuk menampilkan info dengan icon
- Ditambahkan InkWell untuk listenable pada list item
- Bottom sheet height increased ke 85% untuk menampilkan semua field
- Bottom sheet menampilkan:
  - NISN
  - Tanggal Lahir
  - Alamat Orang Tua/Wali
  - Desa
  - Kecamatan
  - Kabupaten
  - Provinsi
  - Nama Orang Tua/Wali
  - Nama Ibu Kandung
