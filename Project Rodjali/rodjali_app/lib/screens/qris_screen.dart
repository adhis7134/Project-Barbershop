import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/qris_cubit.dart';
import '../core/format.dart';
import '../data/cashier_repository.dart';

class QrisScreen extends StatelessWidget {
  const QrisScreen({super.key, required this.transactionId});

  final int transactionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => QrisCubit(ctx.read<CashierRepository>(), transactionId)..load(),
      child: const _QrisView(),
    );
  }
}

class _QrisView extends StatelessWidget {
  const _QrisView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QrisCubit, QrisState>(
      listenWhen: (p, c) => c.error != null && p.error != c.error && c.status == QrisStatus.ready,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!), backgroundColor: Theme.of(context).colorScheme.error),
        );
      },
      builder: (context, state) {
        final cubit = context.read<QrisCubit>();
        final info = state.info;

        Widget body;
        if (info == null) {
          body = state.status == QrisStatus.failure
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.error ?? 'Gagal memuat QRIS.'),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: cubit.load, child: const Text('Coba lagi')),
                    ],
                  ),
                )
              : const Center(child: CircularProgressIndicator());
        } else {
          final confirming = state.status == QrisStatus.confirming;
          body = SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(info.merchant, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Ref. ${info.reference}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                Text(rupiah(info.amount),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _QrisImage(url: info.imageUrl),
                const SizedBox(height: 20),
                if (info.isPaid)
                  const Chip(
                    avatar: Icon(Icons.check_circle, color: Colors.green),
                    label: Text('LUNAS'),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: confirming ? null : () => _confirm(context, cubit, info.amount),
                      child: confirming
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Konfirmasi lunas'),
                    ),
                  ),
                const SizedBox(height: 8),
                if (info.isPaid)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Kembali ke antrean'),
                    ),
                  )
                else
                  Text('Konfirmasi hanya setelah pembayaran tampil masuk di aplikasi bank/e-wallet toko.',
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        }

        return Scaffold(appBar: AppBar(title: const Text('Pembayaran QRIS')), body: body);
      },
    );
  }

  Future<void> _confirm(BuildContext context, QrisCubit cubit, int amount) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi lunas?'),
        content: Text('Pastikan pembayaran ${rupiah(amount)} sudah masuk.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sudah masuk')),
        ],
      ),
    );
    if (ok == true) cubit.confirmPaid();
  }
}

class _QrisImage extends StatelessWidget {
  const _QrisImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    Widget placeholder(String text) => Container(
          width: 260,
          height: 260,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text, textAlign: TextAlign.center),
        );

    if (url.isEmpty) {
      return placeholder('Gambar QRIS belum diatur.\nIsi QRIS_IMAGE_URL di .env backend.');
    }
    return Image.network(
      url,
      width: 260,
      height: 260,
      fit: BoxFit.contain,
      loadingBuilder: (c, child, p) => p == null ? child : placeholder('Memuat QRIS…'),
      errorBuilder: (c, e, s) => placeholder('Gambar QRIS tidak bisa dimuat.\nPeriksa QRIS_IMAGE_URL.'),
    );
  }
}
