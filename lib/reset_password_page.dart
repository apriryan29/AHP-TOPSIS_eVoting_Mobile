import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart';

class ResetPasswordPage extends StatefulWidget {
  /// Email pemilih yang sedang melakukan reset password.
  final String email;

  /// Token dari deep link (jika user membuka lewat tap link di email).
  /// Jika null, user akan diminta memasukkan token secara manual
  /// (fallback, misal saat link tidak bisa diklik dari email client).
  final String? token;

  const ResetPasswordPage({
    super.key,
    required this.email,
    this.token,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late final TextEditingController tokenController;
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;
  String? _errorMessage;
  String? _successMessage;

  // ── Samakan dengan base URL Laravel di login.dart ───────────────────────
  static const String _baseUrl = 'https://votingmu.my.id/api';
  // ──────────────────────────────────────────────────────────────────────

  bool get _tokenPrefilled => widget.token != null && widget.token!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    tokenController = TextEditingController(text: widget.token ?? '');
  }

  @override
  void dispose() {
    tokenController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validate() {
    if (tokenController.text.trim().isEmpty) {
      return 'Kode/token reset tidak boleh kosong.';
    }
    if (newPasswordController.text.isEmpty) {
      return 'Password baru tidak boleh kosong.';
    }
    if (newPasswordController.text.length < 6) {
      return 'Password minimal 6 karakter.';
    }
    if (newPasswordController.text != confirmPasswordController.text) {
      return 'Konfirmasi password tidak sama.';
    }
    return null;
  }

  Future<void> _submitReset() async {
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
      final uri = Uri.parse('$_baseUrl/reset-password');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': widget.email,
              'token': tokenController.text.trim(),
              'password': newPasswordController.text,
              'password_confirmation': confirmPasswordController.text,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        setState(() {
          _successMessage = body['message'] as String? ??
              'Password berhasil diubah. Silakan login kembali.';
        });

        if (mounted) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          });
        }
      } else {
        final message = body['message'] as String? ??
            'Gagal mengubah password. Periksa kode reset Anda.';
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
                const Icon(Icons.password_rounded, size: 56, color: primary),
                const SizedBox(height: 18),
                const Text(
                  'Buat Password Baru',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _tokenPrefilled
                      ? 'Kode reset terdeteksi otomatis dari email Anda (${widget.email}). Silakan masukkan password baru.'
                      : 'Masukkan kode reset yang dikirim ke ${widget.email}, lalu buat password baru.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: textMuted),
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

                // Token field — disembunyikan dari edit jika sudah terisi
                // otomatis dari deep link, tapi tetap ditampilkan agar
                // transparan ke user. Bisa diketuk untuk koreksi manual.
                TextField(
                  controller: tokenController,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: textDark, fontSize: 14),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Kode Reset',
                    labelStyle: const TextStyle(color: textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.vpn_key_outlined,
                        color: textMuted, size: 20),
                    suffixIcon: _tokenPrefilled
                        ? const Icon(Icons.check_circle,
                            color: Colors.green, size: 18)
                        : null,
                    filled: true,
                    fillColor: inputFill,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primary, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: textDark, fontSize: 14),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    labelStyle: const TextStyle(color: textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: textMuted, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => obscureNewPassword = !obscureNewPassword),
                    ),
                    filled: true,
                    fillColor: inputFill,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primary, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => isLoading ? null : _submitReset(),
                  style: const TextStyle(color: textDark, fontSize: 14),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password Baru',
                    labelStyle: const TextStyle(color: textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: textMuted, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() =>
                          obscureConfirmPassword = !obscureConfirmPassword),
                    ),
                    filled: true,
                    fillColor: inputFill,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primary, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submitReset,
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
                            'Simpan Password Baru',
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
        ),
      ),
    );
  }
}