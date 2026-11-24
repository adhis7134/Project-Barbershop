import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth_bloc.dart';
import '../blocs/report_cubit.dart';
import '../core/format.dart';
import '../core/report_export.dart';
import '../core/report_share.dart';
import '../data/owner_repository.dart';
import '../models/models.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ReportCubit(ctx.read<OwnerRepository>())..load(),
      child: const _ReportView(),
    );
  }
}

class _ReportView extends StatelessWidget {
  const _ReportView();

  Future<void> _pickRange(BuildContext context, ReportState s) async {
    final cubit = context.read<ReportCubit>();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: DateTime(s.from.year, s.from.month, s.from.day),
        end: DateTime(s.to.year, s.to.month, s.to.day),
      ),
    );
    if (picked != null) {
      cubit.setRange(
        DateTime.utc(picked.start.year, picked.start.month, picked.start.day),
        DateTime.utc(picked.end.year, picked.end.month, picked.end.day),
      );
    }
  }

  Future<void> _export(BuildContext context, ReportState s) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      final book = buildReportWorkbook(s.report!, s.from, s.to);
      await saveOrShareWorkbook(book, reportFileName(s.from, s.to));
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: const Text('Gagal membuat file Excel.'), backgroundColor: errorColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportCubit, ReportState>(
      builder: (context, state) {
        final cubit = context.read<ReportCubit>();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Laporan Pendapatan'),
            actions: [
              IconButton(
                tooltip: 'Ekspor Excel',
                icon: const Icon(Icons.file_download_outlined),
                onPressed: (state.status == ReportStatus.ready && state.report != null)
                    ? () => _export(context, state)
                    : null,
              ),
              IconButton(tooltip: 'Muat ulang', icon: const Icon(Icons.refresh), onPressed: cubit.load),
              IconButton(
                tooltip: 'Keluar',
                icon: const Icon(Icons.logout),
                onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: OutlinedButton.icon(
                  onPressed: () => _pickRange(context, state),
                  icon: const Icon(Icons.date_range),
                  label: Text('${tanggalIndo(state.from)}  –  ${tanggalIndo(state.to)}'),
                ),
              ),
              Expanded(child: _body(context, state, cubit)),
            ],
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, ReportState state, ReportCubit cubit) {
    if (state.status == ReportStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == ReportStatus.failure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.error ?? 'Gagal memuat laporan.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: cubit.load, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }

    final r = state.report!;
    final theme = Theme.of(context);
    final maxService = r.perService.isEmpty ? 0 : r.perService.map((e) => e.total).reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total pendapatan (lunas)', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(rupiah(r.totalIncome), style: theme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('${r.totalTransactions} transaksi'),
              ],
            ),
          ),
        ),
        if (r.totalTransactions == 0)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Belum ada pembayaran lunas pada rentang tanggal ini.')),
          ),
        if (r.perService.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Per layanan', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final s in r.perService)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(s.service)),
                      Text('${rupiah(s.total)} · ${s.transactions}x'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: maxService == 0 ? 0 : s.total / maxService),
                ],
              ),
            ),
        ],
        if (r.perDay.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Per hari', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          for (final d in r.perDay) _DayRow(day: d),
        ],
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});

  final DayIncome day;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(tanggalIndo(day.date)),
      subtitle: Text('${day.transactions} transaksi'),
      trailing: Text(rupiah(day.total), style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
