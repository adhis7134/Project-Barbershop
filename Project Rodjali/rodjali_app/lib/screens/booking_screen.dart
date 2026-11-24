import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/booking_form_cubit.dart';
import '../core/config.dart';
import '../core/format.dart';
import '../core/slots.dart';
import '../data/customer_repository.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Booking baru ([editing] null) atau ganti jadwal ([editing] diisi). Menutup dengan `true` jika berhasil.
class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key, this.editing});

  final Booking? editing;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => BookingFormCubit(ctx.read<CustomerRepository>(), editing: editing)..load(),
      child: _BookingView(editing: editing),
    );
  }
}

class _BookingView extends StatelessWidget {
  const _BookingView({this.editing});

  final Booking? editing;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingFormCubit, BookingFormState>(
      listenWhen: (p, c) => c.status == BookingFormStatus.success && p.status != BookingFormStatus.success,
      listener: (context, state) => Navigator.of(context).pop(true),
      builder: (context, state) {
        final cubit = context.read<BookingFormCubit>();
        final ready = state.status != BookingFormStatus.loading && state.status != BookingFormStatus.loadFailed;
        return Scaffold(
          appBar: AppBar(title: Text(editing == null ? 'Booking baru' : 'Ganti jadwal')),
          body: CenteredBody(child: _body(context, state, cubit)),
          bottomNavigationBar: ready ? _SubmitBar(state: state, cubit: cubit, editing: editing != null) : null,
        );
      },
    );
  }

  Widget _body(BuildContext context, BookingFormState state, BookingFormCubit cubit) {
    if (state.status == BookingFormStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == BookingFormStatus.loadFailed) {
      return ErrorState(message: state.error ?? 'Data belum bisa dimuat. Coba lagi.', onRetry: cubit.load);
    }

    final submitting = state.status == BookingFormStatus.submitting;
    final service = state.service;
    final today = wibToday();
    final days = List.generate(14, (i) => today.add(Duration(days: i)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _Progress(step1: state.serviceId != null, step2: state.slot != null),
        const SizedBox(height: 20),
        const SectionTitle('1 · Pilih layanan'),
        if (state.services.isEmpty) const Text('Belum ada layanan yang tersedia.'),
        for (final s in state.services)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ServiceTile(
              service: s,
              selected: s.id == state.serviceId,
              // Saat ganti jadwal, layanan tidak bisa diubah.
              onTap: (editing != null || submitting) ? null : () => cubit.selectService(s.id),
            ),
          ),
        const SizedBox(height: 16),
        const SectionTitle('2 · Pilih tanggal dan jam'),
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _DateTile(
              date: days[i],
              isToday: i == 0,
              selected: days[i] == state.date,
              onTap: submitting ? null : () => cubit.selectDate(days[i]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _slots(context, state, cubit, service, submitting),
      ],
    );
  }

  Widget _slots(BuildContext context, BookingFormState state, BookingFormCubit cubit, Service? service, bool submitting) {
    if (service == null) {
      return const Text('Pilih layanan dulu untuk melihat jam kosong.', style: TextStyle(color: AppColors.muted));
    }
    final av = state.availability;
    if (av == null || state.slotsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final slots = buildSlots(
      date: state.date,
      open: av.open,
      close: av.close,
      durationMinutes: service.durationMinutes,
      taken: av.taken,
      now: wibNow(),
      stepMinutes: AppConfig.slotStepMinutes,
      ignore: cubit.ignoreSlot,
    );

    if (!slots.any((s) => s.available)) {
      return const Text('Tidak ada jam kosong pada tanggal ini. Coba tanggal lain.',
          style: TextStyle(color: AppColors.muted));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 480 ? 4 : 3;
            final w = (c.maxWidth - (cols - 1) * 8) / cols;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in slots)
                  SizedBox(
                    width: w,
                    child: _SlotTile(
                      label: hhmm(s.start),
                      available: s.available && !submitting,
                      struck: !s.available,
                      selected: state.slot == s.start,
                      onTap: () => cubit.selectSlot(s.start),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        const Text('Jam yang dicoret sudah terisi atau sudah lewat.',
            style: TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step1, required this.step2});

  final bool step1;
  final bool step2;

  @override
  Widget build(BuildContext context) {
    Widget bar(bool on) => Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: on ? AppColors.ink : AppColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
    return Row(children: [bar(step1), const SizedBox(width: 6), bar(step2)]);
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.selected, required this.onTap});

  final Service service;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? AppColors.ink : AppColors.line, width: selected ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${service.durationMinutes} menit',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ),
              Text(rupiah(service.price), style: const TextStyle(fontWeight: FontWeight.w600)),
              if (selected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: AppColors.ink, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.date, required this.isToday, required this.selected, required this.onTap});

  final DateTime date;
  final bool isToday;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // tanggalPendek -> "Sab 7 Nov"
    final p = tanggalPendek(date).split(' ');
    final fg = selected ? AppColors.cream : AppColors.ink;
    final sub = selected ? const Color(0xFFCFC9BD) : AppColors.muted;
    return Material(
      color: selected ? AppColors.ink : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? AppColors.ink : AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(isToday ? 'Hari ini' : p[0], style: TextStyle(color: sub, fontSize: 12)),
              const SizedBox(height: 2),
              Text(p[1], style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.label,
    required this.available,
    required this.struck,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool available;
  final bool struck;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg = selected ? Colors.white : (struck ? AppColors.faint : AppColors.ink);
    return Material(
      color: selected ? AppColors.red : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selected ? AppColors.red : AppColors.line),
      ),
      child: InkWell(
        onTap: available ? onTap : null,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 15,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              decoration: struck ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Ringkasan pilihan + tombol Pesan yang selalu terlihat di bawah layar.
class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.state, required this.cubit, required this.editing});

  final BookingFormState state;
  final BookingFormCubit cubit;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    final submitting = state.status == BookingFormStatus.submitting;
    final service = state.service;
    final slot = state.slot;
    final hasPick = service != null && slot != null;

    final summary = (service != null && slot != null)
        ? '${service.name} · ${tanggalIndo(state.date)}, ${hhmm(slot)}'
            '–${hhmm(slot.add(Duration(minutes: service.durationMinutes)))}'
        : 'Pilih layanan dan jam dulu.';
    final label = editing
        ? 'Simpan jadwal baru'
        : (service != null ? 'Pesan · ${rupiah(service.price)}' : 'Pesan');

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: CenteredBody(
          fitHeight: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.error != null) ...[
                  Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
                  const SizedBox(height: 6),
                ],
                Text(summary,
                    style: TextStyle(color: hasPick ? AppColors.ink : AppColors.muted, fontSize: 14)),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: (state.canSubmit && !submitting) ? cubit.submit : null,
                  child: submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream),
                        )
                      : Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
