import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/walk_in_cubit.dart';
import '../core/config.dart';
import '../core/format.dart';
import '../core/slots.dart';
import '../data/cashier_repository.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class WalkInScreen extends StatelessWidget {
  const WalkInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => WalkInCubit(ctx.read<CashierRepository>())..load(),
      child: const _WalkInView(),
    );
  }
}

class _WalkInView extends StatefulWidget {
  const _WalkInView();

  @override
  State<_WalkInView> createState() => _WalkInViewState();
}

class _WalkInViewState extends State<_WalkInView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalkInCubit, WalkInState>(
      listenWhen: (p, c) => p.status != c.status && c.status == WalkInStatus.success,
      listener: (context, state) => Navigator.of(context).pop(true),
      builder: (context, state) {
        final cubit = context.read<WalkInCubit>();
        final submitting = state.status == WalkInStatus.submitting;

        return Scaffold(
          appBar: AppBar(title: const Text('Pelanggan Walk-in')),
          body: switch (state.status) {
            WalkInStatus.loading => const Center(child: CircularProgressIndicator()),
            WalkInStatus.loadFailed => Center(
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
              ),
            _ => _FormBody(
                formKey: _formKey,
                nameCtrl: _name,
                phoneCtrl: _phone,
                state: state,
                cubit: cubit,
                submitting: submitting,
              ),
          },
        );
      },
    );
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.formKey,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.state,
    required this.cubit,
    required this.submitting,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final WalkInState state;
  final WalkInCubit cubit;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final service = state.selectedService;
    final av = state.availability;

    // Hitung daftar slot berdasarkan layanan yang dipilih
    List<SlotOption>? slots;
    if (service != null && av != null && !state.slotsLoading) {
      slots = buildSlots(
        date: wibToday(),
        open: av.open,
        close: av.close,
        durationMinutes: service.durationMinutes,
        taken: av.taken,
        now: wibNow(),
        stepMinutes: AppConfig.slotStepMinutes,
      );
    }

    final hasAvailableSlot = slots?.any((s) => s.available) ?? false;

    // Ringkasan slot terpilih untuk bottom bar
    final selectedSlot = state.selectedSlot;
    String summary;
    if (service != null && selectedSlot != null) {
      final endSlot = selectedSlot.add(Duration(minutes: service.durationMinutes));
      summary = '${service.name} · ${hhmm(selectedSlot)}–${hhmm(endSlot)}';
    } else if (service != null) {
      summary = 'Pilih jam atau langsung tambahkan ke antrian terakhir';
    } else {
      summary = 'Isi nama, layanan, lalu pilih jam (opsional).';
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Nama & HP ──
                  TextFormField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama pelanggan',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Isi nama pelanggan' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'No. HP (opsional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Pilih Layanan ──
                  DropdownButtonFormField<int>(
                    value: state.selectedServiceId,
                    decoration: const InputDecoration(labelText: 'Layanan', border: OutlineInputBorder()),
                    items: [
                      for (final s in state.services)
                        DropdownMenuItem(
                          value: s.id,
                          child: Text('${s.name} · ${rupiah(s.price)} · ${s.durationMinutes} mnt'),
                        ),
                    ],
                    onChanged: submitting ? null : cubit.select,
                    validator: (v) => v == null ? 'Pilih layanan' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Pilih Jam (opsional) ──
                  if (service != null) ...[
                    const _SectionLabel('Pilih jam (opsional)'),
                    const SizedBox(height: 4),
                    Text(
                      'Kosongkan agar pelanggan otomatis masuk setelah antrian terakhir.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    if (state.slotsLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (slots != null && !hasAvailableSlot)
                      Text(
                        'Tidak ada jam kosong hari ini.',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      )
                    else if (slots != null)
                      _SlotGrid(
                        slots: slots,
                        selectedSlot: state.selectedSlot,
                        submitting: submitting,
                        onTap: cubit.selectSlot,
                      ),
                  ],

                  // ── Pesan Error ──
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // ── Bottom Bar ──
        _BottomBar(
          summary: summary,
          submitting: submitting,
          canSubmit: state.selectedServiceId != null,
          onSubmit: () {
            if (formKey.currentState!.validate()) {
              cubit.submit(name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim());
            }
          },
        ),
      ],
    );
  }
}

// ── Judul seksi ───────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }
}

// ── Grid slot jam ─────────────────────────────────────────────────────────────
class _SlotGrid extends StatelessWidget {
  const _SlotGrid({
    required this.slots,
    required this.selectedSlot,
    required this.submitting,
    required this.onTap,
  });

  final List<SlotOption> slots;
  final DateTime? selectedSlot;
  final bool submitting;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
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
                      selected: selectedSlot == s.start,
                      onTap: () => onTap(s.start),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Jam yang dicoret sudah terisi atau sudah lewat.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

// ── Tile jam individual ───────────────────────────────────────────────────────
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

// ── Bottom action bar ─────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.summary,
    required this.submitting,
    required this.canSubmit,
    required this.onSubmit,
  });

  final String summary;
  final bool submitting;
  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                summary,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: (canSubmit && !submitting) ? onSubmit : null,
                child: submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream),
                      )
                    : const Text('Tambah ke antrean'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

