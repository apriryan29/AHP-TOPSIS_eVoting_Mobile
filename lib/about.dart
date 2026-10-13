import 'package:flutter/material.dart';

class TentangAplikasiPage extends StatelessWidget {
  const TentangAplikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1A3A6B);
    const accent = Color(0xFFEC900E);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Tentang Aplikasi',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Logo
            Image.asset(
              'assets/logo.png',
              width: 100,
              height: 100,
            ),

            const SizedBox(height: 16),

            const Text(
              'Votura',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: primary,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Sistem Pemilihan Digital',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Votura merupakan aplikasi pemilihan berbasis digital yang dirancang untuk membantu proses pemilihan secara lebih cepat, transparan, efektif, dan efisien. Aplikasi ini memungkinkan pemilih untuk melihat profil calon formatur, visi dan misi kandidat, serta melakukan proses pemungutan suara secara mudah melalui perangkat mobile.',
                textAlign: TextAlign.justify,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 24),

            _sectionTitle('Fitur Utama'),

            const SizedBox(height: 12),

            _fitur(Icons.people_alt_outlined,
                'Daftar Kandidat'),
            _fitur(Icons.person_outline,
                'Profil Kandidat Lengkap'),
            _fitur(Icons.how_to_vote_outlined,
                'Pemungutan Suara Digital'),
            _fitur(Icons.verified_outlined,
                'Proses Pemilihan Transparan'),
            _fitur(Icons.bar_chart_outlined,
                'Rekapitulasi Hasil Pemilihan'),

            const SizedBox(height: 24),

            _sectionTitle('Informasi Aplikasi'),

            const SizedBox(height: 12),

            _infoItem('Versi', '1.0.1'),
            _infoItem('Platform', 'Flutter'),
            _infoItem('Tahun', '2026'),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Text(
                    'Pengembang',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Votura dikembangkan sebagai media pendukung transformasi digital dalam proses demokrasi Organisasi Otonom Muhammadiyah.',
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.6),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              '© Sistem Pemilihan Digital',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A3A6B),
        ),
      ),
    );
  }

  static Widget _fitur(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFEC900E)),
          SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  static Widget _infoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}