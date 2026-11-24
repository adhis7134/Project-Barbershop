import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth_bloc.dart';
import '../blocs/my_bookings_bloc.dart';
import '../core/config.dart';
import '../core/format.dart';
import '../data/customer_repository.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'booking_screen.dart';
import 'shop_info_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => MyBookingsBloc(ctx.read<CustomerRepository>())..add(MyBookingsStarted()),
      child: _HomeView(user: user),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView({required this.user});

  final AppUser user;

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  int _tab = 0;

  void _snack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ));
  }

  Future<void> _openForm({Booking? editing}) async {
    final bloc = context.read<MyBookingsBloc>();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => BookingScreen(editing: editing)),
    );
    if (saved == true) {
      bloc.add(MyBookingsRefreshed());
      if (mounted) _snack(editing == null ? 'Booking berhasil dibuat.' : 'Jadwal berhasil diganti.');
    }
  }

  Future<void> _confirmCancel(Booking b) async {
    final bloc = context.read<MyBookingsBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan booking?'),
        content: Text('${tanggalIndo(b.startAt)}, ${hhmm(b.startAt)} akan dibatalkan dan slotnya dibuka lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, batalkan'),
          ),
        ],
      ),
    );
    if (ok == true) bloc.add(MyBookingCancelRequested(b));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MyBookingsBloc, MyBookingsState>(
      listenWhen: (p, c) => p.messageSeq != c.messageSeq && c.message != null,
      listener: (context, state) => _snack(state.message!, error: state.messageIsError),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tab == 0 ? 'Beranda' : 'Akun'),
          actions: [
            if (_tab == 0)
              IconButton(
                tooltip: 'Muat ulang',
                icon: const Icon(Icons.refresh),
                onPressed: () => context.read<MyBookingsBloc>().add(MyBookingsRefreshed()),
              ),
          ],
        ),
        body: CenteredBody(
          child: _tab == 0
              ? BlocBuilder<MyBookingsBloc, MyBookingsState>(builder: (context, state) => _bookingsTab(state))
              : _AccountTab(user: widget.user),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Akun'),
          ],
        ),
      ),
    );
  }

  Widget _bookingsTab(MyBookingsState state) {
    final bloc = context.read<MyBookingsBloc>();
    final theme = Theme.of(context);

    if (state.status == MyBookingsStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == MyBookingsStatus.failure) {
      return ErrorState(
        message: state.error ?? 'Booking belum bisa dimuat. Periksa koneksi, lalu coba lagi.',
        onRetry: () => bloc.add(MyBookingsStarted()),
      );
    }

    bool isActive(Booking b) => b.status == 'dipesan' || b.status == 'dikerjakan';
    final active = state.bookings.where(isActive).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));
    final history = state.bookings.where((b) => !isActive(b)).toList()..sort((a, b) => b.startAt.compareTo(a.startAt));
    final firstName = widget.user.name.trim().split(' ').first;

    Widget card(Booking b, {required bool hero}) => _ActiveCard(
          booking: b,
          hero: hero,
          busy: state.busyId == b.id,
          disabled: state.busyId != null,
          onReschedule: () => _openForm(editing: b),
          onCancel: () => _confirmCancel(b),
        );

    return RefreshIndicator(
      onRefresh: () async {
        bloc.add(MyBookingsRefreshed());
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text('Halo, $firstName', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            active.isEmpty ? 'Belum ada jadwal. Yuk, pesan potong rambut.' : 'Ini jadwal kamu berikutnya.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          if (active.isNotEmpty) card(active.first, hero: true) else const _EmptyHero(),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Booking baru'),
            ),
          ),
          if (active.length > 1) ...[
            const SizedBox(height: 24),
            const SectionTitle('Jadwal lainnya'),
            for (final b in active.skip(1)) ...[card(b, hero: false), const SizedBox(height: 10)],
          ],
          if (history.isNotEmpty) ...[
            const SizedBox(height: 24),
            const SectionTitle('Riwayat'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < history.length; i++) ...[
                    if (i > 0) const Divider(),
                    _HistoryRow(booking: history[i]),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyHero extends StatelessWidget {
  const _EmptyHero();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            const Icon(Icons.content_cut, size: 32, color: AppColors.muted),
            const SizedBox(height: 10),
            Text('Belum ada jadwal',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Pilih layanan dan jam yang masih kosong.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({
    required this.booking,
    required this.hero,
    required this.busy,
    required this.disabled,
    required this.onReschedule,
    required this.onCancel,
  });

  final Booking booking;
  final bool hero;
  final bool busy;
  final bool disabled;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = customerStatus(booking);
    final service = booking.service;
    final fg = hero ? AppColors.cream : AppColors.ink;
    final sub = hero ? const Color(0xFFCFC9BD) : AppColors.muted;
    final outline = hero ? const Color(0xFF8A857B) : AppColors.line;
    final cancelColor = hero ? const Color(0xFFF09595) : Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hero ? AppColors.ink : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: hero ? null : Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(hero ? 'Booking berikutnya' : tanggalIndo(booking.startAt),
                  style: TextStyle(color: sub, fontSize: 13))),
              if (busy) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                ),
                const SizedBox(width: 8),
              ],
              StatusPill(label, tone, onDark: hero),
            ],
          ),
          const SizedBox(height: 8),
          Text(hhmm(booking.startAt), style: TextStyle(color: fg, fontSize: 32, fontWeight: FontWeight.w600)),
          Text(
            [
              if (hero) tanggalIndo(booking.startAt),
              if (service != null) service.name,
              if (service != null) rupiah(service.price),
            ].join(' · '),
            style: TextStyle(color: sub, fontSize: 14),
          ),
          if (booking.status == 'dipesan') ...[
            const SizedBox(height: 14),
            if (booking.canChange)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: fg, side: BorderSide(color: outline)),
                      onPressed: disabled ? null : onReschedule,
                      child: const Text('Ganti jadwal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: cancelColor, side: BorderSide(color: outline)),
                      onPressed: disabled ? null : onCancel,
                      child: const Text('Batalkan'),
                    ),
                  ),
                ],
              )
            else
              Text(
                'Tidak bisa diubah lagi (batas ${AppConfig.cancelMinHours} jam sebelum jadwal).',
                style: TextStyle(color: sub, fontSize: 12),
              ),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = customerStatus(booking);
    final name = booking.service?.name ?? 'Layanan';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('${tanggalIndo(booking.startAt)} · ${hhmm(booking.startAt)}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
            ),
          ),
          StatusPill(label, tone),
        ],
      ),
    );
  }
}

class _AccountTab extends StatelessWidget {
  const _AccountTab({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = user.name.trim().isEmpty ? '?' : user.name.trim()[0].toUpperCase();
    final phone = user.phone;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.navy,
                  child: Text(initial,
                      style: const TextStyle(color: AppColors.cream, fontSize: 20, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text(user.email, style: const TextStyle(color: AppColors.muted)),
                      if (phone != null && phone.isNotEmpty)
                        Text(phone, style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Info barbershop'),
            subtitle: const Text('Jam buka, cara booking, kontak'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ShopInfoScreen()),
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
          icon: const Icon(Icons.logout),
          label: const Text('Keluar'),
        ),
      ],
    );
  }
}
