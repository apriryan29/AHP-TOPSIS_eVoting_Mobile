import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';
import 'vote.dart';
import 'notification_service.dart';

class VerifikasiPemilihanPage extends StatefulWidget {
  const VerifikasiPemilihanPage({super.key});

  @override
  State<VerifikasiPemilihanPage> createState() =>
      _VerifikasiPemilihanPageState();
}

class _VerifikasiPemilihanPageState extends State<VerifikasiPemilihanPage>
    with TickerProviderStateMixin {
  static const String baseUrl = 'https://votingmu.my.id/api';
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSuccess = false;
  String _submittedEmail = '';

  late AnimationController _successAnimController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  static const Color _primaryBlue = Color(0xFFEC900E);
  static const Color _lightBlue = Color(0xFFE6F1FB);
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _bgSecondary = Color(0xFFF9FAFB);
  static const Color _successGreen = Color(0xFF3B6D11);
  static const Color _successBg = Color(0xFFEAF3DE);

  @override
  void initState() {
    super.initState();
    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _successAnimController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      final response = await http.post(
        Uri.parse('$baseUrl/kirimtoken'),
        headers: {
          'Accept': 'application/json',
        },
        body: {
          'user_id': userId.toString(),
          'email': _emailController.text.trim(),
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Token sudah dikirim oleh backend ke email pemilih dan
        // sudah dicocokkan dengan kolom Vote.token di database.
        // Tidak perlu menyimpan token apapun secara lokal di sini —
        // verifikasi token akan dicocokkan langsung ke server (lihat TokenPage).
        setState(() {
          _isSuccess = true;
          _submittedEmail = _emailController.text.trim();
        });

        _successAnimController.forward();

        // ── Catat notifikasi lokal: token telah dikirim ──────────────────
        await NotificationService.addNotification(
          title: 'Token Telah Dikirim',
          body:
              'Token pemilihan telah dikirim ke $_submittedEmail. Silakan cek email Anda.',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? 'Gagal mengirim token',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleResend() {
    setState(() {
      _isSuccess = false;
      _submittedEmail = '';
      _emailController.clear();
    });
    _successAnimController.reset();
  }

  void _kembaliKeHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  void _lanjutKeVote() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const VotePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Halaman ini biasanya dibuka lewat pushAndRemoveUntil (stack route
      // sebelumnya dihapus), jadi back fisik Android harus diarahkan manual
      // ke HomePage, bukan dibiarkan menutup aplikasi.
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _kembaliKeHome();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: _textPrimary),
            onPressed: _kembaliKeHome,
          ),
          title: const Text(
            'Verifikasi Pemilihan',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 20,
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _isSuccess
                ? _buildSuccessView(key: const ValueKey('success'))
                : _buildFormView(key: const ValueKey('form')),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _lightBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined,
                      size: 14, color: Color(0xFFEC900E)),
                  SizedBox(width: 6),
                  Text(
                    'VERIFIKASI PEMILIHAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEC900E),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Title
            const Text(
              'Masukkan Email\nTerdaftar',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                height: 1.25,
              ),
            ),

            const SizedBox(height: 10),

            // Subtitle
            const Text(
              'Token pemilihan akan dikirimkan ke alamat email yang telah terdaftar dalam sistem.',
              style: TextStyle(
                fontSize: 14,
                color: _textSecondary,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 32),

            // Email label
            const Text(
              'Alamat Email',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            // Email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enabled: !_isLoading,
              style: const TextStyle(
                fontSize: 14,
                color: _textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'contoh@email.com',
                hintStyle: TextStyle(
                  color: _textSecondary.withOpacity(0.5),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.mail_outline_rounded,
                  size: 20,
                  color: _textSecondary,
                ),
                filled: true,
                fillColor: _bgSecondary,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _borderColor, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _borderColor, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _primaryBlue, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Colors.redAccent, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Alamat email tidak boleh kosong';
                }
                final emailRegex =
                    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Masukkan alamat email yang valid';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Tombol Verifikasi
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  disabledBackgroundColor: const Color(0xFFEC900E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Verifikasi Sekarang',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 28),

            // Divider
            Container(height: 0.5, color: _borderColor),

            const SizedBox(height: 16),

            // Info keamanan
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 14, color: _textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data Anda dienkripsi dan aman. Hanya digunakan untuk keperluan verifikasi.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _textSecondary.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Ikon sukses dengan animasi
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: _successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 36,
                color: _successGreen,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Judul sukses
          FadeTransition(
            opacity: _fadeAnim,
            child: const Text(
              'Permintaan Terkirim!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 12),

          // Deskripsi
          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                const Text(
                  'Akun Anda telah meminta verifikasi untuk\ntoken pemilihan. Silakan buka notifikasi\natau kotak masuk email',
                  style: TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                    height: 1.7,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _submittedEmail,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _primaryBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Kotak tips
          FadeTransition(
            opacity: _fadeAnim,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bgSecondary,
                border: Border.all(color: _borderColor, width: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.inbox_outlined,
                      size: 20, color: _primaryBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                          height: 1.55,
                        ),
                        children: [
                          TextSpan(
                              text:
                                  'Jika tidak menemukan email, cek folder '),
                          TextSpan(
                            text: 'Spam',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: ' atau '),
                          TextSpan(
                            text: 'Promosi',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: '. Token berlaku hanya '),
                          TextSpan(
                            text: '1 Kali',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Kirim ulang
          FadeTransition(
            opacity: _fadeAnim,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh_rounded,
                    size: 15, color: _textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Tidak menerima email? ',
                  style: TextStyle(
                    fontSize: 13,
                    color: _textSecondary.withOpacity(0.85),
                  ),
                ),
                GestureDetector(
                  onTap: _handleResend,
                  child: const Text(
                    'Kirim ulang',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          
          const SizedBox(height: 28),

          // Divider
          Container(height: 0.5, color: _borderColor),

          const SizedBox(height: 28),

          // Tombol lanjut ke halaman vote
          FadeTransition(
            opacity: _fadeAnim,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _lanjutKeVote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Mulai Voting',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}