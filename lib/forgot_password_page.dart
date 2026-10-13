import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  bool isLoading = false;
  bool _emailFocused = false;
  String? _errorMessage;
  String? _successMessage;

  // ── Samakan dengan base URL Laravel di login.dart ───────────────────────
  static const String _baseUrl = 'https://votingmu.my.id/api';
  // ──────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  String? _validate() {
    if (emailController.text.trim().isEmpty) {
      return 'Email tidak boleh kosong.';
    }
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$')
        .hasMatch(emailController.text.trim())) {
      return 'Format email tidak valid.';
    }
    return null;
  }

  Future<void> _sendResetLink() async {
    FocusScope.of(context).unfocus();

    final validationError = _validate();
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
        _successMessage = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final uri = Uri.parse('$_baseUrl/forgot-password');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': emailController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        setState(() {
          _successMessage = body['message'] as String? ??
              'Link reset password telah dikirim ke email Anda.';
        });

        // Opsional: arahkan langsung ke halaman input kode/token manual,
        // sebagai fallback jika user tidak bisa tap link dari email.
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResetPasswordPage(
                  email: emailController.text.trim(),
                ),
              ),
            );
          });
        }
      } else {
        final message = body['message'] as String? ??
            'Gagal mengirim link reset password.';
        setState(() => _errorMessage = message);
      }
    } on http.ClientException {
      setState(() => _errorMessage =
          'Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFEC900E);
    const textDark = Color(0xFF1A1A2E);
    const textMuted = Color(0xFF8A8FAB);
    const inputFill = Color(0xFFF7F8FC);
    const borderColor = Color(0xFFE0E4EF);
    const errorColor = Color(0xFFD32F2F);
    const successColor = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_reset_rounded,
                    size: 56, color: primary),
                const SizedBox(height: 18),
                const Text(
                  'Lupa Password?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Masukkan email pemilih yang terdaftar. Kami akan mengirimkan '
                  'link untuk membuat password baru.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),

                const SizedBox(height: 28),

                if (_errorMessage != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: errorColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: errorColor.withOpacity(0.3)),
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

                if (_successMessage != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: successColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: successColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            color: successColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(
                              color: successColor,
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

                Focus(
                  onFocusChange: (v) => setState(() => _emailFocused = v),
                  child: TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => isLoading ? null : _sendResetLink(),
                    style: const TextStyle(color: textDark, fontSize: 14),
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Email Pemilih',
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
                      fillColor: _emailFocused ? Colors.white : inputFill,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: primary, width: 1.5),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _sendResetLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      disabledBackgroundColor: primary.withOpacity(0.5),
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
                            'Kirim Link Reset',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Kembali ke Login',
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}