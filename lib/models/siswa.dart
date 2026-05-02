class Siswa {
  final String nisn;
  final String nama;
  final String kelas;
  final String ttl;
  final String alamat;
  final String namaOrtu;
  final String namaIbu;
  final String desa;
  final String kecamatan;
  final String kabupaten;
  final String provinsi;
  final String? fotoPath;

  const Siswa({
    required this.nisn,
    required this.nama,
    required this.kelas,
    required this.ttl,
    required this.alamat,
    required this.namaOrtu,
    required this.namaIbu,
    required this.desa,
    required this.kecamatan,
    required this.kabupaten,
    required this.provinsi,
    this.fotoPath,
  });

  Siswa copyWith({
    String? nisn,
    String? nama,
    String? kelas,
    String? ttl,
    String? alamat,
    String? namaOrtu,
    String? namaIbu,
    String? desa,
    String? kecamatan,
    String? kabupaten,
    String? provinsi,
    String? fotoPath,
  }) {
    return Siswa(
      nisn: nisn ?? this.nisn,
      nama: nama ?? this.nama,
      kelas: kelas ?? this.kelas,
      ttl: ttl ?? this.ttl,
      alamat: alamat ?? this.alamat,
      namaOrtu: namaOrtu ?? this.namaOrtu,
      namaIbu: namaIbu ?? this.namaIbu,
      desa: desa ?? this.desa,
      kecamatan: kecamatan ?? this.kecamatan,
      kabupaten: kabupaten ?? this.kabupaten,
      provinsi: provinsi ?? this.provinsi,
      fotoPath: fotoPath ?? this.fotoPath,
    );
  }
}
