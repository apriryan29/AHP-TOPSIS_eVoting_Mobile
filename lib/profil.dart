import 'home.dart';
import 'login.dart';
import 'about.dart';
import 'hasil.dart';
import 'notification_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;


// ════════════════════════════════════════════════════════════════════════════
// API: Fetch Profile
// ════════════════════════════════════════════════════════════════════════════
Future<Map<String, dynamic>> fetchProfile() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id');

  if (userId == null) throw Exception('User belum login');

  final response = await http.get(
    Uri.parse('https://votingmu.my.id/api/profile/$userId'),
    headers: {'Accept': 'application/json'},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final profile = data['data'];

    bool _toBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is num) return value == 1;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return false;
    }

    final bool hasVoted   = _toBool(profile['status_memilih']);
    final bool isVerified = _toBool(profile['status_verifikasi']);

    print('FULL PROFILE RESPONSE: $profile');
    print('status_verifikasi: ${profile['status_verifikasi']} -> isVerified=$isVerified');
    print('status_memilih: ${profile['status_memilih']} -> hasVoted=$hasVoted');

    String status;
    if (hasVoted) {
      status = 'sudah_memilih';
    } else if (isVerified) {
      status = 'terverifikasi';
    } else {
      status = 'belum_terverifikasi';
    }

    await prefs.setString('user_verification_status', status);

    print('Profile data: $profile');
    return profile;
  } else {
    throw Exception('Gagal ambil profile');
  }
}


// ════════════════════════════════════════════════════════════════════════════
// ProfilePage
// ════════════════════════════════════════════════════════════════════════════
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String nama        = '';
  String email       = '';
  String komisariat  = '';
  String _verificationStatus = 'belum_terverifikasi';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nama                = prefs.getString('user_name')                ?? '';
      email               = prefs.getString('user_email')               ?? '';
      komisariat          = prefs.getString('user_komisariat')          ?? '';
      _verificationStatus = prefs.getString('user_verification_status') ?? 'belum_terverifikasi';
      _isLoading = false;
    });

    _refreshVerificationStatus();
  }

  Future<void> _refreshVerificationStatus() async {
    try {
      await fetchProfile();
      final prefs = await SharedPreferences.getInstance();
      final latestStatus = prefs.getString('user_verification_status') ?? 'belum_terverifikasi';
      if (!mounted) return;
      setState(() {
        _verificationStatus = latestStatus;
      });
    } catch (e) {
      // Diamkan saja kalau gagal
    }
  }

  String getInitials(String text) {
    if (text.trim().isEmpty) return '?';
    final words = text.trim().split(' ');
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words.first[0] + words.last[0]).toUpperCase();
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> _doLogout(BuildContext dialogCtx) async {
    Navigator.of(dialogCtx).pop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // ── API: Update Profile ───────────────────────────────────────────────────
  Future<void> updateProfileApi({
    required String nama,
    required String email,
    required String komisariat,
  }) async {
    final prefs  = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    final response = await http.put(
      Uri.parse('https://votingmu.my.id/api/profile/$userId'),
      headers: {'Accept': 'application/json'},
      body: {
        'nama': nama,
        'email': email,
        'komisariat': komisariat,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal update profile');
    }
  }

  // ── Simpan Edit Profil ────────────────────────────────────────────────────
  Future<void> _saveProfile({
    required String newNama,
    required String newEmail,
    required String newKomisariat,
  }) async {
    await updateProfileApi(
      nama: newNama,
      email: newEmail,
      komisariat: newKomisariat,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name',       newNama);
    await prefs.setString('user_email',      newEmail);
    await prefs.setString('user_komisariat', newKomisariat);

    setState(() {
      nama       = newNama;
      email      = newEmail;
      komisariat = newKomisariat;
    });
  }

  // ── API: Change Password ──────────────────────────────────────────────────
  Future<void> _callChangePasswordApi({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final prefs  = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    final response = await http.post(
      Uri.parse('https://votingmu.my.id/api/profile/$userId/change-password'),
      headers: {'Accept': 'application/json'},
      body: {
        'old_password':              oldPassword,
        'new_password':              newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['status'] != true) {
      throw Exception(data['message'] ?? 'Gagal ubah password');
    }
  }


  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC900E)))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildProfileCard(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Akun'),
                    const SizedBox(height: 12),
                    _buildMenuSection([
                      _MenuTile(
                        icon: Icons.person_outline_rounded,
                        label: 'Edit Profil',
                        color: const Color(0xFF4F46E5),
                        onTap: () => _showEditProfileDialog(context),
                      ),
                      _MenuTile(
                        icon: Icons.lock_outline_rounded,
                        label: 'Ubah Kata Sandi',
                        color: const Color(0xFF10B981),
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                      _MenuTile(
                        icon: Icons.verified_user_outlined,
                        label: 'Status Akun',
                        color: const Color(0xFFEC900E),
                        trailing: _verifiedBadge(),
                        onTap: () => _showVerificationDetailSheet(context),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Lainnya'),
                    const SizedBox(height: 12),
                    _buildMenuSection([
                      _MenuTile(
                        icon: Icons.info_outline_rounded,
                        label: 'Tentang Aplikasi',
                        color: const Color(0xFF888888),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TentangAplikasiPage()),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 28),
                    _buildLogoutButton(context),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Votura v1.0.1',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }


  // ════════════════════════════════════════════════════════════════════════════
  // WIDGETS UTAMA
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return const Text(
      'Profil',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildProfileCard() {
    final initials     = getInitials(nama);
    final displayName  = nama.isNotEmpty  ? nama  : 'Pengguna';
    final displayEmail = email.isNotEmpty ? email : '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC900E), Color(0xFFFF6B35)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  displayEmail,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 6),
                _buildMiniStatusBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatusBadge() {
    final Map<String, Map<String, dynamic>> info = {
      'belum_terverifikasi': {
        'label': 'Belum Terverifikasi',
        'color': const Color(0xFFEF4444),
        'icon': Icons.cancel_outlined,
      },
      'terverifikasi': {
        'label': 'Terverifikasi',
        'color': const Color(0xFF10B981),
        'icon': Icons.verified_rounded,
      },
      'sudah_memilih': {
        'label': 'Sudah Memilih',
        'color': const Color(0xFF4F46E5),
        'icon': Icons.verified_rounded,
      },
    };

    final current = info[_verificationStatus] ?? info['belum_terverifikasi']!;
    final Color color = current['color'] as Color;
    final IconData icon = current['icon'] as IconData;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            current['label'] as String,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF888888),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildMenuSection(List<_MenuTile> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: List.generate(tiles.length, (i) {
          final tile   = tiles[i];
          final isLast = i == tiles.length - 1;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tile.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(tile.icon, color: tile.color, size: 20),
                ),
                title: Text(
                  tile.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                trailing: tile.trailing ??
                    Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                onTap: tile.onTap,
              ),
              if (!isLast) Divider(height: 1, indent: 68, color: Colors.grey[100]),
            ],
          );
        }),
      ),
    );
  }

  Widget _verifiedBadge() {
    switch (_verificationStatus) {
      case 'sudah_memilih':
        return _buildStatusBadge(
          label: 'Sudah Memilih',
          color: const Color(0xFF4F46E5),
          icon: Icons.verified_rounded,
        );
      case 'terverifikasi':
        return _buildStatusBadge(
          label: 'Terverifikasi',
          color: const Color(0xFF10B981),
          icon: Icons.verified_rounded,
        );
      case 'belum_terverifikasi':
      default:
        return _buildStatusBadge(
          label: 'Belum',
          color: const Color(0xFFEF4444),
          icon: Icons.cancel_outlined,
        );
    }
  }

  Widget _buildStatusBadge({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
            SizedBox(width: 10),
            Text(
              'Keluar dari Akun',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ════════════════════════════════════════════════════════════════════════════
  // DIALOG & BOTTOM SHEET
  // ════════════════════════════════════════════════════════════════════════════

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 28),
              ),
              const SizedBox(height: 20),
              const Text(
                'Keluar dari Akun?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kamu akan keluar dari Akun ini.\nApakah kamu yakin?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF888888), height: 1.5),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text('Batal',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF888888)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _doLogout(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text('Keluar',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ PERBAIKAN: kirim rootContext ke dialog agar SnackBar tampil di Scaffold utama
  void _showEditProfileDialog(BuildContext context) async {
    try {
      final profile = await fetchProfile();
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _verificationStatus = prefs.getString('user_verification_status') ?? 'belum_terverifikasi';
      });
      showDialog(
        context: context,
        builder: (ctx) => _EditProfileDialog(
          initialNama: profile['nama'] ?? '',
          initialEmail: profile['email'] ?? '',
          initialKomisariat: profile['komisariat'] ?? '',
          onSave: _saveProfile,
          rootContext: context, // ✅ kirim context Scaffold
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Gagal load profile'),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ✅ PERBAIKAN: kirim rootContext ke dialog agar SnackBar tampil di Scaffold utama
  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _ChangePasswordDialog(
        onSubmit: _callChangePasswordApi,
        rootContext: context, // ✅ kirim context Scaffold
      ),
    );
  }

  void _showVerificationDetailSheet(BuildContext context) {
    final Map<String, Map<String, dynamic>> statusInfo = {
      'belum_terverifikasi': {
        'title':       'Belum Terverifikasi',
        'description': 'Akun kamu belum terverifikasi untuk melakkan pemilihan. Silakan lakukan verifikasi pada menu Verifikasi Pemilihan.',
        'icon':        Icons.cancel_outlined,
        'color':       const Color(0xFFEF4444),
      },
      'terverifikasi': {
        'title':       'Terverifikasi',
        'description': 'Akun kamu sudah terverifikasi. Kamu berhak menggunakan hak suaramu dalam pemilihan yang sedang berlangsung.',
        'icon':        Icons.verified_rounded,
        'color':       const Color(0xFF10B981),
      },
      'sudah_memilih': {
        'title':       'Sudah Memilih',
        'description': 'Kamu sudah menggunakan hak suaramu. Terima kasih telah berpartisipasi dalam pemilihan ini.',
        'icon':        Icons.verified_rounded,
        'color':       const Color(0xFF4F46E5),
      },
    };

    final info      = statusInfo[_verificationStatus] ?? statusInfo['belum_terverifikasi']!;
    final Color color   = info['color'] as Color;
    final IconData icon = info['icon'] as IconData;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              info['title'] as String,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                info['description'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF888888),
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildStatusTimeline(color),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Center(
                  child: Text(
                    'Tutup',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(Color activeColor) {
    final steps = [
      {'label': 'Belum\nTerverifikasi', 'status': 'belum_terverifikasi'},
      {'label': 'Terverifikasi',        'status': 'terverifikasi'},
      {'label': 'Sudah\nMemilih',       'status': 'sudah_memilih'},
    ];

    final statusOrder = ['belum_terverifikasi', 'terverifikasi', 'sudah_memilih'];
    final currentIdx  = statusOrder.indexOf(_verificationStatus);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final lineIdx = i ~/ 2;
          final isDone  = lineIdx < currentIdx;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(top: 14),
              color: isDone ? activeColor : Colors.grey[200],
            ),
          );
        }

        final stepIdx  = i ~/ 2;
        final isDone   = stepIdx <= currentIdx;
        final isActive = stepIdx == currentIdx;
        final stepColor = isDone ? activeColor : Colors.grey[300]!;

        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 30 : 24,
              height: isActive ? 30 : 24,
              decoration: BoxDecoration(
                color: isDone ? stepColor : Colors.grey[200],
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? stepColor : Colors.grey[300]!,
                  width: isActive ? 2.5 : 1.5,
                ),
                boxShadow: isActive
                    ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                    : [],
              ),
              child: Icon(
                isDone ? Icons.check_rounded : Icons.circle,
                color: isDone ? Colors.white : Colors.grey[300],
                size: isActive ? 16 : 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              steps[stepIdx]['label']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isDone ? stepColor : Colors.grey[400],
                height: 1.3,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x0D000000), blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: const Color(0xFFEC900E),
        unselectedItemColor: const Color(0xFFBBBBBB),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HasilPage()));
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


// ════════════════════════════════════════════════════════════════════════════
// DATA CLASS
// ════════════════════════════════════════════════════════════════════════════
class _MenuTile {
  final IconData icon;
  final String label;
  final Color color;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    this.trailing,
    this.onTap,
  });
}


// ════════════════════════════════════════════════════════════════════════════
// MODAL: EDIT PROFIL
// ════════════════════════════════════════════════════════════════════════════
class _EditProfileDialog extends StatefulWidget {
  final String initialNama;
  final String initialEmail;
  final String initialKomisariat;
  final Future<void> Function({
    required String newNama,
    required String newEmail,
    required String newKomisariat,
  }) onSave;
  final BuildContext rootContext; // ✅ context Scaffold utama

  const _EditProfileDialog({
    required this.initialNama,
    required this.initialEmail,
    required this.initialKomisariat,
    required this.onSave,
    required this.rootContext,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _emailController;
  late TextEditingController _komisariatController;

  bool    _isSaving     = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _namaController       = TextEditingController(text: widget.initialNama);
    _emailController      = TextEditingController(text: widget.initialEmail);
    _komisariatController = TextEditingController(text: widget.initialKomisariat);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _komisariatController.dispose();
    super.dispose();
  }

  String? _validateNama(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nama tidak boleh kosong';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email tidak boleh kosong';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Format email tidak valid';
    return null;
  }

  String? _validateKomisariat(String? value) {
    if (value == null || value.trim().isEmpty) return 'Asal komisariat tidak boleh kosong';
    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSaving = true; _errorMessage = null; });

    try {
      await widget.onSave(
        newNama:       _namaController.text.trim(),
        newEmail:      _emailController.text.trim(),
        newKomisariat: _komisariatController.text.trim(),
      );
      if (!mounted) return;

      // ✅ Tutup dialog dulu, lalu tampilkan SnackBar via rootContext
      Navigator.of(context).pop();
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Profil berhasil diperbarui',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );

      // ── Catat notifikasi lokal ──────────────────────────────────────────
      await NotificationService.addNotification(
        title: 'Profil Diperbarui',
        body: 'Data profil kamu berhasil disimpan.',
      );
    } catch (e) {
      setState(() { _errorMessage = 'Gagal menyimpan profil. Silakan coba lagi.'; });
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.person_outline_rounded, color: Color(0xFF4F46E5), size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text('Edit Profil',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildLabel('Nama'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _namaController,
                  hintText: 'Masukkan nama lengkap',
                  icon: Icons.badge_outlined,
                  validator: _validateNama,
                ),
                const SizedBox(height: 16),

                _buildLabel('Email'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Masukkan email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),

                _buildLabel('Asal Komisariat'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _komisariatController,
                  hintText: 'Masukkan asal komisariat',
                  icon: Icons.account_balance_outlined,
                  validator: _validateKomisariat,
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _buildErrorBox(_errorMessage!),
                ],

                const SizedBox(height: 26),
                _buildActionButtons(
                  isBusy: _isSaving,
                  onCancel: () => Navigator.of(context).pop(),
                  onConfirm: _handleSave,
                  confirmColor: const Color(0xFF4F46E5),
                  confirmLabel: 'Simpan',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF888888)));

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
        prefixIcon: Icon(icon, size: 19, color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.4)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4)),
        errorStyle: const TextStyle(fontSize: 11.5, color: Color(0xFFEF4444)),
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
// MODAL: UBAH KATA SANDI
// ════════════════════════════════════════════════════════════════════════════
class _ChangePasswordDialog extends StatefulWidget {
  final Future<void> Function({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) onSubmit;
  final BuildContext rootContext; // ✅ context Scaffold utama

  const _ChangePasswordDialog({
    required this.onSubmit,
    required this.rootContext,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey                   = GlobalKey<FormState>();
  final _oldPasswordController     = TextEditingController();
  final _newPasswordController     = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool    _obscureOld     = true;
  bool    _obscureNew     = true;
  bool    _obscureConfirm = true;
  bool    _isSubmitting   = false;
  String? _errorMessage;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateOldPassword(String? value) {
    if (value == null || value.isEmpty) return 'Kata sandi lama tidak boleh kosong';
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return 'Kata sandi baru tidak boleh kosong';
    if (value.length < 6) return 'Minimal 6 karakter';
    if (value == _oldPasswordController.text) return 'Kata sandi baru tidak boleh sama dengan yang lama';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Konfirmasi kata sandi tidak boleh kosong';
    if (value != _newPasswordController.text) return 'Konfirmasi kata sandi tidak cocok';
    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _errorMessage = null; });

    try {
      await widget.onSubmit(
        oldPassword:             _oldPasswordController.text,
        newPassword:             _newPasswordController.text,
        newPasswordConfirmation: _confirmPasswordController.text,
      );
      if (!mounted) return;

      // ✅ Tutup dialog dulu, lalu tampilkan SnackBar via rootContext
      Navigator.of(context).pop();
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Kata sandi berhasil diubah',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );

      // ── Catat notifikasi lokal ──────────────────────────────────────────
      await NotificationService.addNotification(
        title: 'Kata Sandi Diubah',
        body: 'Kata sandi akun kamu berhasil diperbarui. Jika bukan kamu yang melakukan ini, segera hubungi admin.',
      );
    } catch (e) {
      setState(() {
        _errorMessage = e is UnimplementedError
            ? 'Fitur ubah kata sandi belum terhubung ke server.'
            : 'Gagal mengubah kata sandi. Periksa kata sandi lama kamu.';
      });
    } finally {
      if (mounted) setState(() { _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF10B981), size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text('Ubah Kata Sandi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildLabel('Kata Sandi Lama'),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _oldPasswordController,
                  hintText: 'Masukkan kata sandi lama',
                  obscure: _obscureOld,
                  onToggleObscure: () => setState(() => _obscureOld = !_obscureOld),
                  validator: _validateOldPassword,
                ),
                const SizedBox(height: 16),

                _buildLabel('Kata Sandi Baru'),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _newPasswordController,
                  hintText: 'Minimal 6 karakter',
                  obscure: _obscureNew,
                  onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                  validator: _validateNewPassword,
                ),
                const SizedBox(height: 16),

                _buildLabel('Konfirmasi Kata Sandi Baru'),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  hintText: 'Ulangi kata sandi baru',
                  obscure: _obscureConfirm,
                  onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: _validateConfirmPassword,
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _buildErrorBox(_errorMessage!),
                ],

                const SizedBox(height: 26),
                _buildActionButtons(
                  isBusy: _isSubmitting,
                  onCancel: () => Navigator.of(context).pop(),
                  onConfirm: _handleSubmit,
                  confirmColor: const Color(0xFF10B981),
                  confirmLabel: 'Simpan',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF888888)));

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
        prefixIcon: Icon(Icons.lock_outline_rounded, size: 19, color: Colors.grey[400]),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 19,
            color: Colors.grey[400],
          ),
          onPressed: onToggleObscure,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.4)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4)),
        errorStyle: const TextStyle(fontSize: 11.5, color: Color(0xFFEF4444)),
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS (dipakai di kedua dialog)
// ════════════════════════════════════════════════════════════════════════════

Widget _buildErrorBox(String message) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFEF4444).withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12.5)),
        ),
      ],
    ),
  );
}

Widget _buildActionButtons({
  required bool isBusy,
  required VoidCallback onCancel,
  required Future<void> Function() onConfirm,
  required Color confirmColor,
  required String confirmLabel,
}) {
  return Row(
    children: [
      Expanded(
        child: GestureDetector(
          onTap: isBusy ? null : onCancel,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('Batal',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF888888))),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: GestureDetector(
          onTap: isBusy ? null : onConfirm,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: confirmColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: isBusy
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(confirmLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
            ),
          ),
        ),
      ),
    ],
  );
}