import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthRegisterRequested(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      // Setelah daftar berhasil, tutup layar ini; beranda pelanggan sudah tampil di bawahnya.
      listenWhen: (p, c) => c is Authenticated,
      listener: (context, state) => Navigator.of(context).popUntil((r) => r.isFirst),
      builder: (context, state) {
        final loading = state is AuthInProgress;
        final error = state is Unauthenticated ? state.error : null;

        return Scaffold(
          appBar: AppBar(title: const Text('Daftar Pelanggan')),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Isi nama' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                          validator: (v) => (v == null || !v.contains('@')) ? 'Isi email yang valid' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                              labelText: 'No. HP (opsional)', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          obscureText: _hidePassword,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password (min. 6 karakter)',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _hidePassword = !_hidePassword),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: loading ? null : _submit,
                          child: loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Daftar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
