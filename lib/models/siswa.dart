class Siswa {
  final String nisn;
  final String nama;
  final String kelas;
  final String ttl;
  final String alamat;
  final String namaOrtu;
  final String? fotoPath;

  const Siswa({
    required this.nisn,
    required this.nama,
    required this.kelas,
    required this.ttl,
    required this.alamat,
    required this.namaOrtu,
    this.fotoPath,
  });

  Siswa copyWith({
    String? nisn,
    String? nama,
    String? kelas,
    String? ttl,
    String? alamat,
    String? namaOrtu,
    String? fotoPath,
  }) {
    return Siswa(
      nisn: nisn ?? this.nisn,
      nama: nama ?? this.nama,
      kelas: kelas ?? this.kelas,
      ttl: ttl ?? this.ttl,
      alamat: alamat ?? this.alamat,
      namaOrtu: namaOrtu ?? this.namaOrtu,
      fotoPath: fotoPath ?? this.fotoPath,
    );
  }
}
