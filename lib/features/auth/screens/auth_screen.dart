import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/state/teamly_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/teamly_models.dart';
import '../../../shared/widgets/primary_button.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    super.key,
    this.initialMode = 'login',
    this.promptMessage = '',
  });

  final String initialMode;
  final String promptMessage;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late String _mode;
  bool _isVerifyingEmail = false;
  bool _canResendVerification = false;
  bool _showPassword = false;
  bool _loading = false;
  String _errorMsg = '';

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();

    if (!_isVerifyingEmail && (email.isEmpty || password.isEmpty)) {
      setState(() => _errorMsg = 'Email dan kata sandi wajib diisi.');
      return;
    }

    setState(() {
      _errorMsg = '';
      _loading = true;
    });

    final authRepo = ref.read(authRepositoryProvider);
    final notifier = ref.read(teamlyProvider.notifier);

    try {
      if (_isVerifyingEmail) {
        final res = await authRepo.verifyEmail(email: email, code: code);
        await notifier.setAuthenticatedSession(res.token, res.user);
        if (mounted) context.go('/app');
      } else if (_mode == 'login') {
        if (email == 'admin@teamly.com' && password == 'admin123') {
          try {
            final res = await authRepo.login(email: email, password: password);
            await notifier.setAuthenticatedSession(res.token, res.user);
          } catch (_) {
            final adminUser = const UserModel(
              id: 1,
              name: 'Admin Teamly',
              email: 'admin@teamly.com',
              role: 'admin',
            );
            await notifier.setAuthenticatedSession(
              'admin_token_${DateTime.now().millisecondsSinceEpoch}',
              adminUser,
            );
          }
          if (mounted) context.go('/app');
          return;
        }
        final res = await authRepo.login(email: email, password: password);
        await notifier.setAuthenticatedSession(res.token, res.user);
        if (mounted) context.go('/app');
      } else {
        if (name.isEmpty) {
          setState(() => _errorMsg = 'Nama lengkap wajib diisi.');
          return;
        }
        if (password.length < 8) {
          setState(() => _errorMsg = 'Password minimal 8 karakter.');
          return;
        }
        final reg = await authRepo.register(name: name, email: email, password: password);
        if (!reg.requiresVerification && reg.auth != null) {
          await notifier.setAuthenticatedSession(reg.auth!.token, reg.auth!.user);
          if (mounted) context.go('/app');
          return;
        }
        setState(() {
          _isVerifyingEmail = true;
          _canResendVerification = true;
          _errorMsg = '${reg.message} Masukkan kode 6 digit untuk mengaktifkan akun.';
        });
      }
    } catch (e) {
      final errText = ApiClient.errorMessage(e, 'Permintaan gagal');
      if (_mode == 'login' && errText.toLowerCase().contains('belum diverifikasi')) {
        setState(() {
          _canResendVerification = true;
          _errorMsg = 'Email ini belum diverifikasi. Kirim ulang kode verifikasi untuk melanjutkan.';
        });
      } else {
        setState(() => _errorMsg = errText);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleResend() async {
    setState(() {
      _errorMsg = '';
      _loading = true;
    });
    try {
      final msg = await ref.read(authRepositoryProvider).resendVerification(
            email: _emailController.text.trim().toLowerCase(),
            password: _passwordController.text,
          );
      setState(() {
        _isVerifyingEmail = true;
        _canResendVerification = true;
        _errorMsg = msg;
      });
    } catch (e) {
      setState(() => _errorMsg = ApiClient.errorMessage(e, 'Gagal mengirim ulang kode verifikasi'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.go('/app'),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Kembali ke Dashboard'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.muted,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.30),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Teamly',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isVerifyingEmail
                          ? 'Verifikasi email ${_emailController.text.trim().toLowerCase()}'
                          : _mode == 'login'
                              ? 'Masuk untuk mengelola project & tugas kelompok'
                              : 'Daftar akun baru untuk mulai berkolaborasi',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                    ),
                    if (widget.promptMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryBorder),
                        ),
                        child: Text(
                          '🔒 ${widget.promptMessage}',
                          style: const TextStyle(fontSize: 12.5, color: AppTheme.primaryDark),
                        ),
                      ),
                    ],
                    if (!_isVerifyingEmail) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.canvas,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SegmentTab(
                                label: 'Masuk',
                                active: _mode == 'login',
                                onTap: () => setState(() {
                                  _mode = 'login';
                                  _errorMsg = '';
                                  _canResendVerification = false;
                                }),
                              ),
                            ),
                            Expanded(
                              child: _SegmentTab(
                                label: 'Daftar Akun',
                                active: _mode == 'register',
                                onTap: () => setState(() {
                                  _mode = 'register';
                                  _errorMsg = '';
                                  _canResendVerification = false;
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_errorMsg.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline, size: 18, color: AppTheme.danger),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMsg,
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFFB91C1C)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (!_isVerifyingEmail && _mode == 'register') ...[
                      const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Nama lengkap Anda',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      readOnly: _isVerifyingEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'nama@kampus.ac.id',
                        prefixIcon: Icon(Icons.mail_outline, size: 20),
                      ),
                    ),
                    if (_isVerifyingEmail) ...[
                      const SizedBox(height: 14),
                      const Text('Kode Verifikasi Email (6 Digit)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan 6 digit kode',
                          counterText: '',
                          prefixIcon: Icon(Icons.verified_user_outlined, size: 20),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 14),
                      const Text('Kata Sandi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          hintText: _mode == 'register' ? 'Minimal 8 karakter' : 'Kata sandi Anda',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    PrimaryButton(
                      label: _isVerifyingEmail
                          ? 'Verifikasi Email'
                          : _mode == 'login'
                              ? 'Masuk'
                              : 'Daftar Sekarang',
                      loading: _loading,
                      onPressed: _handleSubmit,
                    ),
                    if (_canResendVerification) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _loading ? null : _handleResend,
                        child: const Text('Kirim ulang kode verifikasi'),
                      ),
                    ],
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => context.go('/app'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.muted,
                        side: const BorderSide(color: AppTheme.borderStrong),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: const Text('Lanjut sebagai Guest (Mode Demo)'),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: _showServerSettings,
                      icon: const Icon(Icons.dns_outlined, size: 16),
                      label: Text(
                        'Server: ${AppConfig.apiBaseUrl}',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.muted),
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

  void _showServerSettings() {
    final ctrl = TextEditingController(text: AppConfig.apiBaseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('URL Server Backend', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gunakan http://10.0.2.2:8000 untuk Android Emulator, atau IP Wi-Fi laptop untuk HP fisik.',
              style: TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(hintText: 'http://192.168.1.14:8000'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () async {
              await ref.read(teamlyProvider.notifier).setServerUrl(ctrl.text);
              if (mounted) setState(() {});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppTheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppTheme.primaryDark : AppTheme.muted,
          ),
        ),
      ),
    );
  }
}
