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
  final String rt;
  final String rw;
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
    required this.rt,
    required this.rw,
    this.fotoPath,
  });

  String get kelasDisplay {
    final k = kelas.trim();
    if (k.toUpperCase().contains('MI') || 
        k.toUpperCase().contains('MTS') || 
        k.toUpperCase().contains('MA')) {
      return k;
    }
    
    final clean = k.toUpperCase().replaceAll('KLS', '').replaceAll('KELAS', '').trim();
    if (clean == '1' || clean == '2' || clean == '3' || clean == '4' || clean == '5' || clean == '6' ||
        clean == 'I' || clean == 'II' || clean == 'III' || clean == 'IV' || clean == 'V' || clean == 'VI') {
      return k.contains('KLS') ? '$k MI' : 'KLS $k MI';
    }
    
    if (clean == '7' || clean == '8' || clean == '9' ||
        clean == 'VII' || clean == 'VIII' || clean == 'IX') {
      return k.contains('KLS') ? '$k MTS' : 'KLS $k MTS';
    }
    
    if (clean == '10' || clean == '11' || clean == '12' ||
        clean == 'X' || clean == 'XI' || clean == 'XII') {
      return k.contains('KLS') ? '$k MA' : 'KLS $k MA';
    }
    
    return k;
  }

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
    String? rt,
    String? rw,
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
      rt: rt ?? this.rt,
      rw: rw ?? this.rw,
      fotoPath: fotoPath ?? this.fotoPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nisn': nisn,
      'nama': nama,
      'kelas': kelas,
      'ttl': ttl,
      'alamat': alamat,
      'namaOrtu': namaOrtu,
      'namaIbu': namaIbu,
      'desa': desa,
      'kecamatan': kecamatan,
      'kabupaten': kabupaten,
      'provinsi': provinsi,
      'rt': rt,
      'rw': rw,
      'fotoPath': fotoPath,
    };
  }

  factory Siswa.fromJson(Map<String, dynamic> json) {
    return Siswa(
      nisn: json['nisn'] as String,
      nama: json['nama'] as String,
      kelas: json['kelas'] as String,
      ttl: json['ttl'] as String? ?? "-",
      alamat: json['alamat'] as String? ?? "-",
      namaOrtu: json['namaOrtu'] as String? ?? "-",
      namaIbu: json['namaIbu'] as String? ?? "-",
      desa: json['desa'] as String? ?? "-",
      kecamatan: json['kecamatan'] as String? ?? "-",
      kabupaten: json['kabupaten'] as String? ?? "-",
      provinsi: json['provinsi'] as String? ?? "-",
      rt: json['rt'] as String? ?? "-",
      rw: json['rw'] as String? ?? "-",
      fotoPath: json['fotoPath'] as String?,
    );
  }
}
