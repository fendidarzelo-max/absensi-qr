import 'package:excel/excel.dart';
import '../models/siswa.dart';
import '../models/guru.dart';

class ExcelHelper {
  // --- SISWA (STUDENT) ---
  
  static const List<String> _siswaHeaders = [
    'NISN',
    'Nama Lengkap',
    'Kelas',
    'TTL (Tempat Tanggal Lahir)',
    'Alamat',
    'Nama Wali / Ortu',
    'Nama Ibu Kandung',
    'Desa / Kelurahan',
    'Kecamatan',
    'Kabupaten / Kota',
    'Provinsi',
    'RT',
    'RW'
  ];

  /// Generate empty student import template
  static List<int> generateSiswaTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Add headers
    sheet.appendRow(_siswaHeaders.map((e) => TextCellValue(e)).toList());

    // Add 1 sample row to help the user understand
    sheet.appendRow([
      TextCellValue('1234567890'),
      TextCellValue('Budi Santoso'),
      TextCellValue('7A'),
      TextCellValue('Sampang, 12 Juni 2012'),
      TextCellValue('Jl. Miftahul Ulum No. 12'),
      TextCellValue('Ahmad Santoso'),
      TextCellValue('Siti Aminah'),
      TextCellValue('Pancor'),
      TextCellValue('Ketapang'),
      TextCellValue('Sampang'),
      TextCellValue('Jawa Timur'),
      TextCellValue('02'),
      TextCellValue('04')
    ]);

    return excel.save() ?? [];
  }

  /// Generate student excel from database records
  static List<int> exportSiswaToExcel(List<Siswa> siswaList) {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Add headers
    sheet.appendRow(_siswaHeaders.map((e) => TextCellValue(e)).toList());

    // Add data rows
    for (var s in siswaList) {
      sheet.appendRow([
        TextCellValue(s.nisn),
        TextCellValue(s.nama),
        TextCellValue(s.kelas),
        TextCellValue(s.ttl),
        TextCellValue(s.alamat),
        TextCellValue(s.namaOrtu),
        TextCellValue(s.namaIbu),
        TextCellValue(s.desa),
        TextCellValue(s.kecamatan),
        TextCellValue(s.kabupaten),
        TextCellValue(s.provinsi),
        TextCellValue(s.rt),
        TextCellValue(s.rw)
      ]);
    }

    return excel.save() ?? [];
  }

  /// Parse uploaded student excel file bytes to Siswa objects
  static List<Siswa> parseSiswaExcel(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    final List<Siswa> importedSiswa = [];

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null || sheet.maxRows <= 1) continue;

      // Extract headers from first row
      final firstRow = sheet.rows.first;
      final headerMap = <String, int>{};
      for (int i = 0; i < firstRow.length; i++) {
        final val = firstRow[i]?.value?.toString().trim().toLowerCase() ?? '';
        if (val.isNotEmpty) {
          headerMap[val] = i;
        }
      }

      // Helper to retrieve cell string by header keyword, falling back to column index
      String getCellText(List<Data?> row, List<String> headerKeywords, int fallbackColIndex) {
        int colIndex = fallbackColIndex;
        // Search for matching header keyword
        for (var kw in headerKeywords) {
          final cleanKw = kw.toLowerCase().trim();
          final match = headerMap.keys.firstWhere(
            (k) => k == cleanKw || k.contains(cleanKw),
            orElse: () => '',
          );
          if (match.isNotEmpty) {
            colIndex = headerMap[match]!;
            break;
          }
        }

        if (colIndex < row.length) {
          return row[colIndex]?.value?.toString().trim() ?? '';
        }
        return '';
      }

      // Iterate starting from second row (index 1)
      for (int r = 1; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        if (row.isEmpty) continue;

        // Skip rows where name and nisn are empty
        final nisn = getCellText(row, ['nisn', 'nomor induk'], 0);
        final nama = getCellText(row, ['nama', 'lengkap'], 1);
        final kelas = getCellText(row, ['kelas'], 2);

        if (nisn.isEmpty && nama.isEmpty) continue;

        final ttl = getCellText(row, ['ttl', 'tempat tanggal lahir', 'lahir'], 3);
        final alamat = getCellText(row, ['alamat'], 4);
        final namaOrtu = getCellText(row, ['wali', 'ortu', 'orang tua'], 5);
        final namaIbu = getCellText(row, ['ibu'], 6);
        final desa = getCellText(row, ['desa', 'kelurahan'], 7);
        final kecamatan = getCellText(row, ['kecamatan'], 8);
        final kabupaten = getCellText(row, ['kabupaten', 'kota'], 9);
        final provinsi = getCellText(row, ['provinsi'], 10);
        final rt = getCellText(row, ['rt'], 11);
        final rw = getCellText(row, ['rw'], 12);

        importedSiswa.add(Siswa(
          nisn: nisn.isNotEmpty ? nisn : DateTime.now().millisecondsSinceEpoch.toString(),
          nama: nama.isNotEmpty ? nama : 'Tanpa Nama',
          kelas: kelas.isNotEmpty ? kelas : '7A',
          ttl: ttl.isNotEmpty ? ttl : '-',
          alamat: alamat.isNotEmpty ? alamat : '-',
          namaOrtu: namaOrtu.isNotEmpty ? namaOrtu : '-',
          namaIbu: namaIbu.isNotEmpty ? namaIbu : '-',
          desa: desa.isNotEmpty ? desa : '-',
          kecamatan: kecamatan.isNotEmpty ? kecamatan : '-',
          kabupaten: kabupaten.isNotEmpty ? kabupaten : '-',
          provinsi: provinsi.isNotEmpty ? provinsi : '-',
          rt: rt.isNotEmpty ? rt : '-',
          rw: rw.isNotEmpty ? rw : '-',
        ));
      }
    }

    return importedSiswa;
  }

  // --- GURU (TEACHER) ---
  
  static const List<String> _guruHeaders = [
    'NIP / Kode Guru',
    'Nama Lengkap',
    'Jenis Kelamin (Laki-laki/Perempuan)',
    'Agama',
    'Mata Pelajaran (Mapel)',
    'Jabatan',
    'Jadwal Mengajar (JSON - Opsional)'
  ];

  /// Generate empty teacher import template
  static List<int> generateGuruTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Add headers
    sheet.appendRow(_guruHeaders.map((e) => TextCellValue(e)).toList());

    // Add 1 sample row to help the user understand
    sheet.appendRow([
      TextCellValue('198012062005011002'),
      TextCellValue('Drs. Ahmad Jufri'),
      TextCellValue('Laki-laki'),
      TextCellValue('Islam'),
      TextCellValue('Matematika'),
      TextCellValue('Guru Mata Pelajaran'),
      TextCellValue('{"Senin":["MI","MTS"],"Selasa":["MA"]}')
    ]);

    return excel.save() ?? [];
  }

  /// Generate teacher excel from database records
  static List<int> exportGuruToExcel(List<Guru> guruList) {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Add headers
    sheet.appendRow(_guruHeaders.map((e) => TextCellValue(e)).toList());

    // Add data rows
    for (var g in guruList) {
      sheet.appendRow([
        TextCellValue(g.nip),
        TextCellValue(g.nama),
        TextCellValue(g.jenisKelamin),
        TextCellValue(g.agama),
        TextCellValue(g.mapel),
        TextCellValue(g.jabatan),
        TextCellValue(g.jadwalMengajar ?? '')
      ]);
    }

    return excel.save() ?? [];
  }

  /// Parse uploaded teacher excel file bytes to Guru objects
  static List<Guru> parseGuruExcel(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    final List<Guru> importedGuru = [];

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null || sheet.maxRows <= 1) continue;

      // Extract headers from first row
      final firstRow = sheet.rows.first;
      final headerMap = <String, int>{};
      for (int i = 0; i < firstRow.length; i++) {
        final val = firstRow[i]?.value?.toString().trim().toLowerCase() ?? '';
        if (val.isNotEmpty) {
          headerMap[val] = i;
        }
      }

      // Helper to retrieve cell string by header keyword, falling back to column index
      String getCellText(List<Data?> row, List<String> headerKeywords, int fallbackColIndex) {
        int colIndex = fallbackColIndex;
        // Search for matching header keyword
        for (var kw in headerKeywords) {
          final cleanKw = kw.toLowerCase().trim();
          final match = headerMap.keys.firstWhere(
            (k) => k == cleanKw || k.contains(cleanKw),
            orElse: () => '',
          );
          if (match.isNotEmpty) {
            colIndex = headerMap[match]!;
            break;
          }
        }

        if (colIndex < row.length) {
          return row[colIndex]?.value?.toString().trim() ?? '';
        }
        return '';
      }

      // Iterate starting from second row (index 1)
      for (int r = 1; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        if (row.isEmpty) continue;

        // Skip rows where name and NIP are empty
        final nip = getCellText(row, ['nip', 'kode', 'induk'], 0);
        final nama = getCellText(row, ['nama', 'lengkap'], 1);
        final jenisKelamin = getCellText(row, ['kelamin', 'gender', 'jenis kelamin'], 2);
        final agama = getCellText(row, ['agama'], 3);
        final mapel = getCellText(row, ['mapel', 'pelajaran'], 4);
        final jabatan = getCellText(row, ['jabatan'], 5);
        final jadwal = getCellText(row, ['jadwal', 'mengajar'], 6);

        if (nip.isEmpty && nama.isEmpty) continue;

        importedGuru.add(Guru(
          nip: nip.isNotEmpty ? nip : DateTime.now().millisecondsSinceEpoch.toString(),
          nama: nama.isNotEmpty ? nama : 'Tanpa Nama',
          mapel: mapel.isNotEmpty ? mapel : '-',
          kelas: '-',
          status: 'Tidak Hadir',
          jabatan: jabatan.isNotEmpty ? jabatan : 'Guru Mata Pelajaran',
          hakAkses: 'Guru',
          agama: agama.isNotEmpty ? agama : 'Islam',
          jenisKelamin: jenisKelamin.isNotEmpty ? jenisKelamin : 'Laki-laki',
          tanggalLahir: '-',
          pendidikanTerakhir: '-',
          jadwalMengajar: jadwal.isNotEmpty ? jadwal : null,
        ));
      }
    }

    return importedGuru;
  }
}
