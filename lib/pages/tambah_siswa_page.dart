import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/siswa.dart';
import '../services/student_service.dart';

class TambahSiswaPage extends StatefulWidget {
  final Siswa? siswaToEdit;
  final String? defaultKelas;
  const TambahSiswaPage({super.key, this.siswaToEdit, this.defaultKelas});

  @override
  State<TambahSiswaPage> createState() => _TambahSiswaPageState();
}

class _TambahSiswaPageState extends State<TambahSiswaPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _nisnController = TextEditingController();
  final _ttlController = TextEditingController();
  final _alamatController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _namaOrtuController = TextEditingController();
  final _desaController = TextEditingController();
  final _kecamatanController = TextEditingController();
  final _kabupatenController = TextEditingController();
  final _provinsiController = TextEditingController();
  final _namaIbuController = TextEditingController();
  late String _selectedKelas;
  bool _isLoading = false;
  String? _selectedProvinsiId;
  String? _selectedKabupatenId;
  String? _selectedKecamatanId;

  final List<String> _kelasOptions = ["KLS I MI", "KLS II MI", "KLS III MI", "KLS IV MI", "KLS V MI", "KLS VI MI", "KLS I MTS", "KLS II MTS", "KLS III MTS", "KLS I MA", "KLS II MA", "KLS III MA"];

  @override
  void initState() {
    super.initState();
    _selectedKelas = _kelasOptions.first;
    if (widget.defaultKelas != null) {
      if (!_kelasOptions.contains(widget.defaultKelas)) {
        _kelasOptions.add(widget.defaultKelas!);
        _kelasOptions.sort();
      }
      _selectedKelas = widget.defaultKelas!;
    }
    if (widget.siswaToEdit != null) {
      final s = widget.siswaToEdit!;
      _namaController.text = s.nama;
      _nisnController.text = s.nisn;
      if (!_kelasOptions.contains(s.kelas)) {
        _kelasOptions.add(s.kelas);
        _kelasOptions.sort();
      }
      _selectedKelas = s.kelas;
      _ttlController.text = s.ttl;
      _alamatController.text = s.alamat;
      _rtController.text = s.rt;
      _rwController.text = s.rw;
      _namaOrtuController.text = s.namaOrtu;
      _desaController.text = s.desa;
      _kecamatanController.text = s.kecamatan;
      _kabupatenController.text = s.kabupaten;
      _provinsiController.text = s.provinsi;
      _namaIbuController.text = s.namaIbu;
    }
    _provinsiController.addListener(_onProvinsiChanged);
  }

  void _onProvinsiChanged() {
    final text = _provinsiController.text.trim().toLowerCase();
    if (text == 'jawa timur' || text == 'jatim') {
      if (_kabupatenController.text.trim().isEmpty) {
        _kabupatenController.text = "Sampang";
      }
      if (_kecamatanController.text.trim().isEmpty) {
        _kecamatanController.text = "Ketapang";
      }
      if (_desaController.text.trim().isEmpty) {
        _desaController.text = "Pancor";
      }
    }
  }

  static const Map<String, Map<String, Map<String, List<String>>>> _indonesianRegions = {
    "Aceh": {
      "Banda Aceh": {
        "Syiah Kuala": ["Kopelma Darussalam", "Rukoh", "Jeulingke"]
      }
    },
    "Sumatera Utara": {
      "Medan": {
        "Medan Baru": ["Padang Bulan", "Titi Rantai", "Merdeka"]
      }
    },
    "Sumatera Barat": {
      "Padang": {
        "Padang Barat": ["Purus", "Kampung Pondok", "Belakang Tangsi"]
      }
    },
    "Riau": {
      "Pekanbaru": {
        "Tampan": ["Simpang Baru", "Delima", "Sidomulyo Barat"]
      }
    },
    "Kepulauan Riau": {
      "Tanjungpinang": {
        "Tanjungpinang Kota": ["Senggarang", "Penyengat", "Kampung Bugis"]
      }
    },
    "Jambi": {
      "Jambi": {
        "Telanaipura": ["Telanaipura", "Pematang Sulur", "Simpang IV Sipin"]
      }
    },
    "Sumatera Selatan": {
      "Palembang": {
        "Ilir Timur I": ["20 Ilir", "13 Ilir", "14 Ilir"]
      }
    },
    "Kepulauan Bangka Belitung": {
      "Pangkalpinang": {
        "Bukit Intan": ["Sriwijaya", "Temberan", "Air Itam"]
      }
    },
    "Bengkulu": {
      "Bengkulu": {
        "Ratu Agung": ["Lempuing", "Tanah Patah", "Nusa Indah"]
      }
    },
    "Lampung": {
      "Bandar Lampung": {
        "Tanjung Karang Pusat": ["Durian Payung", "Gotong Royong", "Kaliawi"]
      }
    },
    "DKI Jakarta": {
      "Jakarta Pusat": {
        "Gambir": ["Gambir", "Cideng", "Petojo Utara", "Petojo Selatan", "Kebon Kelapa", "Duri Pulo"]
      }
    },
    "Jawa Barat": {
      "Bandung": {
        "Coblong": ["Dago", "Sadang Serang", "Sekeloa", "Lebak Siliwangi", "Cipaganti"]
      }
    },
    "Banten": {
      "Serang": {
        "Serang": ["Serang", "Kagungan", "Lontarbaru", "Lopang", "Unyur"]
      }
    },
    "Jawa Tengah": {
      "Semarang": {
        "Semarang Tengah": ["Sekayu", "Miroto", "Brumbungan", "Gabahan", "Kembangsari"]
      }
    },
    "DI Yogyakarta": {
      "Sleman": {
        "Depok": ["Caturtunggal", "Condongcatur", "Maguwoharjo"]
      }
    },
    "Jawa Timur": {
      "Sampang": {
        "Ketapang": ["Pancor", "Ketapang Daya", "Ketapang Laok", "Ketapang Barat", "Banyusokah", "Bunten Barat", "Bunten Timur", "Paeleng", "Rabiyan", "Karang Anyar", "Bira Barat", "Bira Timur"],
        "Robatal": ["Robatal", "Jelgung", "Bapelle", "Sogian", "Torjunan", "Tragih", "Lepelle", "Pandiyangan", "Leber"],
        "Karang Penang": ["Karang Penang Onjur", "Karang Penang Oloh", "Tlambah", "Bulmatet", "Poreh", "Batu Poro Barat", "Batu Poro Timur"],
        "Omben": ["Omben", "Rapa Laok", "Rapa Daya", "Sogian", "Kebun Sareh", "Karang Gayam", "Jrangoan", "Tambak"],
        "Sampang": ["Gunung Sekar", "Rongtengah", "Polagan", "Karang Dalam", "Banyuanyar", "Dalpenang", "Pasean", "Panggung"],
        "Camplong": ["Camplong", "Dharma Camplong", "Taddan", "Sejati", "Banyumas", "Tambaan", "Plampaan", "Pamolaan"],
        "Torjun": ["Torjun", "Bringin Nunggal", "Kramat", "Dulang", "Patapan", "Kanjar", "Jerra Karang"],
        "Sokobanah": ["Sokobanah Daya", "Sokobanah Laok", "Tamberu Laok", "Tobai Barat", "Tobai Timur", "Bira Tengah"],
        "Banyuates": ["Banyuates", "Jatra Timur", "Kradenan", "Larangan Tokol", "Masaran", "Montor", "Nepo", "Planggaran Barat", "Planggaran Timur", "Tolak", "Tlangoh"],
        "Kedungdung": ["Kedungdung", "Bajrasoka", "Banjar Billah", "Banyupelle", "Daleman", "Gunung Eleh", "Mekar Sari", "Nangkah", "Ombak", "Palenggiyan", "Prajjan", "Raba", "Rohayu"],
        "Pangarengan": ["Pangarengan", "Apaan", "Gulbung", "Pecanggaan", "Panyepen"],
        "Sreseh": ["Sreseh", "Bungbaruh", "Disanah", "Klobur", "Labuhan", "Marparan", "Noreh", "Plasah", "Ploso", "Rapa Kebon", "Taman"],
      },
      "Bangkalan": {
        "Bangkalan": ["Bangkalan", "Demangan", "Kemayoran", "Mekar", "Mlajah", "Pejagan", "Pangeranan", "Kraton"],
        "Burneh": ["Burneh", "Arosbaya", "Banangkah", "Jambuh", "Langkap", "Sobih", "Tunjung"],
        "Arosbaya": ["Arosbaya", "Balung", "Batona", "Berbeluk", "Dandang", "Galis", "Karang Duwak", "Lajing", "Makam Agung", "Pandabah", "Plakaran", "Tengket"],
        "Klampis": ["Klampis", "Banyuanyar", "Bulung", "Karang Leman", "Klampis Barat", "Klampis Timur", "Lajing", "Muara", "Panyaksagan", "Tegangger", "Tobaddung"],
        "Sepulu": ["Sepulu", "Bangkes", "Geger", "Kelbung", "Klabetan", "Maneron", "Prancak", "Saplasah", "Tanah Merah"],
        "Tanjungbumi": ["Tanjungbumi", "Banyusangka", "Bungkeng", "Macajah", "Paseseh", "Tagungguh", "Telaga Biru", "Tlagah"],
      },
      "Pamekasan": {
        "Pamekasan": ["Barurambat Kota", "Bugih", "Jungcangcang", "Kowel", "Ladin", "Nyalabu Daya", "Nyalabu Laok", "Parteker", "Patemon"],
        "Tlanakan": ["Tlanakan", "Ambat", "Branta Pesisir", "Branta Tinggi", "Bukek", "Dabuan", "Grompol", "Kramat", "Lalang", "Mangar", "Panglegur", "Tlesah"],
        "Pademawu": ["Pademawu", "Babadan", "Bunder", "Durbukan", "Jureman", "Murtajih", "Pademawu Barat", "Pademawu Timur", "Padelegan", "Pagagan", "Prekbun", "Sentol", "Tambung"],
        "Galis": ["Galis", "Artodung", "Bulay", "Molan", "Pandan", "Polagan", "Tobungan"],
      },
      "Sumenep": {
        "Kota Sumenep": ["Bangselok", "Karangduak", "Kepanjin", "Pajagalan", "Pamolokan", "Giling", "Kolor", "Marek", "Pangarangan"],
        "Kalianget": ["Kalianget Barat", "Kalianget Timur", "Kalimook", "Karanganyar", "Kertasada", "Marengan Laok", "Pinggirpapas"],
        "Talango": ["Talango", "Cabbiya", "Gapurana", "Padike", "Kombangan", "Palasa"],
      }
    },
    "Bali": {
      "Denpasar": {
        "Denpasar Selatan": ["Sanur", "Panjer", "Sidakarya", "Renon"]
      }
    },
    "Nusa Tenggara Barat": {
      "Mataram": {
        "Mataram": ["Pejanggik", "Mataram Barat", "Pagentan"]
      }
    },
    "Nusa Tenggara Timur": {
      "Kupang": {
        "Oebobo": ["Oebobo", "Fatululi", "Liliba"]
      }
    },
    "Kalimantan Barat": {
      "Pontianak": {
        "Pontianak Kota": ["Tengah", "Mariana", "Sungai Bangkong"]
      }
    },
    "Kalimantan Tengah": {
      "Palangkaraya": {
        "Pahandut": ["Pahandut", "Panarung", "Langkai"]
      }
    },
    "Kalimantan Selatan": {
      "Banjarmasin": {
        "Banjarmasin Tengah": ["Mekar", "Kertak Baru Ilir", "Antasan Besar"]
      }
    },
    "Kalimantan Timur": {
      "Samarinda": {
        "Samarinda Kota": ["Bugis", "Karang Mumus", "Pelabuhan"]
      }
    },
    "Kalimantan Utara": {
      "Tanjung Selor": {
        "Tanjung Selor Hilir": ["Tanjung Selor Hilir", "Tanjung Selor Hulu"]
      }
    },
    "Sulawesi Utara": {
      "Manado": {
        "Wenang": ["Wenang Utara", "Wenang Selatan", "Titiwungen"]
      }
    },
    "Gorontalo": {
      "Gorontalo": {
        "Kota Selatan": ["Lamino", "Limba B", "Biawao"]
      }
    },
    "Sulawesi Tengah": {
      "Palu": {
        "Palu Timur": ["Besusu Barat", "Besusu Tengah", "Besusu Timur"]
      }
    },
    "Sulawesi Barat": {
      "Mamuju": {
        "Mamuju": ["Mamuju", "Binanga", "Rimuku"]
      }
    },
    "Sulawesi Selatan": {
      "Makassar": {
        "Ujung Pandang": ["Baru", "Maloku", "Sawerigading", "Mangkura"]
      }
    },
    "Sulawesi Tenggara": {
      "Kendari": {
        "Kadia": ["Kadia", "Bende", "Pondambeka"]
      }
    },
    "Maluku": {
      "Ambon": {
        "Sirimau": ["Batu Merah", "Rijali", "Ahusen"]
      }
    },
    "Maluku Utara": {
      "Ternate": {
        "Ternate Tengah": ["Gamalama", "Mekar", "Salahuddin"]
      }
    },
    "Papua Barat": {
      "Manokwari": {
        "Manokwari Barat": ["Sanggeng", "Wosi", "Amban"]
      }
    },
    "Papua": {
      "Jayapura": {
        "Jayapura Utara": ["Gurabesi", "Imbi", "Bhayangkara"]
      }
    },
    "Papua Tengah": {
      "Nabire": {
        "Nabire": ["Nabire Kota", "Girimulyo", "Karang Mulia"]
      }
    },
    "Papua Pegunungan": {
      "Wamena": {
        "Wamena": ["Wamena Kota", "Sinakma", "Wosilimo"]
      }
    },
    "Papua Selatan": {
      "Merauke": {
        "Merauke": ["Merauke Kota", "Kelapa Lima", "Maro"]
      }
    },
    "Papua Barat Daya": {
      "Sorong": {
        "Sorong Kota": ["Sorong Barat", "Sorong Timur", "Sorong Kepulauan"]
      }
    }
  };

  static const Map<String, List<String>> _indonesianKabupatens = {
    "Aceh": [
      "Kab. Aceh Barat", "Kab. Aceh Barat Daya", "Kab. Aceh Besar", "Kab. Aceh Jaya", "Kab. Aceh Selatan", 
      "Kab. Aceh Singkil", "Kab. Aceh Tamiang", "Kab. Aceh Tengah", "Kab. Aceh Tenggara", "Kab. Aceh Timur", 
      "Kab. Aceh Utara", "Kab. Bener Meriah", "Kab. Bireuen", "Kab. Gayo Lues", "Kab. Nagan Raya", 
      "Kab. Pidie", "Kab. Pidie Jaya", "Kab. Simeulue", "Kota Banda Aceh", "Kota Langsa", 
      "Kota Lhokseumawe", "Kota Sabang", "Kota Subulussalam"
    ],
    "Sumatera Utara": [
      "Kab. Asahan", "Kab. Batu Bara", "Kab. Dairi", "Kab. Deli Serdang", "Kab. Humbang Hasundutan", 
      "Kab. Karo", "Kab. Labuhanbatu", "Kab. Labuhanbatu Selatan", "Kab. Labuhanbatu Utara", "Kab. Langkat", 
      "Kab. Mandailing Natal", "Kab. Nias", "Kab. Nias Barat", "Kab. Nias Selatan", "Kab. Nias Utara", 
      "Kab. Padang Lawas", "Kab. Padang Lawas Utara", "Kab. Pakpak Bharat", "Kab. Samosir", "Kab. Serdang Bedagai", 
      "Kab. Simalungun", "Kab. Toba Samosir", "Kab. Tapanuli Selatan", "Kab. Tapanuli Tengah", "Kab. Tapanuli Utara", 
      "Kota Binjai", "Kota Gunungsitoli", "Kota Medan", "Kota Padangsidimpuan", "Kota Pematangsiantar", 
      "Kota Sibolga", "Kota Tanjungbalai", "Kota Tebing Tinggi"
    ],
    "Sumatera Barat": [
      "Kab. Agam", "Kab. Dharmasraya", "Kab. Kepulauan Mentawai", "Kab. Lima Puluh Kota", "Kab. Padang Pariaman", 
      "Kab. Pasaman", "Kab. Pasaman Barat", "Kab. Pesisir Selatan", "Kab. Sijunjung", "Kab. Solok", 
      "Kab. Solok Selatan", "Kab. Tanah Datar", "Kota Bukittinggi", "Kota Padang", "Kota Padangpanjang", 
      "Kota Pariaman", "Kota Payakumbuh", "Kota Sawahlunto", "Kota Solok"
    ],
    "Riau": [
      "Kab. Bengkalis", "Kab. Indragiri Hilir", "Kab. Indragiri Hulu", "Kab. Kampar", "Kab. Kepulauan Meranti", 
      "Kab. Kuantan Singingi", "Kab. Pelalawan", "Kab. Rokan Hilir", "Kab. Rokan Hulu", "Kab. Siak", 
      "Kota Dumai", "Kota Pekanbaru"
    ],
    "Kepulauan Riau": [
      "Kab. Bintan", "Kab. Karimun", "Kab. Kepulauan Anambas", "Kab. Lingga", "Kab. Natuna", 
      "Kota Batam", "Kota Tanjungpinang"
    ],
    "Jambi": [
      "Kab. Batanghari", "Kab. Bungo", "Kab. Kerinci", "Kab. Merangin", "Kab. Muaro Jambi", 
      "Kab. Sarolangun", "Kab. Tanjung Jabung Barat", "Kab. Tanjung Jabung Timur", "Kab. Tebo", "Kota Jambi", 
      "Kota Sungai Penuh"
    ],
    "Sumatera Selatan": [
      "Kab. Banyuasin", "Kab. Empat Lawang", "Kab. Lahat", "Kab. Muara Enim", "Kab. Musi Banyuasin", 
      "Kab. Musi Rawas", "Kab. Musi Rawas Utara", "Kab. Ogan Ilir", "Kab. Ogan Komering Ilir", "Kab. Ogan Komering Ulu", 
      "Kab. Ogan Komering Ulu Selatan", "Kab. Ogan Komering Ulu Timur", "Kab. Penukal Abab Lematang Ilir", "Kota Lubuklinggau", "Kota Pagar Alam", 
      "Kota Palembang", "Kota Prabumulih"
    ],
    "Kepulauan Bangka Belitung": [
      "Kab. Bangka", "Kab. Bangka Barat", "Kab. Bangka Selatan", "Kab. Bangka Tengah", "Kab. Belitung", 
      "Kab. Belitung Timur", "Kota Pangkalpinang"
    ],
    "Bengkulu": [
      "Kab. Bengkulu Selatan", "Kab. Bengkulu Tengah", "Kab. Bengkulu Utara", "Kab. Kaur", "Kab. Kepahiang", 
      "Kab. Lebong", "Kab. Mukomuko", "Kab. Rejang Lebong", "Kab. Seluma", "Kota Bengkulu"
    ],
    "Lampung": [
      "Kab. Lampung Barat", "Kab. Lampung Selatan", "Kab. Lampung Tengah", "Kab. Lampung Timur", "Kab. Lampung Utara", 
      "Kab. Mesuji", "Kab. Pesawaran", "Kab. Pesisir Barat", "Kab. Pringsewu", "Kab. Tanggamus", 
      "Kab. Tulang Bawang", "Kab. Tulang Bawang Barat", "Kab. Way Kanan", "Kota Bandar Lampung", "Kota Metro"
    ],
    "DKI Jakarta": [
      "Kab. Adm. Kepulauan Seribu", "Kota Adm. Jakarta Barat", "Kota Adm. Jakarta Pusat", "Kota Adm. Jakarta Selatan", "Kota Adm. Jakarta Timur", 
      "Kota Adm. Jakarta Utara"
    ],
    "Jawa Barat": [
      "Kab. Bandung", "Kab. Bandung Barat", "Kab. Bekasi", "Kab. Bogor", "Kab. Ciamis", 
      "Kab. Cianjur", "Kab. Cirebon", "Kab. Garut", "Kab. Indramayu", "Kab. Karawang", 
      "Kab. Kuningan", "Kab. Majalengka", "Kab. Pangandaran", "Kab. Purwakarta", "Kab. Subang", 
      "Kab. Sukabumi", "Kab. Sumedang", "Kab. Tasikmalaya", "Kota Bandung", "Kota Banjar", 
      "Kota Bekasi", "Kota Bogor", "Kota Cimahi", "Kota Cirebon", "Kota Depok", 
      "Kota Sukabumi", "Kota Tasikmalaya"
    ],
    "Banten": [
      "Kab. Lebak", "Kab. Pandeglang", "Kab. Serang", "Kab. Tangerang", "Kota Cilegon", 
      "Kota Serang", "Kota Tangerang", "Kota Tangerang Selatan"
    ],
    "Jawa Tengah": [
      "Kab. Banjarnegara", "Kab. Banyumas", "Kab. Batang", "Kab. Blora", "Kab. Boyolali", 
      "Kab. Brebes", "Kab. Cilacap", "Kab. Demak", "Kab. Grobogan", "Kab. Jepara", 
      "Kab. Karanganyar", "Kab. Kebumen", "Kab. Kendal", "Kab. Klaten", "Kab. Kudus", 
      "Kab. Magelang", "Kab. Pati", "Kab. Pekalongan", "Kab. Pemalang", "Kab. Purbalingga", 
      "Kab. Purworejo", "Kab. Rembang", "Kab. Semarang", "Kab. Sragen", "Kab. Sukoharjo", 
      "Kab. Tegal", "Kab. Temanggung", "Kab. Wonogiri", "Kab. Wonosobo", "Kota Magelang", 
      "Kota Pekalongan", "Kota Salatiga", "Kota Semarang", "Kota Surakarta (Solo)", "Kota Tegal"
    ],
    "DI Yogyakarta": [
      "Kab. Bantul", "Kab. Gunungkidul", "Kab. Kulon Progo", "Kab. Sleman", "Kota Yogyakarta"
    ],
    "Jawa Timur": [
      "Bangkalan", "Sampang", "Pamekasan", "Sumenep",
      "Kab. Banyuwangi", "Kab. Blitar", "Kab. Bojonegoro", "Kab. Bondowoso", "Kab. Gresik", 
      "Kab. Jember", "Kab. Jombang", "Kab. Kediri", "Kab. Lamongan", "Kab. Lumajang", 
      "Kab. Madiun", "Kab. Magetan", "Kab. Malang", "Kab. Nganjuk", "Kab. Ngawi", 
      "Kab. Pacitan", "Kab. Pasuruan", "Kab. Ponorogo", "Kab. Probolinggo", "Kab. Sidoarjo", 
      "Kab. Situbondo", "Kab. Trenggalek", "Kab. Tuban", "Kab. Tulungagung", "Kota Batu", 
      "Kota Blitar", "Kota Kediri", "Kota Madiun", "Kota Malang", "Kota Mojokerto", 
      "Kota Pasuruan", "Kota Probolinggo", "Kota Surabaya"
    ],
    "Bali": [
      "Kab. Badung", "Kab. Bangli", "Kab. Buleleng", "Kab. Gianyar", "Kab. Jembrana", 
      "Kab. Karangasem", "Kab. Klungkung", "Kab. Tabanan", "Kota Denpasar"
    ],
    "Nusa Tenggara Barat": [
      "Kab. Bima", "Kab. Dompu", "Kab. Lombok Barat", "Kab. Lombok Tengah", "Kab. Lombok Timur", 
      "Kab. Lombok Utara", "Kab. Sumbawa", "Kab. Sumbawa Barat", "Kota Bima", "Kota Mataram"
    ],
    "Nusa Tenggara Timur": [
      "Kab. Alor", "Kab. Belu", "Kab. Ende", "Kab. Flores Timur", "Kab. Kupang", 
      "Kab. Lembata", "Kab. Malaka", "Kab. Manggarai", "Kab. Manggarai Barat", "Kab. Manggarai Timur", 
      "Kab. Nagekeo", "Kab. Ngada", "Kab. Rote Ndao", "Kab. Sabu Raijua", "Kab. Sikka", 
      "Kab. Sumba Barat", "Kab. Sumba Barat Daya", "Kab. Sumba Tengah", "Kab. Sumba Timur", "Kab. Timor Tengah Selatan", 
      "Kab. Timor Tengah Utara", "Kota Kupang"
    ],
    "Kalimantan Barat": [
      "Kab. Bengkayang", "Kab. Kapuas Hulu", "Kab. Kayong Utara", "Kab. Ketapang", "Kab. Kubu Raya", 
      "Kab. Landak", "Kab. Melawi", "Kab. Pontianak", "Kab. Sambas", "Kab. Sanggau", 
      "Kab. Sekadau", "Kab. Sintang", "Kota Pontianak", "Kota Singkawang"
    ],
    "Kalimantan Tengah": [
      "Kab. Barito Selatan", "Kab. Barito Timur", "Kab. Barito Utara", "Kab. Gunung Mas", "Kab. Kapuas", 
      "Kab. Katingan", "Kab. Kotawaringin Barat", "Kab. Kotawaringin Timur", "Kab. Lamandau", "Kab. Murung Raya", 
      "Kab. Pulang Pisau", "Kab. Sukamara", "Kab. Seruyan", "Kota Palangkaraya"
    ],
    "Kalimantan Selatan": [
      "Kab. Balangan", "Kab. Banjar", "Kab. Barito Kuala", "Kab. Hulu Sungai Selatan", "Kab. Hulu Sungai Tengah", 
      "Kab. Hulu Sungai Utara", "Kab. Kotabaru", "Kab. Tabalong", "Kab. Tanah Bumbu", "Kab. Tanah Laut", 
      "Kab. Tapin", "Kota Banjarbaru", "Kota Banjarmasin"
    ],
    "Kalimantan Timur": [
      "Kab. Berau", "Kab. Kutai Barat", "Kab. Kutai Kartanegara", "Kab. Kutai Timur", "Kab. Mahakam Ulu", 
      "Kab. Paser", "Kab. Penajam Paser Utara", "Kota Balikpapan", "Kota Bontang", "Kota Samarinda"
    ],
    "Kalimantan Utara": [
      "Kab. Bulungan", "Kab. Malinau", "Kab. Nunukan", "Kab. Tana Tidung", "Kota Tarakan"
    ],
    "Sulawesi Utara": [
      "Kab. Bolaang Mongondow", "Kab. Bolaang Mongondow Selatan", "Kab. Bolaang Mongondow Timur", "Kab. Bolaang Mongondow Utara", "Kab. Kepulauan Sangihe", 
      "Kab. Kepulauan Siau Tagulandang Biaro", "Kab. Kepulauan Talaud", "Kab. Minahasa", "Kab. Minahasa Selatan", "Kab. Minahasa Tenggara", 
      "Kab. Minahasa Utara", "Kota Bitung", "Kota Kotamobagu", "Kota Manado", "Kota Tomohon"
    ],
    "Gorontalo": [
      "Kab. Boalemo", "Kab. Bone Bolango", "Kab. Gorontalo", "Kab. Gorontalo Utara", "Kab. Pohuwato", 
      "Kota Gorontalo"
    ],
    "Sulawesi Tengah": [
      "Kab. Banggai", "Kab. Banggai Kepulauan", "Kab. Banggai Laut", "Kab. Buol", "Kab. Donggala", 
      "Kab. Morowali", "Kab. Morowali Utara", "Kab. Parigi Moutong", "Kab. Poso", "Kab. Sigi", 
      "Kab. Tojo Una-Una", "Kab. Toli-Toli", "Kota Palu"
    ],
    "Sulawesi Barat": [
      "Kab. Majene", "Kab. Mamasa", "Kab. Mamuju", "Kab. Mamuju Tengah", "Kab. Pasangkayu", 
      "Kab. Polewali Mandar"
    ],
    "Sulawesi Selatan": [
      "Kab. Bantaeng", "Kab. Barru", "Kab. Bone", "Kab. Bulukumba", "Kab. Enrekang", 
      "Kab. Gowa", "Kab. Jeneponto", "Kab. Kepulauan Selayar", "Kab. Luwu", "Kab. Luwu Timur", 
      "Kab. Luwu Utara", "Kab. Maros", "Kab. Pangkajene dan Kepulauan", "Kab. Pinrang", "Kab. Sidenreng Rappang", 
      "Kab. Sinjai", "Kab. Soppeng", "Kab. Takalar", "Kab. Tana Toraja", "Kab. Toraja Utara", 
      "Kab. Wajo", "Kota Makassar", "Kota Palopo", "Kota Parepare"
    ],
    "Sulawesi Tenggara": [
      "Kab. Bombana", "Kab. Buton", "Kab. Buton Selatan", "Kab. Buton Tengah", "Kab. Buton Utara", 
      "Kab. Kolaka", "Kab. Kolaka Timur", "Kab. Kolaka Utara", "Kab. Konawe", "Kab. Konawe Kepulauan", 
      "Kab. Konawe Selatan", "Kab. Konawe Utara", "Kab. Muna", "Kab. Muna Barat", "Kab. Wakatobi", 
      "Kota Bau-Bau", "Kota Kendari"
    ],
    "Maluku": [
      "Kab. Buru", "Kab. Buru Selatan", "Kab. Kepulauan Aru", "Kab. Maluku Barat Daya", "Kab. Maluku Tengah", 
      "Kab. Maluku Tenggara", "Kab. Kepulauan Tanimbar", "Kab. Seram Bagian Barat", "Kab. Seram Bagian Timur", "Kota Ambon", 
      "Kota Tual"
    ],
    "Maluku Utara": [
      "Kab. Halmahera Barat", "Kab. Halmahera Tengah", "Kab. Halmahera Timur", "Kab. Halmahera Selatan", "Kab. Halmahera Utara", 
      "Kab. Kepulauan Sula", "Kab. Pulau Morotai", "Kab. Pulau Taliabu", "Kota Ternate", "Kota Tidore Kepulauan"
    ],
    "Papua": [
      "Kab. Biak Numfor", "Kab. Jayapura", "Kab. Keerom", "Kab. Kepulauan Yapen", "Kab. Mamberamo Raya", 
      "Kab. Sarmi", "Kab. Supiori", "Kab. Waropen", "Kota Jayapura"
    ],
    "Papua Barat": [
      "Kab. Fakfak", "Kab. Kaimana", "Kab. Manokwari", "Kab. Manokwari Selatan", "Kab. Pegunungan Arfak", 
      "Kab. Teluk Bintuni", "Kab. Teluk Wondama"
    ],
    "Papua Selatan": [
      "Kab. Asmat", "Kab. Mappi", "Kab. Merauke", "Kab. Boven Digoel"
    ],
    "Papua Tengah": [
      "Kab. Deiyai", "Kab. Dogiyai", "Kab. Intan Jaya", "Kab. Mimika", "Kab. Nabire", 
      "Kab. Paniai", "Kab. Puncak", "Kab. Puncak Jaya"
    ],
    "Papua Pegunungan": [
      "Kab. Jayawijaya", "Kab. Lanny Jaya", "Kab. Mamberamo Tengah", "Kab. Nduga", "Kab. Pegunungan Bintang", 
      "Kab. Tolikara", "Kab. Yahukimo", "Kab. Yalimo"
    ],
    "Papua Barat Daya": [
      "Kab. Maybrat", "Kab. Raja Ampat", "Kab. Sorong", "Kab. Sorong Selatan", "Kab. Tambrauw", 
      "Kota Sorong"
    ]
  };

  Map<String, Map<String, List<String>>>? _getKabupatenMap() {
    final prov = _provinsiController.text.trim();
    for (var key in _indonesianRegions.keys) {
      if (key.toLowerCase() == prov.toLowerCase()) {
        return _indonesianRegions[key];
      }
    }
    return null;
  }

  List<String> _getKabupatenList() {
    final prov = _provinsiController.text.trim().toLowerCase();
    
    String? matchedProvKey;
    for (var key in _indonesianRegions.keys) {
      if (key.toLowerCase() == prov) {
        matchedProvKey = key;
        break;
      }
    }
    
    final Set<String> kabList = {};
    if (matchedProvKey != null) {
      kabList.addAll(_indonesianRegions[matchedProvKey]!.keys);
    }
    
    String? matchedProvDbKey;
    for (var key in _indonesianKabupatens.keys) {
      if (key.toLowerCase() == prov) {
        matchedProvDbKey = key;
        break;
      }
    }
    if (matchedProvDbKey != null) {
      kabList.addAll(_indonesianKabupatens[matchedProvDbKey]!);
    }
    
    final sortedList = kabList.toList()..sort();
    return sortedList;
  }

  Map<String, List<String>>? _getKecamatanMap() {
    final kabMap = _getKabupatenMap();
    if (kabMap == null) return null;
    final kab = _kabupatenController.text.trim();
    for (var key in kabMap.keys) {
      if (key.toLowerCase() == kab.toLowerCase()) {
        return kabMap[key];
      }
    }
    return null;
  }

  List<String>? _getDesaList() {
    final kecMap = _getKecamatanMap();
    if (kecMap == null) return null;
    final kec = _kecamatanController.text.trim();
    for (var key in kecMap.keys) {
      if (key.toLowerCase() == kec.toLowerCase()) {
        return kecMap[key];
      }
    }
    return null;
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _cleanRegionName(String name, String type) {
    name = name.toUpperCase();
    if (type == 'kabupaten') {
      name = name.replaceAll('KABUPATEN ', '').replaceAll('KOTA ', '');
    }
    return _toTitleCase(name);
  }

  Future<List<dynamic>?> _fetchJsonList(String url) async {
    // 1. On Web, browser CORS block is active, so try CORS proxies first. On non-Web, try direct first.
    if (kIsWeb) {
      // Try corsproxy.io
      try {
        final proxyUrl = 'https://corsproxy.io/?' + Uri.encodeComponent(url);
        final response = await http.get(Uri.parse(proxyUrl)).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          return json.decode(response.body) as List;
        }
      } catch (e) {
        debugPrint("CORS proxy (corsproxy.io) failed: $e");
      }

      // Try allorigins.win
      try {
        final proxyUrl = 'https://api.allorigins.win/raw?url=' + Uri.encodeComponent(url);
        final response = await http.get(Uri.parse(proxyUrl)).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          return json.decode(response.body) as List;
        }
      } catch (e) {
        debugPrint("CORS proxy (allorigins.win) failed: $e");
      }
      
      // Direct as ultimate fallback
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          return json.decode(response.body) as List;
        }
      } catch (_) {}
    } else {
      // Non-Web: Try direct first (no CORS limitations on mobile/desktop/windows)
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          return json.decode(response.body) as List;
        }
      } catch (e) {
        debugPrint("Direct fetch failed for $url: $e");
      }

      // Proxy as fallback
      try {
        final proxyUrl = 'https://corsproxy.io/?' + Uri.encodeComponent(url);
        final response = await http.get(Uri.parse(proxyUrl)).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          return json.decode(response.body) as List;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<List<Map<String, String>>> _fetchProvinces() async {
    final data = await _fetchJsonList('https://emsifa.github.io/api-wilayah-indonesia/api/provinces.json');
    if (data != null) {
      return data.map<Map<String, String>>((item) => {
        'id': item['id'].toString(),
        'name': _toTitleCase(item['name'].toString())
      }).toList();
    }
    return [];
  }

  Future<List<Map<String, String>>> _fetchKabupatens(String provinceId) async {
    final data = await _fetchJsonList('https://emsifa.github.io/api-wilayah-indonesia/api/regencies/$provinceId.json');
    if (data != null) {
      return data.map<Map<String, String>>((item) => {
        'id': item['id'].toString(),
        'name': _cleanRegionName(item['name'].toString(), 'kabupaten')
      }).toList();
    }
    return [];
  }

  Future<List<Map<String, String>>> _fetchKecamatans(String regencyId) async {
    final data = await _fetchJsonList('https://emsifa.github.io/api-wilayah-indonesia/api/districts/$regencyId.json');
    if (data != null) {
      return data.map<Map<String, String>>((item) => {
        'id': item['id'].toString(),
        'name': _toTitleCase(item['name'].toString())
      }).toList();
    }
    return [];
  }

  Future<List<Map<String, String>>> _fetchDesas(String districtId) async {
    final data = await _fetchJsonList('https://emsifa.github.io/api-wilayah-indonesia/api/villages/$districtId.json');
    if (data != null) {
      return data.map<Map<String, String>>((item) => {
        'id': item['id'].toString(),
        'name': _toTitleCase(item['name'].toString())
      }).toList();
    }
    return [];
  }

  Future<String?> _resolveProvinceId() async {
    if (_selectedProvinsiId != null) return _selectedProvinsiId;
    final provName = _provinsiController.text.trim().toLowerCase();
    if (provName.isEmpty) return null;
    
    final provinces = await _fetchProvinces();
    for (var p in provinces) {
      if (p['name']!.toLowerCase() == provName) {
        _selectedProvinsiId = p['id'];
        return _selectedProvinsiId;
      }
    }
    return null;
  }

  Future<String?> _resolveKabupatenId(String provinceId) async {
    if (_selectedKabupatenId != null) return _selectedKabupatenId;
    final kabName = _kabupatenController.text.trim().toLowerCase();
    if (kabName.isEmpty) return null;

    final kabupatens = await _fetchKabupatens(provinceId);
    for (var k in kabupatens) {
      if (k['name']!.toLowerCase() == kabName) {
        _selectedKabupatenId = k['id'];
        return _selectedKabupatenId;
      }
    }
    return null;
  }

  Future<String?> _resolveKecamatanId(String regencyId) async {
    if (_selectedKecamatanId != null) return _selectedKecamatanId;
    final kecName = _kecamatanController.text.trim().toLowerCase();
    if (kecName.isEmpty) return null;

    final kecamatans = await _fetchKecamatans(regencyId);
    for (var kc in kecamatans) {
      if (kc['name']!.toLowerCase() == kecName) {
        _selectedKecamatanId = kc['id'];
        return _selectedKecamatanId;
      }
    }
    return null;
  }

  void _showDynamicRegionPicker({
    required String title,
    required Future<List<Map<String, String>>> Function() fetchItems,
    required List<String> offlineFallbackItems,
    required void Function(String name, String? id) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        List<Map<String, String>> loadedItems = [];
        List<String> displayedItems = [];
        bool isLoading = true;
        String searchQuery = "";

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            if (isLoading) {
              fetchItems().then((result) {
                if (context.mounted) {
                  setModalState(() {
                    loadedItems = result;
                    isLoading = false;
                    if (loadedItems.isEmpty) {
                      displayedItems = offlineFallbackItems;
                    } else {
                      displayedItems = loadedItems.map((e) => e['name']!).toList();
                    }
                  });
                }
              }).catchError((_) {
                if (context.mounted) {
                  setModalState(() {
                    isLoading = false;
                    displayedItems = offlineFallbackItems;
                  });
                }
              });
            }

            final filteredItems = displayedItems.where((item) {
              return item.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                        if (isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (val) {
                        setModalState(() {
                          searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Cari...",
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filteredItems.isEmpty
                          ? Center(
                              child: Text(
                                isLoading ? "Memuat data wilayah..." : "Tidak ada data ditemukan",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final itemName = filteredItems[index];
                                return ListTile(
                                  title: Text(itemName),
                                  trailing: const Icon(Icons.chevron_right, size: 18),
                                  onTap: () {
                                    final match = loadedItems.firstWhere(
                                      (element) => element['name'] == itemName,
                                      orElse: () => {},
                                    );
                                    onSelected(itemName, match['id']);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? _validateNama(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.length < 3) {
      return 'Nama minimal 3 karakter';
    }
    return null;
  }

  String? _validateNisn(String? value) {
    if (value == null || value.isEmpty) {
      return 'NISN tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'NISN minimal 6 digit';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'NISN harus angka';
    }
    return null;
  }

  void _handleSimpan() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // Create new/updated siswa object from form data
      final newSiswa = Siswa(
        nisn: _nisnController.text,
        nama: _namaController.text,
        kelas: _selectedKelas,
        ttl: _ttlController.text.isEmpty ? "-" : _ttlController.text,
        alamat: _alamatController.text.isEmpty ? "-" : _alamatController.text,
        namaOrtu: _namaOrtuController.text.isEmpty ? "-" : _namaOrtuController.text,
        namaIbu: _namaIbuController.text.isEmpty ? "-" : _namaIbuController.text,
        desa: _desaController.text.isEmpty ? "-" : _desaController.text,
        kecamatan: _kecamatanController.text.isEmpty ? "-" : _kecamatanController.text,
        kabupaten: _kabupatenController.text.isEmpty ? "-" : _kabupatenController.text,
        provinsi: _provinsiController.text.isEmpty ? "-" : _provinsiController.text,
        rt: _rtController.text.isEmpty ? "-" : _rtController.text,
        rw: _rwController.text.isEmpty ? "-" : _rwController.text,
      );
      
      // Save/Update to StudentService
      if (widget.siswaToEdit != null) {
        StudentService().updateSiswa(newSiswa);
      } else {
        StudentService().addSiswa(newSiswa);
      }
      
      // Simulate save delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.siswaToEdit != null 
                ? "Siswa ${_namaController.text} berhasil diperbarui!"
                : "Siswa ${_namaController.text} berhasil ditambahkan!"),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success/changes
        }
      });
    }
  }

  @override
  void dispose() {
    _provinsiController.removeListener(_onProvinsiChanged);
    _namaController.dispose();
    _nisnController.dispose();
    _ttlController.dispose();
    _alamatController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _namaOrtuController.dispose();
    _desaController.dispose();
    _kecamatanController.dispose();
    _kabupatenController.dispose();
    _provinsiController.dispose();
    _namaIbuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.siswaToEdit != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        title: Text(isEditing ? "Edit Siswa" : "Tambah Siswa"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEditing ? "Formulir Edit Siswa" : "Formulir Pendaftaran Siswa", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(isEditing ? "Perbarui data diri siswa" : "Lengkapi data diri siswa baru", style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _namaController,
                      validator: _validateNama,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Nama Lengkap",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nisnController,
                      validator: _validateNisn,
                      keyboardType: TextInputType.number,
                      enabled: !isEditing, // Disable NISN editing since it is the identifier
                      decoration: InputDecoration(
                        labelText: "NISN",
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedKelas,
                      decoration: InputDecoration(
                        labelText: "Kelas",
                        prefixIcon: const Icon(Icons.class_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _kelasOptions.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                      onChanged: (val) => setState(() => _selectedKelas = val!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ttlController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Tanggal Lahir",
                        hintText: "Contoh: Bandung, 15 Januari 2008",
                        prefixIcon: const Icon(Icons.cake_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _alamatController,
                      textCapitalization: TextCapitalization.words,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Alamat Orang Tua/Wali",
                        hintText: "Contoh: Jl. Merdeka No. 10",
                        prefixIcon: const Icon(Icons.home_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _rtController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "RT",
                              hintText: "Contoh: 01",
                              prefixIcon: const Icon(Icons.tag),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _rwController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "RW",
                              hintText: "Contoh: 03",
                              prefixIcon: const Icon(Icons.tag),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _namaOrtuController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Nama Orang Tua/Wali",
                        hintText: "Contoh: Ahmad",
                        prefixIcon: const Icon(Icons.person_pin_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _namaIbuController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Nama Ibu Kandung",
                        hintText: "Contoh: Siti Aminah",
                        prefixIcon: const Icon(Icons.woman_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _provinsiController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Provinsi",
                        hintText: "Contoh: Jawa Timur",
                        prefixIcon: const Icon(Icons.flag_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_drop_down),
                          onPressed: () {
                            _showDynamicRegionPicker(
                              title: "Pilih Provinsi",
                              fetchItems: _fetchProvinces,
                              offlineFallbackItems: _indonesianRegions.keys.toList(),
                              onSelected: (val, id) {
                                setState(() {
                                  _provinsiController.text = val;
                                  _selectedProvinsiId = id;
                                  _kabupatenController.clear();
                                  _selectedKabupatenId = null;
                                  _kecamatanController.clear();
                                  _selectedKecamatanId = null;
                                  _desaController.clear();
                                });
                              },
                            );
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _kabupatenController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Kabupaten",
                        hintText: "Contoh: Sampang",
                        prefixIcon: const Icon(Icons.business_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_drop_down),
                          onPressed: () {
                            _showDynamicRegionPicker(
                              title: "Pilih Kabupaten",
                              fetchItems: () async {
                                final pId = await _resolveProvinceId();
                                if (pId == null) return [];
                                return _fetchKabupatens(pId);
                              },
                              offlineFallbackItems: _getKabupatenList(),
                              onSelected: (val, id) {
                                setState(() {
                                  _kabupatenController.text = val;
                                  _selectedKabupatenId = id;
                                  _kecamatanController.clear();
                                  _selectedKecamatanId = null;
                                  _desaController.clear();
                                });
                              },
                            );
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _kecamatanController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Kecamatan",
                        hintText: "Contoh: Ketapang",
                        prefixIcon: const Icon(Icons.map_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_drop_down),
                          onPressed: () {
                            _showDynamicRegionPicker(
                              title: "Pilih Kecamatan",
                              fetchItems: () async {
                                final pId = await _resolveProvinceId();
                                if (pId == null) return [];
                                final kId = await _resolveKabupatenId(pId);
                                if (kId == null) return [];
                                return _fetchKecamatans(kId);
                              },
                              offlineFallbackItems: _getKecamatanMap()?.keys.toList() ?? <String>[],
                              onSelected: (val, id) {
                                setState(() {
                                  _kecamatanController.text = val;
                                  _selectedKecamatanId = id;
                                  _desaController.clear();
                                });
                              },
                            );
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _desaController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Desa",
                        hintText: "Contoh: Pancor",
                        prefixIcon: const Icon(Icons.location_city_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_drop_down),
                          onPressed: () {
                            _showDynamicRegionPicker(
                              title: "Pilih Desa",
                              fetchItems: () async {
                                final pId = await _resolveProvinceId();
                                if (pId == null) return [];
                                final kId = await _resolveKabupatenId(pId);
                                if (kId == null) return [];
                                final kcId = await _resolveKecamatanId(kId);
                                if (kcId == null) return [];
                                return _fetchDesas(kcId);
                              },
                              offlineFallbackItems: _getDesaList() ?? <String>[],
                              onSelected: (val, id) {
                                setState(() {
                                  _desaController.text = val;
                                });
                              },
                            );
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSimpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(isEditing ? "SIMPAN PERUBAHAN" : "SIMPAN DATA", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
