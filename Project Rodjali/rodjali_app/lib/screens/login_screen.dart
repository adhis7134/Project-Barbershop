import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth_bloc.dart';
import '../core/config.dart';
import '../core/shop_info.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'shop_info_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthLoginRequested(_email.text.trim(), _password.text));
  }

  Future<void> _openForgotPassword() async {
    final messenger = ScaffoldMessenger.of(context);
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => ForgotPasswordScreen(initialEmail: _email.text.trim())),
    );
    if (changed == true) {
      _password.clear();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Password berhasil diubah. Silakan masuk.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final loading = state is AuthInProgress;
    final error = state is Unauthenticated ? state.error : null;
    final theme = Theme.of(context);
    const info = ShopInfo.current;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PoleBar(),
                    const SizedBox(height: 20),
                    const Center(child: BrandLogo(width: 200)),
                    const SizedBox(height: 4),
                    Text(
                      info.tagline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Email', hintText: 'nama@email.com'),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Isi email yang valid' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          tooltip: _hidePassword ? 'Tampilkan password' : 'Sembunyikan password',
                          icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Isi password' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: loading ? null : _openForgotPassword,
                        child: const Text('Lupa password?'),
                      ),
                    ),
                    if (error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCEBEB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, size: 20, color: theme.colorScheme.error),
                            const SizedBox(width: 8),
                            Expanded(child: Text(error, style: const TextStyle(color: Color(0xFF791F1F)))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      onPressed: loading ? null : _submit,
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream),
                            )
                          : const Text('Masuk'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
                              ),
                      child: Text.rich(
                        TextSpan(
                          text: 'Belum punya akun? ',
                          style: const TextStyle(color: AppColors.muted),
                          children: [
                            TextSpan(
                              text: 'Daftar',
                              style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: loading
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => const ShopInfoScreen()),
                              ),
                      icon: const Icon(Icons.storefront_outlined),
                      label: Text('Info barbershop · Buka ${info.openTime}–${info.closeTime}'),
                    ),
                    // Alamat server hanya untuk pengembang, tidak tampil di aplikasi rilis.
                    if (kDebugMode) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Server: ${AppConfig.apiBaseUrl}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.faint),
                      ),
                    ],
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
