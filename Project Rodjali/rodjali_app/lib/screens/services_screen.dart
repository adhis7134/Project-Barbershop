import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth_bloc.dart';
import '../blocs/services_cubit.dart';
import '../core/format.dart';
import '../data/owner_repository.dart';
import '../models/models.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ServicesCubit(ctx.read<OwnerRepository>())..load(),
      child: const _ServicesView(),
    );
  }
}

class _ServicesView extends StatelessWidget {
  const _ServicesView();

  Future<void> _openForm(BuildContext context, {Service? existing}) {
    final cubit = context.read<ServicesCubit>();
    return showDialog<void>(
      context: context,
      builder: (_) => _ServiceFormDialog(cubit: cubit, existing: existing),
    );
  }

  Future<void> _confirmRemove(BuildContext context, Service s) async {
    final cubit = context.read<ServicesCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus layanan?'),
        content: Text(
          '${s.name} akan dihapus. Jika sudah punya riwayat booking, layanan hanya dinonaktifkan '
          'supaya laporan tetap utuh.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya')),
        ],
      ),
    );
    if (ok == true) cubit.remove(s);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ServicesCubit, ServicesState>(
      listenWhen: (p, c) => p.messageSeq != c.messageSeq && c.message != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(state.message!),
            backgroundColor: state.messageIsError ? Theme.of(context).colorScheme.error : null,
          ));
      },
      child: BlocBuilder<ServicesCubit, ServicesState>(
        builder: (context, state) {
          final cubit = context.read<ServicesCubit>();
          return Scaffold(
            appBar: AppBar(
              title: const Text('Kelola Layanan'),
              actions: [
                IconButton(tooltip: 'Muat ulang', icon: const Icon(Icons.refresh), onPressed: cubit.load),
                IconButton(
                  tooltip: 'Keluar',
                  icon: const Icon(Icons.logout),
                  onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Layanan baru'),
            ),
            body: _body(context, state, cubit),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, ServicesState state, ServicesCubit cubit) {
    if (state.status == ServicesStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == ServicesStatus.failure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.error ?? 'Gagal memuat layanan.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: cubit.load, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }
    if (state.services.isEmpty) {
      return const Center(child: Text('Belum ada layanan. Tekan "Layanan baru".'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      itemCount: state.services.length,
      itemBuilder: (context, i) {
        final s = state.services[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(s.name, style: s.isActive ? null : const TextStyle(decoration: TextDecoration.lineThrough)),
            subtitle: Text('${rupiah(s.price)} · ${s.durationMinutes} menit${s.isActive ? '' : ' · nonaktif'}'),
            onTap: state.busy ? null : () => _openForm(context, existing: s),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: s.isActive,
                  onChanged: state.busy ? null : (v) => cubit.setActive(s, v),
                ),
                IconButton(
                  tooltip: 'Hapus',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: state.busy ? null : () => _confirmRemove(context, s),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServiceFormDialog extends StatefulWidget {
  const _ServiceFormDialog({required this.cubit, this.existing});

  final ServicesCubit cubit;
  final Service? existing;

  @override
  State<_ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<_ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _price = TextEditingController(text: widget.existing?.price.toString() ?? '');
  late final _duration = TextEditingController(text: widget.existing?.durationMinutes.toString() ?? '30');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final err = await widget.cubit.save(
      existing: widget.existing,
      name: _name.text.trim(),
      price: int.parse(_price.text),
      duration: int.parse(_duration.text),
    );
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Layanan baru' : 'Ubah layanan'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama layanan'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Isi nama layanan' : null,
              ),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                validator: (v) => (v == null || v.isEmpty) ? 'Isi harga' : null,
              ),
              TextFormField(
                controller: _duration,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Durasi (menit)'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 5 || n > 480) return 'Isi 5 sampai 480 menit';
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Batal')),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
