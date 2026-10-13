import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import 'profil.dart';
import 'kandidat.dart';
import 'about.dart';
import 'hasil.dart';
import 'verif.dart';
import 'vote.dart';
import 'panduan.dart';
import 'notifikasi.dart';
import 'notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String namaPemilihan = '';
  String deskripsi = '';
  String mulai = '';
  String selesai = '';
  int _unreadNotifCount = 0;

  String getStatusPemilihan() {
    if (mulai.isEmpty || selesai.isEmpty) return 'Memuat...';

    final jakarta = tz.getLocation('Asia/Jakarta');
    final now = tz.TZDateTime.now(jakarta);
    final mulaiDate = tz.TZDateTime.from(DateTime.parse(mulai), jakarta);
    final selesaiDate = tz.TZDateTime.from(DateTime.parse(selesai), jakarta);

    if (now.isBefore(mulaiDate)) {
      return 'Belum Dimulai';
    } else if (now.isAfter(selesaiDate)) {
      return 'Selesai';
    } else {
      return 'Sedang Berlangsung';
    }
  }
  String formatTanggal(String tanggal) {
    try {
      final date = DateTime.parse(tanggal);
      final jakarta = tz.getLocation('Asia/Jakarta');
      final jakartaTime = tz.TZDateTime.from(date, jakarta);
      return DateFormat('dd MMM yyyy HH:mm').format(jakartaTime);
    } catch (e) {
      return tanggal;
    }
  }

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    getPemilihan();
    _loadUnreadNotifCount();
  }

  // ── Notifikasi ──────────────────────────────────────────────────────────
  Future<void> _loadUnreadNotifCount() async {
    final count = await NotificationService.getUnreadCount();
    if (!mounted) return;
    setState(() {
      _unreadNotifCount = count;
    });
  }

  Future<void> _openNotifikasi(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotifikasiPage()),
    );
    // Setelah kembali dari halaman notifikasi, refresh badge
    // (NotifikasiPage menandai semua sudah dibaca saat dibuka).
    _loadUnreadNotifCount();
  }

  Future<void> getPemilihan() async {
    try {
      final response = await http.get(
        //Atur ip local
        Uri.parse('https://votingmu.my.id/api/pemilihan'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success']) {
          setState(() {
            namaPemilihan =
                data['data']['nama_pemilihan'] ?? '';

            deskripsi =
                data['data']['deskripsi'] ?? '';

            mulai =
                data['data']['mulai'] ?? '';

            selesai =
                data['data']['selesai'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error pemilihan: $e');
    }
  }

  //Link Kuisioner
  Future<void> _openKuisioner(BuildContext context) async {
    const String formUrl = 'https://forms.gle/hcExUUS11PEFnYPdA';

    final uri = Uri.parse(formUrl);

    final success = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication, // buka di browser/app luar
    );

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka link kuisioner.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 28),
              _buildBannerCard(context),
              const SizedBox(height: 32),
              _buildSectionTitle('Menu Utama'),
              const SizedBox(height: 16),
              _buildMenuGrid(context),
              const SizedBox(height: 32),
              _buildSectionTitle('Lainnya'),
              const SizedBox(height: 16),
              _buildActivityList(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Selamat Datang 👋',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Votura',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => _openNotifikasi(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC900E).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFFEC900E),
                  size: 22,
                ),
              ),
              if (_unreadNotifCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        _unreadNotifCount > 9 ? '9+' : '$_unreadNotifCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCard(BuildContext context) {
    final bool bisaVote = getStatusPemilihan() == 'Sedang Berlangsung';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEC900E), Color(0xFFFF6B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC900E).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🗳️ ${getStatusPemilihan()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                namaPemilihan.isEmpty
                    ? 'Memuat Data...'
                    : namaPemilihan,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 52,
                        child: Text('Mulai', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ),
                      const Text(' : ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(formatTanggal(mulai), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const SizedBox(
                        width: 52,
                        child: Text('Selesai', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ),
                      const Text(' : ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(formatTanggal(selesai), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: bisaVote
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VotePage(),
                          ),
                        );
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: bisaVote
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    bisaVote
                        ? 'Mulai Voting →'
                        : getStatusPemilihan() == 'Belum Dimulai'
                            ? 'Belum Dimulai'
                            : 'Pemilihan Selesai',
                    style: TextStyle(
                      color: bisaVote
                          ? const Color(0xFFEC900E)
                          : Colors.grey,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    final menus = [
      _MenuItem(
        icon: Icons.verified_user_outlined,
        title: 'Verifikasi\nPemilihan',
        color: const Color(0xFF4F46E5),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VerifikasiPemilihanPage()),
        ), // tambahkan halaman verifikasi jika ada
      ),
      _MenuItem(
        icon: Icons.people_alt_outlined,
        title: 'Daftar\nKandidat',
        color: const Color(0xFFEC900E),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KandidatPage()),
        ),
      ),
      _MenuItem(
        icon: Icons.bar_chart_rounded,
        title: 'Statistik\nHasil',
        color: const Color(0xFF10B981),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HasilPage()),
        ),
      ),
      _MenuItem(
        icon: Icons.person_outline_rounded,
        title: 'Profil\nSaya',
        color: const Color(0xFFEF4444),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        ),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.15,
      children: menus.map((m) => _buildMenuCard(m, context)).toList(),
    );
  }

  Widget _buildMenuCard(_MenuItem item, BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityList(BuildContext context) {
    final activities = [
      _Activity(
        title: 'Panduan Aplikasi',
        subtitle: 'Pelajari cara menggunakan Votura',
        time: '',
        icon: Icons.menu_book_outlined,
        color: const Color(0xFF4F46E5),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PanduanAplikasiPage()),
        ),
      ),
      _Activity(
        title: 'Tentang Aplikasi',
        subtitle: 'Lihat informasi tentang Votura',
        time: '',
        icon: Icons.info_outline_rounded,
        color: const Color(0xFF888888),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TentangAplikasiPage()),
        ),
      ),
      _Activity(
        title: 'Kuisioner Responden',
        subtitle: 'Isi kuisioner untuk membantu penelitian kami',
        time: '',
        icon: Icons.assignment_outlined,
        color: Color.fromARGB(255, 23, 19, 153),
        onTap: () => _openKuisioner(context),
      ),
    ];

    return Column(
      children: activities.map((a) => _buildActivityItem(a)).toList(),
    );
  }

  Widget _buildActivityItem(_Activity activity) {
    return GestureDetector(
      onTap: activity.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: activity.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                activity.icon,
                color: activity.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activity.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            if (activity.time.isNotEmpty)
              Text(
                activity.time,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFBBBBBB),
                ),
              ),
          ],
        ),
      ),
    );
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
        currentIndex: 0,
        selectedItemColor: const Color(0xFFEC900E),
        unselectedItemColor: const Color(0xFFBBBBBB),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
          else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HasilPage()),
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
}

class _MenuItem {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.color,
    this.onTap,
  });
}

class _Activity {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _Activity({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
    this.onTap,
  });
}