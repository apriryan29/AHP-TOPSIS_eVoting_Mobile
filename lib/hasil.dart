import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'home.dart';
import 'profil.dart';

const String _baseUrl = 'https://votingmu.my.id';

// Palet warna untuk tiap kandidat di chart (diulang jika kandidat lebih banyak
// dari jumlah warna yang tersedia).
const List<Color> _warnaChart = [
  Color(0xFFEC900E),
  Color(0xFF2F6FED),
  Color(0xFF3B6D11),
  Color(0xFFA32D2D),
  Color(0xFF8E44AD),
  Color(0xFF1ABC9C),
  Color(0xFFE67E22),
];

Color _warnaUntukIndex(int i) => _warnaChart[i % _warnaChart.length];

class HasilPage extends StatefulWidget {
  const HasilPage({super.key});

  @override
  State<HasilPage> createState() => _HasilPageState();
}

class _HasilPageState extends State<HasilPage> {
  int _selectedIndex = -1;

  List<Map<String, dynamic>> _hasil = [];
  bool    _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchHasil();
  }

  Future<void> _fetchHasil() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/hasil-suara'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded is Map ? decoded['data'] : decoded;

        // Urutkan berdasarkan id kandidat (ascending) sebelum diberi warna & index.
        // Urutan ini menentukan urutan section pada pie chart.
        final rawList = (list as List).cast<Map<String, dynamic>>();
        rawList.sort((a, b) {
          final idA = int.tryParse(a['id'].toString()) ?? 0;
          final idB = int.tryParse(b['id'].toString()) ?? 0;
          return idA.compareTo(idB);
        });

        final hasil = rawList.asMap().entries.map((entry) {
          final index = entry.key;
          final item  = entry.value;
          return {
            'nama' : item['nama']?.toString() ?? '-',
            'suara': int.tryParse(item['suara'].toString()) ?? 0,
            'warna': _warnaUntukIndex(index),
          };
        }).toList();

        setState(() {
          _hasil      = hasil;
          _isLoading  = false;
        });
      } else {
        setState(() {
          _errorMsg  = 'Gagal memuat data (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg  = 'Tidak dapat terhubung ke server.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Statistik Hasil\nPemilihan Formatur',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFEC900E)));
    }

    if (_errorMsg != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 52, color: Colors.black38),
            const SizedBox(height: 16),
            Text(_errorMsg!,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchHasil,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC900E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ),
      );
    }

    if (_hasil.isEmpty) {
      return const Center(
          child: Text('Belum ada data suara.',
              style: TextStyle(color: Colors.black54)));
    }

    final totalSuara = _hasil.fold<int>(
      0,
      (sum, item) => sum + (item['suara'] as int),
    );

    // Salinan _hasil yang diurutkan dari suara terbanyak, khusus untuk list
    // keterangan. _hasil sendiri tetap urut berdasarkan id (dipakai pie chart).
    final hasilTerurut = List<Map<String, dynamic>>.from(_hasil)
      ..sort((a, b) => (b['suara'] as int).compareTo(a['suara'] as int));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // PIE CHART (urut berdasarkan id)
            Center(
              child: SizedBox(
                height: 250,
                child: totalSuara == 0
                    ? const Center(
                        child: Text('Belum ada suara yang masuk.',
                            style: TextStyle(color: Colors.black54)),
                      )
                    : PieChart(
                        PieChartData(
                          centerSpaceRadius: 55,
                          sectionsSpace: 3,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    response == null ||
                                    response.touchedSection == null) {
                                  _selectedIndex = -1;
                                  return;
                                }

                                _selectedIndex = response
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          sections: List.generate(
                            _hasil.length,
                            (index) {
                              final item = _hasil[index];
                              final isTouched = index == _selectedIndex;

                              final suara = item['suara'] as int;

                              final persen = totalSuara == 0
                                  ? '0.0'
                                  : (suara / totalSuara * 100)
                                      .toStringAsFixed(1);

                              return PieChartSectionData(
                                color: item['warna'] as Color,
                                value: suara.toDouble(),
                                radius: isTouched ? 80 : 65,
                                title: '$persen%',
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // INFO KETIKA DIKLIK (mengacu ke _hasil, urutan id, sesuai touchedSectionIndex)
            if (_selectedIndex != -1 && _selectedIndex < _hasil.length)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC900E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _hasil[_selectedIndex]['nama'].toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Jumlah Suara: ${_hasil[_selectedIndex]['suara']}',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      totalSuara == 0
                          ? '0.0%'
                          : '${((_hasil[_selectedIndex]['suara'] as int) / totalSuara * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEC900E),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            const Text(
              'Keterangan:',
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),

            const Divider(),

            const SizedBox(height: 18),

            // LIST KETERANGAN (urut dari suara terbanyak)
            ...hasilTerurut.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final item = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: item['warna'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        '$index. ${item['nama']}',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),

                    Text(
                      '${item['suara']} Suara',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEC900E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Total Suara: $totalSuara',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEC900E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildBottomNav(BuildContext context) {
  return Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 20,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: BottomNavigationBar(
      currentIndex: 1,
      selectedItemColor: const Color(0xFFEC900E),
      unselectedItemColor: const Color(0xFFBBBBBB),
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
      ),
      onTap: (index) {
        if (index == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const HomePage(),
            ),
            (route) => false,
          );
        }

        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProfilePage(),
            ),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_rounded),
          activeIcon: Icon(Icons.bar_chart_rounded),
          label: 'Hasil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Profil',
        ),
      ],
    ),
  );
}