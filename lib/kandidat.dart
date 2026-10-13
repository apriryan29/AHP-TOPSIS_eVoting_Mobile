import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'home.dart';
import 'hasil.dart';
import 'profil.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BASE URL — ganti sesuai server Anda
// ─────────────────────────────────────────────────────────────────────────────
const String _baseUrl = 'https://votingmu.my.id';

/// ─────────────────────────────────────────────
/// MODEL
/// ─────────────────────────────────────────────
class Kandidat {
  final int id;
  final String nama;
  final String nia;
  final String foto;
  final String visi;
  final List<String> misi;
  final String asalKomisariat;
  final String tahunDad;

  Kandidat({
    required this.id,
    required this.nama,
    required this.nia,
    required this.foto,
    required this.visi,
    required this.misi,
    required this.asalKomisariat,
    required this.tahunDad,
  });

  /// URL lengkap foto untuk dipakai di Image.network
  String get fotoUrl => '$_baseUrl/storage/$foto';

  factory Kandidat.fromJson(Map<String, dynamic> json) {
    return Kandidat(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      nia: json['nia'] ?? '',
      foto: json['foto'] ?? '',
      visi: json['visi'] ?? '',
      misi: _parseMisi(json['misi']),
      asalKomisariat: json['asal_komisariat'] ?? '',
      tahunDad: json['tahun_dad'] ?? '',
    );
  }

  /// Parse misi dari berbagai format: List JSON, HTML <li>, atau plain CSV
  static List<String> _parseMisi(dynamic raw) {
    if (raw == null) return [];

    // Sudah berupa List dari JSON
    if (raw is List) return List<String>.from(raw);

    final str = raw.toString();

    // Format HTML — ekstrak semua konten di dalam <li>...</li>
    if (str.contains('<li')) {
      final regex = RegExp(r'<li[^>]*>(.*?)<\/li>', dotAll: true);
      return regex
          .allMatches(str)
          .map((m) => _stripHtml(m.group(1) ?? ''))
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // Fallback: plain text dipisah koma
    return str
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Hapus semua tag HTML dan decode entitas dasar
  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
}

/// ─────────────────────────────────────────────
/// PAGE
/// ─────────────────────────────────────────────
class KandidatPage extends StatefulWidget {
  const KandidatPage({super.key});

  @override
  State<KandidatPage> createState() => _KandidatPageState();
}

class _KandidatPageState extends State<KandidatPage> {
  List<Kandidat> daftarKandidat = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchKandidat();
  }

  Future<void> fetchKandidat() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/kandidats'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded is Map ? decoded['data'] : decoded;

        setState(() {
          daftarKandidat =
              (list as List).map((e) => Kandidat.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetchKandidat: $e');
      setState(() => isLoading = false);
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
          'Daftar\nCalon Formatur',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFEC900E)))
          : daftarKandidat.isEmpty
              ? const Center(child: Text('Data kandidat kosong'))
              : Column(
                  children: [
                    // Header total
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.people_alt_outlined,
                              color: Color(0xFFEC900E), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Total Calon Formatur: ${daftarKandidat.length}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        itemCount: daftarKandidat.length,
                        itemBuilder: (context, index) {
                          final k = daftarKandidat[index];
                          return _KandidatListItem(
                            kandidat: k,
                            onTap: () => _showDetailModal(context, k),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  void _showDetailModal(BuildContext context, Kandidat k) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => _KandidatDetailModal(kandidat: k),
    );
  }
}

/// ─────────────────────────────────────────────
/// LIST ITEM
/// ─────────────────────────────────────────────
class _KandidatListItem extends StatelessWidget {
  final Kandidat kandidat;
  final VoidCallback onTap;

  const _KandidatListItem({required this.kandidat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── FIX 1: pakai fotoUrl (full URL) ──────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                kandidat.fotoUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: const Color(0xFFE8E8E8),
                  child: const Icon(Icons.image_outlined,
                      color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                kandidat.nama,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFFCCCCCC), size: 20),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// DETAIL MODAL
/// ─────────────────────────────────────────────
class _KandidatDetailModal extends StatelessWidget {
  final Kandidat kandidat;

  const _KandidatDetailModal({required this.kandidat});

  static const primary = Color(0xFFEC900E);
  static const radius = Radius.circular(20);

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.80;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(radius),
        child: Container(
          color: Colors.white,
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── FOTO — punya scroll sendiri, terpisah dari konten ─────
              SizedBox(
                height: 220,
                width: double.infinity,
                child: ClipRect(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Image.network(
                      kandidat.fotoUrl,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 220,
                          color: const Color(0xFFE8EBF5),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFEC900E),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        height: 220,
                        color: const Color(0xFFE8EBF5),
                        child: const Icon(Icons.person,
                            size: 60, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),

              // ── KONTEN — bisa discroll ────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kandidat.nama,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${kandidat.asalKomisariat} • ${kandidat.tahunDad}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      const Text('Visi',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(kandidat.visi),
                      const SizedBox(height: 16),
                      const Text('Misi',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      ...kandidat.misi
                          .where((e) => e.isNotEmpty)
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      child: Text(
                                        '${entry.key + 1}.',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFEC900E),
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Text(entry.value)),
                                  ],
                                ),
                              )),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Tutup',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// BOTTOM NAV
/// ─────────────────────────────────────────────
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
      currentIndex: 0,
      selectedItemColor: const Color(0xFFEC900E),
      unselectedItemColor: const Color(0xFFBBBBBB),
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      onTap: (index) {
        if (index == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        }
        if (index == 1) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HasilPage()));
        }
        if (index == 2) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfilePage()));
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