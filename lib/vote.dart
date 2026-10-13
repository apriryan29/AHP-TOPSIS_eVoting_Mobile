import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';
import 'verif.dart';
import 'notification_service.dart';

const String _baseUrl = 'https://votingmu.my.id';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL — hanya id, nama, foto
// ─────────────────────────────────────────────────────────────────────────────
class CalonFormatur {
  final int    id;
  final String nama;
  final String foto;

  const CalonFormatur({
    required this.id,
    required this.nama,
    required this.foto,
  });

  String get fotoUrl => '$_baseUrl/storage/$foto';

  String get inisial {
    final parts = nama.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return nama.isNotEmpty ? nama[0].toUpperCase() : '?';
  }

  factory CalonFormatur.fromJson(Map<String, dynamic> json) {
    return CalonFormatur(
      id:   json['id']   ?? 0,
      nama: json['nama'] ?? '',
      foto: json['foto'] ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WARNA AVATAR
// ─────────────────────────────────────────────────────────────────────────────
const List<_AvatarColor> _avatarColors = [
  _AvatarColor(bg: Color(0xFFE6F1FB), text: Color(0xFF0C447C)),
  _AvatarColor(bg: Color(0xFFEAF3DE), text: Color(0xFF27500A)),
  _AvatarColor(bg: Color(0xFFFAEEDA), text: Color(0xFF633806)),
  _AvatarColor(bg: Color(0xFFFBEAF0), text: Color(0xFF72243E)),
  _AvatarColor(bg: Color(0xFFE1F5EE), text: Color(0xFF085041)),
  _AvatarColor(bg: Color(0xFFEEEDFE), text: Color(0xFF3C3489)),
  _AvatarColor(bg: Color(0xFFFCEBEB), text: Color(0xFF791F1F)),
];

class _AvatarColor {
  final Color bg;
  final Color text;
  const _AvatarColor({required this.bg, required this.text});
}

_AvatarColor _colorForIndex(int i) => _avatarColors[i % _avatarColors.length];

// ─────────────────────────────────────────────────────────────────────────────
// KONSTANTA WARNA
// ─────────────────────────────────────────────────────────────────────────────
// _maxPilihan sekarang diambil dari server (kolom Pemilihan.maksimal_pilihan),
// lihat field instance _maxPilihan di _VotingPageState.

const Color _primaryOrange = Color(0xFFEC900E);
const Color _lightOrange   = Color(0xFFFBF1E6);
const Color _textPrimary   = Color(0xFF2E251A);
const Color _textSecondary = Color(0xFF80786B);
const Color _borderColor   = Color(0xFFEBE9E5);
const Color _bgPage        = Color(0xFFFAF8F7);
const Color _successBg     = Color(0xFFEAF3DE);
const Color _successGreen  = Color(0xFF3B6D11);
const Color _errorRed      = Color(0xFFA32D2D);
const Color _errorBg       = Color(0xFFFCEBEB);

// ═══════════════════════════════════════════════════════════════════════════
//  VotePage  —  entry point
// ═══════════════════════════════════════════════════════════════════════════
class VotePage extends StatelessWidget {
  const VotePage({super.key});

  @override
  Widget build(BuildContext context) => const TokenPage();
}

// ═══════════════════════════════════════════════════════════════════════════
//  TokenPage  —  verifikasi token dari email
// ═══════════════════════════════════════════════════════════════════════════
class TokenPage extends StatefulWidget {
  const TokenPage({super.key});

  @override
  State<TokenPage> createState() => _TokenPageState();
}

class _TokenPageState extends State<TokenPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool    _isLoading = false;
  bool    _isError   = false;
  String  _errorMsg  = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNodes[0].requestFocus());
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes)  f.dispose();
    super.dispose();
  }

  bool get _tokenLengkap => _controllers.every((c) => c.text.isNotEmpty);

  void _onInput(String val, int index) {
    if (val.length == 1 && index < 5) _focusNodes[index + 1].requestFocus();
    if (val.isEmpty   && index > 0)   _focusNodes[index - 1].requestFocus();
    setState(() {});
  }

  Future<void> _verifikasi() async {
    if (!_tokenLengkap || _isLoading) return;

    final inputToken = _controllers.map((c) => c.text).join();

    setState(() { _isLoading = true; _isError = false; _errorMsg = ''; });

    try {
      final prefs  = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        setState(() {
          _isLoading = false;
          _isError   = true;
          _errorMsg  = 'Sesi tidak ditemukan. Silakan login ulang.';
        });
        _clearInput();
        return;
      }

      // ── Cocokkan token ke database lewat backend ───────────────────────
      final response = await http.post(
        Uri.parse('$_baseUrl/api/verifikasitoken'),
        headers: {'Accept': 'application/json'},
        body: {
          'user_id': userId.toString(),
          'token': inputToken,
        },
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Token valid — lanjut ke halaman voting
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VotingPage()),
        );
      } else {
        setState(() {
          _isLoading = false;
          _isError   = true;
          _errorMsg  = data['message'] ?? 'Token tidak sesuai. Periksa kembali email Anda.';
        });
        _clearInput();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError   = true;
        _errorMsg  = 'Tidak dapat terhubung ke server.';
      });
      _clearInput();
    }
  }

  void _clearInput() {
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: _textPrimary),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          ),
        ),
        title: const Text('Verifikasi Token',
            style: TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: _borderColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ikon
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: _isError ? _errorBg : _lightOrange,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isError ? Icons.lock_reset_rounded : Icons.key_rounded,
                  size: 32,
                  color: _isError ? _errorRed : _primaryOrange,
                ),
              ),
              const SizedBox(height: 20),

              // Judul
              Text(
                _isError ? 'Token Tidak Valid' : 'Masukkan Token Pemilihan',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _isError
                    ? _errorMsg
                    : 'Masukkan kode 6 digit yang dikirimkan\nke email terdaftar Anda.',
                style: const TextStyle(
                    fontSize: 14, color: _textSecondary, height: 1.55),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Input token
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  return Container(
                    margin: EdgeInsets.only(right: i < 5 ? 8 : 0),
                    width: 44, height: 54,
                    child: TextFormField(
                      controller: _controllers[i],
                      focusNode:  _focusNodes[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      obscureText: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: _isError
                            ? _errorBg
                            : const Color(0xFFF9FAFB),
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _isError
                                  ? _errorRed.withOpacity(0.4)
                                  : _borderColor,
                              width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _isError
                                  ? _errorRed.withOpacity(0.4)
                                  : _borderColor,
                              width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _isError ? _errorRed : _primaryOrange,
                              width: 1.8),
                        ),
                      ),
                      onChanged: (v) => _onInput(v, i),
                      onFieldSubmitted: (_) => _verifikasi(),
                    ),
                  );
                }),
              ),

              // Pesan error inline
              if (_isError && _errorMsg.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 14, color: _errorRed),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(_errorMsg,
                        style: const TextStyle(
                            fontSize: 12, color: _errorRed),
                        textAlign: TextAlign.center),
                  ),
                ]),
              ],
              const SizedBox(height: 32),

              // Tombol verifikasi
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed:
                      (_tokenLengkap && !_isLoading) ? _verifikasi : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryOrange,
                    disabledBackgroundColor: const Color(0xFFE3C08E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white)))
                      : const Text('Verifikasi Token',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 14),

              // Tombol kembali
              SizedBox(
                width: double.infinity, height: 50,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.mail_outline_rounded),
                  label: const Text('Kembali ke Verifikasi Pemilihan',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const VerifikasiPemilihanPage()),
                    (route) => false,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textSecondary,
                    side: const BorderSide(color: _borderColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                Icon(Icons.lock_outline_rounded,
                    size: 13, color: _textSecondary),
                SizedBox(width: 5),
                Text('Token hanya berlaku 1 kali.',
                    style: TextStyle(fontSize: 11, color: _textSecondary)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  VotingPage  —  halaman pemilihan
// ═══════════════════════════════════════════════════════════════════════════
class VotingPage extends StatefulWidget {
  const VotingPage({super.key});

  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> with TickerProviderStateMixin {
  List<CalonFormatur> _daftarCalon = [];
  bool    _isLoadingData = true;
  String? _errorData;

  // Diambil dari server (kolom Pemilihan.maksimal_pilihan). 13 hanya fallback
  // jika data pemilihan gagal/tidak ditemukan, supaya app tetap bisa dipakai.
  int _maxPilihan = 13;

  final Set<int> _dipilih = {};
  bool _isSaving = false;
  bool _isSaved  = false;

  late AnimationController _savedCtrl;
  late Animation<double>   _savedScale;

  @override
  void initState() {
    super.initState();
    _savedCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _savedScale =
        CurvedAnimation(parent: _savedCtrl, curve: Curves.elasticOut);
    _fetchData();
  }

  @override
  void dispose() {
    _savedCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() { _isLoadingData = true; _errorData = null; });
    try {
      final results = await Future.wait([
        http.get(
          Uri.parse('$_baseUrl/api/kandidats'),
          headers: {'Accept': 'application/json'},
        ),
        http.get(
          Uri.parse('$_baseUrl/api/pemilihan'),
          headers: {'Accept': 'application/json'},
        ),
      ]);

      final kandidatResponse  = results[0];
      final pemilihanResponse = results[1];

      if (kandidatResponse.statusCode != 200) {
        setState(() {
          _errorData     = 'Gagal memuat data (${kandidatResponse.statusCode})';
          _isLoadingData = false;
        });
        return;
      }

      final decoded = jsonDecode(kandidatResponse.body);
      final list = decoded is Map ? decoded['data'] : decoded;
      final daftarCalon = (list as List)
          .map((e) => CalonFormatur.fromJson(e))
          .toList();

      // maksimal_pilihan diambil dari /api/pemilihan; jika gagal/kosong,
      // tetap pakai fallback default agar halaman tidak macet.
      int maxPilihan = _maxPilihan;
      if (pemilihanResponse.statusCode == 200) {
        final pemilihanDecoded = jsonDecode(pemilihanResponse.body);
        final pemilihanData = pemilihanDecoded is Map
            ? pemilihanDecoded['data']
            : null;
        final rawMax = pemilihanData is Map
            ? pemilihanData['maksimal_pilihan']
            : null;
        if (rawMax != null) {
          maxPilihan = int.tryParse(rawMax.toString()) ?? maxPilihan;
        }
      }

      setState(() {
        _daftarCalon   = daftarCalon;
        _maxPilihan    = maxPilihan;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _errorData     = 'Tidak dapat terhubung ke server.';
        _isLoadingData = false;
      });
    }
  }

  void _togglePilih(int id) {
    if (_isSaved) return;
    setState(() {
      if (_dipilih.contains(id)) {
        _dipilih.remove(id);
      } else if (_dipilih.length < _maxPilihan) {
        _dipilih.add(id);
        HapticFeedback.lightImpact();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.info_outline_rounded,
                color: Color(0xFF2F2E2E), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Anda sudah memilih $_maxPilihan calon. Batalkan salah satu untuk mengganti.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF2F2E2E)),
              ),
            ),
          ]),
          backgroundColor: const Color(0xFFEBE8E5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ));
      }
    });
  }

  Future<void> _simpanPilihan() async {
    if (_dipilih.length != _maxPilihan || _isSaving || _isSaved) return;

    final konfirmasi = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => _KonfirmasiDialog(
        dipilih: _dipilih.toList(),
        daftarCalon: _daftarCalon,
      ),
    );
    if (konfirmasi != true) return;

    setState(() => _isSaving = true);

    try {
      final prefs  = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/simpanpilihan'),
        headers: {'Accept': 'application/json'},
        body: {
          'user_id': userId?.toString() ?? '',
          'kandidat_ids': jsonEncode(_dipilih.toList()),
        },
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() { _isSaving = false; _isSaved = true; });
        _savedCtrl.forward();
        HapticFeedback.heavyImpact();

        // ── Catat notifikasi lokal: pilihan berhasil disimpan ────────────
        await NotificationService.addNotification(
          title: 'Pilihan Berhasil Disimpan',
          body:
              'Anda telah memilih $_maxPilihan calon formatur. Terima kasih telah berpartisipasi dalam pemilihan.',
        );
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['message'] ?? 'Gagal menyimpan pilihan.'),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tidak dapat terhubung ke server.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final kurang = _maxPilihan - _dipilih.length;

    return PopScope(
      canPop: _isSaved,
      onPopInvoked: (didPop) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selesaikan dan simpan pilihan terlebih dahulu.'),
          duration: Duration(seconds: 2),
        ));
      },
      child: Scaffold(
        backgroundColor: _bgPage,
        appBar: _buildAppBar(),
        body: _buildBodyContent(kurang),
        bottomNavigationBar: !_isSaved ? _buildBottomBar(kurang) : null,
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: _isSaved
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: _textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            )
          : const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Icon(Icons.how_to_vote_outlined,
                  color: _primaryOrange, size: 22),
            ),
      title: const Text('Pemilihan Formatur',
          style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600)),
      centerTitle: true,
      actions: [
        if (!_isSaved && !_isLoadingData)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _dipilih.length == _maxPilihan
                  ? _successBg
                  : _lightOrange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_dipilih.length}/$_maxPilihan',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _dipilih.length == _maxPilihan
                      ? _successGreen
                      : _primaryOrange),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 0.5, color: _borderColor),
      ),
    );
  }

  Widget _buildBodyContent(int kurang) {
    if (_isLoadingData) {
      return const Center(
          child: CircularProgressIndicator(color: _primaryOrange));
    }
    if (_errorData != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded,
                size: 52, color: _textSecondary),
            const SizedBox(height: 16),
            Text(_errorData!,
                style:
                    const TextStyle(color: _textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryOrange,
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
    if (_daftarCalon.isEmpty) {
      return const Center(
          child: Text('Data kandidat kosong.',
              style: TextStyle(color: _textSecondary)));
    }
    if (_isSaved) return _buildSavedView();
    return _buildBody(kurang);
  }

  Widget _buildBody(int kurang) {
    return Column(children: [
      _buildBanner(kurang),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: _daftarCalon.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _buildKartuCalon(_daftarCalon[i], i),
        ),
      ),
    ]);
  }

  Widget _buildBanner(int kurang) {
    final selesai = _dipilih.length == _maxPilihan;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _lightOrange,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryOrange, width: 0.5),
      ),
      child: Row(children: [
        Icon(
          selesai
              ? Icons.check_circle_outline_rounded
              : Icons.how_to_vote_outlined,
          size: 20, color: _primaryOrange,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            selesai
                ? 'Pilihan Anda sudah lengkap. Tekan Simpan Pilihan untuk mengonfirmasi.'
                : 'Pilih $kurang calon lagi dari daftar di bawah ini.',
            style: const TextStyle(
                fontSize: 13,
                color: _primaryOrange,
                height: 1.45,
                fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }

  Widget _buildKartuCalon(CalonFormatur calon, int index) {
    final dipilih = _dipilih.contains(calon.id);
    final urutan  = dipilih ? _dipilih.toList().indexOf(calon.id) + 1 : null;
    final penuh   = _dipilih.length >= _maxPilihan && !dipilih;
    final colors  = _colorForIndex(index);

    return GestureDetector(
      onTap: () => _togglePilih(calon.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: dipilih ? const Color(0xFFFFF7EB) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dipilih
                ? _primaryOrange
                : penuh
                    ? _borderColor.withOpacity(0.5)
                    : _borderColor,
            width: dipilih ? 1.5 : 0.5,
          ),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: calon.foto.isNotEmpty
                ? Image.network(
                    calon.fotoUrl,
                    width: 46, height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _avatarInisial(calon, dipilih, colors, 46),
                  )
                : _avatarInisial(calon, dipilih, colors, 46),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              calon.nama,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: penuh && !dipilih
                      ? _textSecondary.withOpacity(0.5)
                      : _textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          dipilih
              ? _buildBadgeUrutan(urutan!)
              : _buildCheckboxKosong(penuh),
        ]),
      ),
    );
  }

  Widget _avatarInisial(
      CalonFormatur calon, bool dipilih, _AvatarColor colors, double size) {
    return Container(
      width: size, height: size,
      color: dipilih ? _primaryOrange : colors.bg,
      child: Center(
        child: Text(
          calon.inisial,
          style: TextStyle(
              fontSize: size * 0.3,
              fontWeight: FontWeight.w700,
              color: dipilih ? Colors.white : colors.text),
        ),
      ),
    );
  }

  Widget _buildBadgeUrutan(int urutan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: _primaryOrange, borderRadius: BorderRadius.circular(20)),
      child: Text('$urutan/$_maxPilihan',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white)),
    );
  }

  Widget _buildCheckboxKosong(bool penuh) {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: penuh ? _borderColor.withOpacity(0.4) : _borderColor,
            width: 1.5),
        color: penuh ? const Color(0xFFF6F5F3) : Colors.transparent,
      ),
    );
  }

  Widget _buildBottomBar(int kurang) {
    final selesai = _dipilih.length == _maxPilihan;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _borderColor, width: 0.5)),
      ),
      child: SizedBox(
        width: double.infinity, height: 50,
        child: ElevatedButton(
          onPressed: selesai && !_isSaving ? _simpanPilihan : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                selesai ? _primaryOrange : const Color(0xFFEBE8E5),
            disabledBackgroundColor: selesai
                ? const Color(0xFFF8D29C)
                : const Color(0xFFEBE8E5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white)))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        selesai
                            ? Icons.save_outlined
                            : Icons.how_to_vote_outlined,
                        size: 18,
                        color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      selesai ? 'Simpan Pilihan' : 'Pilih $kurang calon lagi',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSavedView() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ScaleTransition(
            scale: _savedScale,
            child: Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                  color: _primaryOrange, shape: BoxShape.circle),
              child: const Icon(Icons.how_to_vote_rounded,
                  size: 38, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Pilihan Tersimpan!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            'Anda telah memilih $_maxPilihan calon formatur.\nTerima kasih telah berpartisipasi dalam pemilihan.',
            style: const TextStyle(
                fontSize: 14, color: _textSecondary, height: 1.65),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: _borderColor, width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('Calon yang dipilih:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary)),
              const SizedBox(height: 10),
              ..._dipilih.map((id) {
                final calon  = _daftarCalon.firstWhere((c) => c.id == id);
                final urutan = _dipilih.toList().indexOf(id) + 1;
                final colors =
                    _colorForIndex(_daftarCalon.indexOf(calon));
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Container(
                      width: 22, height: 22,
                      decoration: const BoxDecoration(
                          color: _lightOrange, shape: BoxShape.circle),
                      child: Center(
                        child: Text('$urutan',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _primaryOrange)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: calon.foto.isNotEmpty
                          ? Image.network(
                              calon.fotoUrl,
                              width: 24, height: 24,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _avatarInisial(calon, false, colors, 24),
                            )
                          : _avatarInisial(calon, false, colors, 24),
                    ),
                    const SizedBox(width: 8),
                    Text(calon.nama,
                        style: const TextStyle(
                            fontSize: 13, color: _textPrimary)),
                  ]),
                );
              }),
            ]),
          ),
          const SizedBox(height: 24),

          // Tombol kembali ke beranda
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
                (route) => false,
              ),
              icon: const Icon(Icons.home_rounded, size: 18),
              label: const Text('Kembali ke Beranda',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  _KonfirmasiDialog
// ═══════════════════════════════════════════════════════════════════════════
class _KonfirmasiDialog extends StatelessWidget {
  final List<int>           dipilih;
  final List<CalonFormatur> daftarCalon;

  const _KonfirmasiDialog({
    required this.dipilih,
    required this.daftarCalon,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: const BoxDecoration(
            color: _lightOrange,
            borderRadius: BorderRadius.only(
              topLeft:  Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(children: [
            Container(
              width: 52, height: 52,
              decoration: const BoxDecoration(
                  color: _primaryOrange, shape: BoxShape.circle),
              child: const Icon(Icons.how_to_vote_rounded,
                  size: 26, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text('Konfirmasi Pilihan',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
            const SizedBox(height: 6),
            const Text(
              'Pastikan pilihan Anda sudah benar.\nPilihan tidak dapat diubah setelah disimpan.',
              style: TextStyle(
                  fontSize: 12, color: _textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ]),
        ),

        // Daftar
        ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.35),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            shrinkWrap: true,
            itemCount: dipilih.length,
            itemBuilder: (_, i) {
              final calon  = daftarCalon.firstWhere((c) => c.id == dipilih[i]);
              final colors = _colorForIndex(daftarCalon.indexOf(calon));
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(
                    width: 26, height: 26,
                    decoration: const BoxDecoration(
                        color: _lightOrange, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _primaryOrange)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: calon.foto.isNotEmpty
                        ? Image.network(
                            calon.fotoUrl,
                            width: 32, height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 32, height: 32,
                              color: colors.bg,
                              child: Center(
                                child: Text(calon.inisial,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: colors.text)),
                              ),
                            ),
                          )
                        : Container(
                            width: 32, height: 32,
                            color: colors.bg,
                            child: Center(
                              child: Text(calon.inisial,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colors.text)),
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(calon.nama,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary)),
                  ),
                  const Icon(Icons.check_circle_rounded,
                      size: 18, color: _primaryOrange),
                ]),
              );
            },
          ),
        ),

        Container(
            height: 0.5,
            color: _borderColor,
            margin: const EdgeInsets.symmetric(horizontal: 16)),

        // Tombol
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Row(children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textSecondary,
                    side: const BorderSide(color: _borderColor, width: 1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Periksa Lagi',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ya, Simpan',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}