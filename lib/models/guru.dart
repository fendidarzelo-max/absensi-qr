class Guru {
  final String nip;
  final String nama;
  final String mapel;
  final String kelas;
  final String status; // Hadir, Izin, Alpha, Sakit, Tidak Hadir
  final String jabatan; // e.g. Guru Bidang, Wali Kelas, Kepala Sekolah
  final String hakAkses; // e.g. Admin, Staf, Guru
  final String agama;
  final String jenisKelamin;
  final String tanggalLahir;
  final String pendidikanTerakhir;

  const Guru({
    required this.nip,
    required this.nama,
    required this.mapel,
    required this.kelas,
    required this.status,
    this.jabatan = "Guru Mata Pelajaran",
    this.hakAkses = "Guru",
    this.agama = "",
    this.jenisKelamin = "",
    this.tanggalLahir = "",
    this.pendidikanTerakhir = "",
  });

  Guru copyWith({
    String? nip,
    String? nama,
    String? mapel,
    String? kelas,
    String? status,
    String? jabatan,
    String? hakAkses,
    String? agama,
    String? jenisKelamin,
    String? tanggalLahir,
    String? pendidikanTerakhir,
  }) {
    return Guru(
      nip: nip ?? this.nip,
      nama: nama ?? this.nama,
      mapel: mapel ?? this.mapel,
      kelas: kelas ?? this.kelas,
      status: status ?? this.status,
      jabatan: jabatan ?? this.jabatan,
      hakAkses: hakAkses ?? this.hakAkses,
      agama: agama ?? this.agama,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      pendidikanTerakhir: pendidikanTerakhir ?? this.pendidikanTerakhir,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nip': nip,
      'nama': nama,
      'mapel': mapel,
      'kelas': kelas,
      'status': status,
      'jabatan': jabatan,
      'hakAkses': hakAkses,
      'agama': agama,
      'jenisKelamin': jenisKelamin,
      'tanggalLahir': tanggalLahir,
      'pendidikanTerakhir': pendidikanTerakhir,
    };
  }

  factory Guru.fromJson(Map<String, dynamic> json) {
    return Guru(
      nip: json['nip'] as String,
      nama: json['nama'] as String,
      mapel: json['mapel'] as String,
      kelas: json['kelas'] as String,
      status: json['status'] as String,
      jabatan: json['jabatan'] as String? ?? "Guru Mata Pelajaran",
      hakAkses: json['hakAkses'] as String? ?? "Guru",
      agama: json['agama'] as String? ?? "",
      jenisKelamin: json['jenisKelamin'] as String? ?? "",
      tanggalLahir: json['tanggalLahir'] as String? ?? "",
      pendidikanTerakhir: json['pendidikanTerakhir'] as String? ?? "",
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Guru && other.nip == nip;
  }

  @override
  int get hashCode => nip.hashCode;
}
