import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/reset_password_cubit.dart';
import '../data/auth_repository.dart';

/// Lupa password dalam dua langkah: (1) isi email, (2) isi kode dari email + password baru.
/// Menutup dengan `true` jika password berhasil diubah.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ResetPasswordCubit(ctx.read<AuthRepository>()),
      child: _ForgotPasswordView(initialEmail: initialEmail),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _emailKey = GlobalKey<FormState>();
  final _codeKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hide = true;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _sendCode() {
    if (!_emailKey.currentState!.validate()) return;
    context.read<ResetPasswordCubit>().sendCode(_email.text.trim());
  }

  void _reset() {
    if (!_codeKey.currentState!.validate()) return;
    context.read<ResetPasswordCubit>().reset(code: _code.text.trim(), password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ResetPasswordCubit, ResetState>(
      listenWhen: (p, c) => c.step == ResetStep.done && p.step != ResetStep.done,
      listener: (context, state) => Navigator.of(context).pop(true),
      builder: (context, state) {
        final cubit = context.read<ResetPasswordCubit>();
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(title: const Text('Lupa Password')),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: state.step == ResetStep.email
                      ? _emailStep(context, state, theme)
                      : _codeStep(context, state, cubit, theme),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emailStep(BuildContext context, ResetState state, ThemeData theme) {
    return Form(
      key: _emailKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Masukkan email akun Anda. Kami akan mengirim kode 6 digit untuk membuat password baru.',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            onFieldSubmitted: (_) => _sendCode(),
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            validator: (v) => (v == null || !v.contains('@')) ? 'Isi email yang valid' : null,
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(state.error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: state.busy ? null : _sendCode,
            child: state.busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Kirim kode'),
          ),
        ],
      ),
    );
  }

  Widget _codeStep(BuildContext context, ResetState state, ResetPasswordCubit cubit, ThemeData theme) {
    return Form(
      key: _codeKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.notice != null) Text(state.notice!, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text('Cek juga folder spam. Kode baru bisa diminta setelah 1 menit.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          TextFormField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Kode 6 digit', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().length != 6) ? 'Isi 6 digit kode dari email' : null,
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _password,
            obscureText: _hide,
            decoration: InputDecoration(
              labelText: 'Password baru (min. 6 karakter)',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _hide = !_hide),
              ),
            ),
            validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirm,
            obscureText: _hide,
            onFieldSubmitted: (_) => _reset(),
            decoration: const InputDecoration(labelText: 'Ulangi password baru', border: OutlineInputBorder()),
            validator: (v) => v != _password.text ? 'Password tidak sama' : null,
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(state.error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: state.busy ? null : _reset,
            child: state.busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Ubah password'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: state.busy ? null : () => cubit.sendCode(state.email),
            child: const Text('Kirim ulang kode'),
          ),
          TextButton(
            onPressed: state.busy ? null : cubit.backToEmail,
            child: const Text('Ganti email'),
          ),
        ],
      ),
    );
  }
}
