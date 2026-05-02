class Guru {
  final String nip;
  final String nama;
  final String mapel;
  final String kelas;
  final String status; // Hadir, Izin, Alpha, Sakit

  const Guru({
    required this.nip,
    required this.nama,
    required this.mapel,
    required this.kelas,
    required this.status,
  });

  Guru copyWith({
    String? nip,
    String? nama,
    String? mapel,
    String? kelas,
    String? status,
  }) {
    return Guru(
      nip: nip ?? this.nip,
      nama: nama ?? this.nama,
      mapel: mapel ?? this.mapel,
      kelas: kelas ?? this.kelas,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nip': nip,
      'nama': nama,
      'mapel': mapel,
      'kelas': kelas,
      'status': status,
    };
  }

  factory Guru.fromJson(Map<String, dynamic> json) {
    return Guru(
      nip: json['nip'] as String,
      nama: json['nama'] as String,
      mapel: json['mapel'] as String,
      kelas: json['kelas'] as String,
      status: json['status'] as String,
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
