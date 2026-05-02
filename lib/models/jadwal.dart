class Jadwal {
  final String jam;
  final String mapel;
  final String guru;
  final String kelas;

  const Jadwal({
    required this.jam,
    required this.mapel,
    required this.guru,
    required this.kelas,
  });

  Jadwal copyWith({
    String? jam,
    String? mapel,
    String? guru,
    String? kelas,
  }) {
    return Jadwal(
      jam: jam ?? this.jam,
      mapel: mapel ?? this.mapel,
      guru: guru ?? this.guru,
      kelas: kelas ?? this.kelas,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jam': jam,
      'mapel': mapel,
      'guru': guru,
      'kelas': kelas,
    };
  }

  factory Jadwal.fromJson(Map<String, dynamic> json) {
    return Jadwal(
      jam: json['jam'] as String,
      mapel: json['mapel'] as String,
      guru: json['guru'] as String,
      kelas: json['kelas'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Jadwal && 
           other.jam == jam && 
           other.mapel == mapel && 
           other.guru == guru &&
           other.kelas == kelas;
  }

  @override
  int get hashCode => Object.hash(jam, mapel, guru, kelas);
}
