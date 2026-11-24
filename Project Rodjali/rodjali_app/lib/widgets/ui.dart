import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// Membatasi lebar isi layar. Di HP tidak berpengaruh; di tablet isi tetap terpusat dan nyaman dibaca.
class CenteredBody extends StatelessWidget {
  const CenteredBody({super.key, required this.child, this.maxWidth = 600, this.fitHeight = false});

  final Widget child;
  final double maxWidth;

  /// true untuk bar bawah/atas: tinggi mengikuti isi, tidak memenuhi layar.
  final bool fitHeight;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        heightFactor: fitHeight ? 1 : null,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

/// Garis merah-putih-biru ala tiang barber.
class PoleBar extends StatelessWidget {
  const PoleBar({super.key, this.height = 5});

  final double height;

  @override
  Widget build(BuildContext context) {
    const colors = [AppColors.red, Colors.white, AppColors.navy];
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Row(children: [
          for (var i = 0; i < 12; i++) Expanded(child: ColoredBox(color: colors[i % 3], child: const SizedBox.expand())),
        ]),
      ),
    );
  }
}

/// Logo berlatar putih dilebur ke krem supaya tidak tampak kotak putih.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 200});

  final double width;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/images/logo.png',
        width: width,
        color: AppColors.cream,
        colorBlendMode: BlendMode.multiply,
        semanticLabel: 'Rodjali Barbershop',
        errorBuilder: (_, _, _) => const Icon(Icons.content_cut, size: 56),
      );
}

enum Tone { info, progress, success, neutral, danger }

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, this.tone, {super.key, this.onDark = false});

  final String label;
  final Tone tone;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = onDark
        ? (const Color(0x26FFFFFF), AppColors.cream)
        : switch (tone) {
            Tone.info => (const Color(0xFFE3ECF1), AppColors.navy),
            Tone.progress => (const Color(0xFFFAEEDA), const Color(0xFF633806)),
            Tone.success => (const Color(0xFFEAF3DE), const Color(0xFF27500A)),
            Tone.neutral => (AppColors.sand, const Color(0xFF444441)),
            Tone.danger => (const Color(0xFFFCEBEB), const Color(0xFF791F1F)),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

/// Label dan warna status booking untuk pelanggan.
(String, Tone) customerStatus(Booking b) {
  switch (b.status) {
    case 'dipesan':
      return ('Dipesan', Tone.info);
    case 'dikerjakan':
      return ('Sedang dikerjakan', Tone.progress);
    case 'selesai':
      return b.transaction?.isPaid == true ? ('Selesai · Lunas', Tone.success) : ('Selesai', Tone.neutral);
    case 'dibatalkan':
      return ('Dibatalkan', Tone.neutral);
    case 'tidak_datang':
      return ('Tidak datang', Tone.danger);
    default:
      return (statusLabel(b.status), Tone.neutral);
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      );
}
