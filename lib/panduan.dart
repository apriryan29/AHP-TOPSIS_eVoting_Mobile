import 'package:flutter/material.dart';

class PanduanAplikasiPage extends StatelessWidget {
  const PanduanAplikasiPage({super.key});

  static const Color _primaryOrange = Color(0xFFEC900E);
  static const Color _lightOrange   = Color(0xFFFBF1E6);
  static const Color _textPrimary   = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderColor   = Color(0xFFE5E7EB);
  static const Color _bgPage        = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context) {
    final langkah = <_LangkahPanduan>[
      const _LangkahPanduan(
        icon: Icons.people_alt_outlined,
        judul: '1. Lihat Daftar Kandidat',
        deskripsi:
            'Sebelum memilih, Anda bisa melihat profil lengkap setiap calon '
            'formatur melalui menu "Daftar Kandidat" di halaman utama.',
      ),
      const _LangkahPanduan(
        icon: Icons.verified_user_outlined,
        judul: '2. Verifikasi Pemilihan',
        deskripsi:
            'Buka menu "Verifikasi Pemilihan" lalu masukkan alamat email yang '
            'terdaftar di sistem. Token pemilihan 6 digit akan dikirimkan ke '
            'email tersebut.',
      ),
      const _LangkahPanduan(
        icon: Icons.key_rounded,
        judul: '3. Masukkan Token',
        deskripsi:
            'Cek kotak masuk email Anda (termasuk folder Spam/Promosi jika '
            'tidak ditemukan), lalu masukkan token 6 digit tersebut pada '
            'halaman Verifikasi Token untuk melanjutkan ke halaman voting.',
      ),
      const _LangkahPanduan(
        icon: Icons.how_to_vote_outlined,
        judul: '4. Pilih Calon Formatur',
        deskripsi:
            'Pada halaman voting, pilih calon formatur sesuai jumlah maksimal '
            'yang ditentukan. Ketuk kartu calon untuk memilih atau '
            'membatalkan pilihan.',
      ),
      const _LangkahPanduan(
        icon: Icons.save_outlined,
        judul: '5. Konfirmasi & Simpan',
        deskripsi:
            'Setelah jumlah pilihan lengkap, tekan tombol "Simpan Pilihan". '
            'Periksa kembali daftar calon yang dipilih pada dialog '
            'konfirmasi, lalu tekan "Ya, Simpan". Pilihan tidak dapat '
            'diubah setelah disimpan.',
      ),
      const _LangkahPanduan(
        icon: Icons.bar_chart_rounded,
        judul: '6. Pantau Hasil',
        deskripsi:
            'Setelah periode pemilihan berakhir, hasil rekapitulasi suara '
            'dapat dilihat melalui menu "Statistik Hasil" di halaman utama.',
      ),
    ];

    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Panduan Aplikasi',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: _borderColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intro
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _lightOrange,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        color: _primaryOrange, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ikuti langkah-langkah berikut untuk berpartisipasi '
                        'dalam pemilihan formatur melalui Votura.',
                        style: TextStyle(
                          fontSize: 13,
                          color: _textPrimary.withOpacity(0.85),
                          height: 1.55,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Daftar langkah
              ...List.generate(langkah.length, (i) {
                final item = langkah[i];
                final isLast = i == langkah.length - 1;
                return _buildLangkahItem(item, isLast);
              }),

              const SizedBox(height: 8),

              // Catatan tambahan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _borderColor, width: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: _textSecondary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Setiap token hanya dapat digunakan satu kali dan '
                        'pilihan yang sudah disimpan tidak dapat diubah. '
                        'Pastikan Anda sudah yakin sebelum menekan tombol '
                        'simpan.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: _textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangkahItem(_LangkahPanduan item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _lightOrange,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: _primaryOrange, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: _borderColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24, top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.judul,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.deskripsi,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangkahPanduan {
  final IconData icon;
  final String judul;
  final String deskripsi;

  const _LangkahPanduan({
    required this.icon,
    required this.judul,
    required this.deskripsi,
  });
}