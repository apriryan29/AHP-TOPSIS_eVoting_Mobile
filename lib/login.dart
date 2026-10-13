import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool _emailFocused = false;
  bool _passwordFocused = false;
  String? _errorMessage;

  // ── Ganti dengan base URL Laravel Anda ──────────────────────────────────────
  static const String _baseUrl = 'https://votingmu.my.id/api';
  // ────────────────────────────────────────────────────────────────────────────

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ── Validasi input sebelum kirim ─────────────────────────────────────────
  String? _validate() {
    if (emailController.text.trim().isEmpty) return 'Email tidak boleh kosong.';
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$')
        .hasMatch(emailController.text.trim())) {
      return 'Format email tidak valid.';
    }
    if (passwordController.text.isEmpty) return 'Password tidak boleh kosong.';
    if (passwordController.text.length < 6) {
      return 'Password minimal 6 karakter.';
    }
    return null;
  }

  // ── Panggil Laravel API POST /api/vote/login ──────────────────────────────
  Future<void> login() async {
    // Sembunyikan keyboard
    FocusScope.of(context).unfocus();

    final validationError = _validate();
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse('$_baseUrl/login');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': emailController.text.trim(),
              'password': passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 15));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        // ── Simpan token & data user ke SharedPreferences ──────────────────
        final prefs = await SharedPreferences.getInstance();
        final user = body['user'] as Map<String, dynamic>? ?? {};
        print(user);
        await prefs.setString('user_name', user['nama']?.toString() ?? '');
        await prefs.setString('user_email', user['email']?.toString() ?? '');
        await prefs.setString('user_komisariat', user['komisariat']?.toString()?? '');
        await prefs.setInt('user_id', (user['id'] as num?)?.toInt() ?? 0);

        if (!mounted) return;

        // Navigasi ke HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        // 401 Unauthorized atau validasi gagal dari Laravel
        final message = body['message'] as String? ??
            body['error'] as String? ??
            'Login gagal. Periksa email dan password Anda.';
        setState(() => _errorMessage = message);
      }
    } on http.ClientException {
      setState(() =>
          _errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFEC900E);
    const accent = Color(0xFFCFA84B);
    const textDark = Color(0xFF1A1A2E);
    const textMuted = Color(0xFF8A8FAB);
    const inputFill = Color(0xFFF7F8FC);
    const borderColor = Color(0xFFE0E4EF);
    const errorColor = Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Center(
                      child: Image.asset(
                        'assets/logo.png',
                        width: 100,
                        height: 100,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Divider ornamen
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accent.withOpacity(0.0), accent],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.star_rounded,
                              size: 10, color: accent),
                        ),
                        Container(
                          width: 36,
                          height: 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accent, accent.withOpacity(0.0)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // Form card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Masuk ke Akun',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Silakan masukkan email dan password Anda',
                            style: TextStyle(fontSize: 12, color: textMuted),
                          ),

                          const SizedBox(height: 22),

                          // ── Error banner ──────────────────────────────────
                          if (_errorMessage != null) ...[
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: errorColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: errorColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: errorColor, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: errorColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email field
                          Focus(
                            onFocusChange: (v) =>
                                setState(() => _emailFocused = v),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _emailFocused
                                    ? [
                                        BoxShadow(
                                          color: primary.withOpacity(0.12),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : [],
                              ),
                              child: TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(
                                    color: textDark, fontSize: 14),
                                onChanged: (_) {
                                  if (_errorMessage != null) {
                                    setState(() => _errorMessage = null);
                                  }
                                },
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: TextStyle(
                                    color: _emailFocused ? primary : textMuted,
                                    fontSize: 13,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: _emailFocused ? primary : textMuted,
                                    size: 20,
                                  ),
                                  filled: true,
                                  fillColor:
                                      _emailFocused ? Colors.white : inputFill,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(color: borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: primary, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Password field
                          Focus(
                            onFocusChange: (v) =>
                                setState(() => _passwordFocused = v),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _passwordFocused
                                    ? [
                                        BoxShadow(
                                          color: primary.withOpacity(0.12),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : [],
                              ),
                              child: TextField(
                                controller: passwordController,
                                obscureText: obscurePassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => isLoading ? null : login(),
                                style: const TextStyle(
                                    color: textDark, fontSize: 14),
                                onChanged: (_) {
                                  if (_errorMessage != null) {
                                    setState(() => _errorMessage = null);
                                  }
                                },
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: TextStyle(
                                    color: _passwordFocused ? primary : textMuted,
                                    fontSize: 13,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color:
                                        _passwordFocused ? primary : textMuted,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: textMuted,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => obscurePassword = !obscurePassword),
                                  ),
                                  filled: true,
                                  fillColor: _passwordFocused
                                      ? Colors.white
                                      : inputFill,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(color: borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: primary, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordPage(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Lupa password?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Login button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                disabledBackgroundColor:
                                    primary.withOpacity(0.5),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Masuk',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Footer
                    const Text(
                      '© Sistem Pemilihan Digital',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}