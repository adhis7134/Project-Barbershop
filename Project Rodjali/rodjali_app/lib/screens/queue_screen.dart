import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth_bloc.dart';
import '../blocs/queue_bloc.dart';
import '../core/format.dart';
import '../core/queue_filter.dart';
import '../data/cashier_repository.dart';
import '../models/models.dart';
import 'qris_screen.dart';
import 'walk_in_screen.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => QueueBloc(ctx.read<CashierRepository>())..add(QueueStarted()),
      child: _QueueView(user: user),
    );
  }
}

class _QueueView extends StatelessWidget {
  const _QueueView({required this.user});

  final AppUser user;

  Future<void> _openQris(BuildContext context, int transactionId) async {
    final bloc = context.read<QueueBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(builder: (_) => QrisScreen(transactionId: transactionId)),
    );
    bloc.add(QueueRefreshed());
  }

  Future<void> _openWalkIn(BuildContext context) async {
    final bloc = context.read<QueueBloc>();
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const WalkInScreen()),
    );
    if (added == true) bloc.add(QueueRefreshed());
  }

  Future<void> _pickDate(BuildContext context, DateTime current) async {
    final bloc = context.read<QueueBloc>();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) bloc.add(QueueDateChanged(DateTime.utc(picked.year, picked.month, picked.day)));
  }

  Future<bool> _confirm(BuildContext context, String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya')),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<QueueBloc, QueueState>(
          listenWhen: (p, c) => p.messageSeq != c.messageSeq && c.message != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(state.message!),
                backgroundColor: state.messageIsError ? Theme.of(context).colorScheme.error : null,
              ));
          },
        ),
        BlocListener<QueueBloc, QueueState>(
          listenWhen: (p, c) => c.qrisTransactionId != null && p.qrisTransactionId != c.qrisTransactionId,
          listener: (context, state) {
            final id = state.qrisTransactionId!;
            context.read<QueueBloc>().add(QueueQrisHandled());
            _openQris(context, id);
          },
        ),
      ],
      child: BlocBuilder<QueueBloc, QueueState>(
        builder: (context, state) {
          final bloc = context.read<QueueBloc>();
          final active = activeQueue(state.bookings);
          final done = doneQueue(state.bookings);
          final ready = state.status == QueueStatus.ready;
          return DefaultTabController(
            length: 2,
            child: Scaffold(
            appBar: AppBar(
              title: const Text('Antrean Kasir'),
              bottom: TabBar(
                tabs: [
                  Tab(text: ready ? 'Aktif (${active.length})' : 'Aktif'),
                  Tab(text: ready ? 'Selesai (${done.length})' : 'Selesai'),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Muat ulang',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => bloc.add(QueueRefreshed()),
                ),
                PopupMenuButton<String>(
                  onSelected: (_) => context.read<AuthBloc>().add(AuthLogoutRequested()),
                  itemBuilder: (_) => [
                    PopupMenuItem(enabled: false, child: Text('${user.name} (${user.role})')),
                    const PopupMenuItem(value: 'logout', child: Text('Keluar')),
                  ],
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _openWalkIn(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Walk-in'),
            ),
            body: Column(
              children: [
                _DateBar(
                  date: state.date,
                  onPrev: () => bloc.add(QueueDateChanged(state.date.subtract(const Duration(days: 1)))),
                  onNext: () => bloc.add(QueueDateChanged(state.date.add(const Duration(days: 1)))),
                  onPick: () => _pickDate(context, state.date),
                ),
                Expanded(child: _body(context, state, active, done)),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, QueueState state, List<Booking> active, List<Booking> done) {
    final bloc = context.read<QueueBloc>();

    if (state.status == QueueStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == QueueStatus.failure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.error ?? 'Gagal memuat antrean.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => bloc.add(QueueRefreshed()), child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      children: [
        _list(
          context,
          state,
          active,
          state.bookings.isEmpty ? 'Belum ada antrean pada tanggal ini.' : 'Tidak ada antrean aktif.',
        ),
        _list(context, state, done, 'Belum ada yang selesai, batal, atau tidak datang.'),
      ],
    );
  }

  Widget _list(BuildContext context, QueueState state, List<Booking> items, String emptyText) {
    final bloc = context.read<QueueBloc>();

    return RefreshIndicator(
      onRefresh: () async {
        bloc.add(QueueRefreshed());
      },
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(child: Text(emptyText)),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final b = items[i];
                return _BookingCard(
                  booking: b,
                  disabled: state.busyId != null,
                  busy: state.busyId == b.id,
                  onStart: () => bloc.add(QueueActionRequested(b, QueueAction.start)),
                  onComplete: () => bloc.add(QueueActionRequested(b, QueueAction.complete)),
                  onNoShow: () async {
                    if (await _confirm(context, 'Tandai tidak datang?',
                        '${b.customerName} akan ditandai tidak datang dan slotnya dibuka lagi.')) {
                      bloc.add(QueueActionRequested(b, QueueAction.noShow));
                    }
                  },
                  onPay: () => _openQris(context, b.transaction!.id),
                );
              },
            ),
    );
  }
}

class _DateBar extends StatelessWidget {
  const _DateBar({required this.date, required this.onPrev, required this.onNext, required this.onPick});

  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(tanggalIndo(date)),
            ),
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.disabled,
    required this.busy,
    required this.onStart,
    required this.onComplete,
    required this.onNoShow,
    required this.onPay,
  });

  final Booking booking;
  final bool disabled;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onNoShow;
  final VoidCallback onPay;

  (String, Color) _statusChip() {
    switch (booking.status) {
      case 'dipesan':
        return ('Dipesan', Colors.blue);
      case 'dikerjakan':
        return ('Dikerjakan', Colors.orange);
      case 'selesai':
        return booking.transaction?.isPaid == true ? ('Lunas', Colors.green) : ('Belum dibayar', Colors.amber.shade800);
      case 'dibatalkan':
        return ('Dibatalkan', Colors.grey);
      case 'tidak_datang':
        return ('Tidak datang', Colors.red);
      default:
        return (booking.status, Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusChip();
    final service = booking.service;
    final actions = <Widget>[];

    if (booking.status == 'dipesan') {
      actions.addAll([
        TextButton(onPressed: disabled ? null : onNoShow, child: const Text('Tidak datang')),
        FilledButton(onPressed: disabled ? null : onStart, child: const Text('Mulai')),
      ]);
    } else if (booking.status == 'dikerjakan') {
      actions.add(FilledButton(onPressed: disabled ? null : onComplete, child: const Text('Selesai')));
    } else if (booking.status == 'selesai' && booking.transaction != null && !booking.transaction!.isPaid) {
      actions.add(FilledButton.icon(
        onPressed: disabled ? null : onPay,
        icon: const Icon(Icons.qr_code_2),
        label: const Text('Tagih QRIS'),
      ));
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${hhmm(booking.startAt)}–${hhmm(booking.endAt)}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                if (booking.isWalkIn) const Chip(label: Text('Walk-in'), visualDensity: VisualDensity.compact),
                const Spacer(),
                Chip(
                  label: Text(label, style: const TextStyle(color: Colors.white)),
                  backgroundColor: color,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(booking.customerName, style: Theme.of(context).textTheme.bodyLarge),
            if (service != null) Text('${service.name} · ${rupiah(service.price)}'),
            if (booking.customerPhone != null && booking.customerPhone!.isNotEmpty) Text(booking.customerPhone!),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (busy) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ...actions,
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
