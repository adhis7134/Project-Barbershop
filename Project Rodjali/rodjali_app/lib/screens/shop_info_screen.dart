import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config.dart';
import '../core/shop_info.dart';

/// Halaman info barbershop yang bisa dibuka tanpa login.
class ShopInfoScreen extends StatelessWidget {
  const ShopInfoScreen({super.key, this.info = ShopInfo.current});

  final ShopInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Info Barbershop')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 200,
                      semanticLabel: info.name,
                      errorBuilder: (_, _, _) => const Icon(Icons.content_cut, size: 56),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(info.tagline, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 20),
                  _InfoCard(
                    icon: Icons.schedule,
                    title: 'Jam buka',
                    child: Text('Setiap hari, ${info.openTime} – ${info.closeTime} WIB'),
                  ),
                  _InfoCard(
                    icon: Icons.event_available,
                    title: 'Cara booking',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Step(1, 'Daftar atau masuk ke aplikasi.'),
                        const _Step(2, 'Pilih layanan, tanggal, dan jam yang masih kosong.'),
                        _Step(
                          3,
                          'Datang tepat waktu. Terlambat lebih dari ${info.lateToleranceMinutes} menit, '
                          'booking bisa ditandai tidak datang.',
                        ),
                        const _Step(4, 'Bayar di kasir dengan QRIS.'),
                        const SizedBox(height: 8),
                        Text(
                          'Ganti jadwal atau batal paling lambat ${AppConfig.cancelMinHours} jam sebelum jam booking.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (info.hasContact)
                    _InfoCard(
                      icon: Icons.location_on_outlined,
                      title: 'Lokasi dan kontak',
                      child: Column(
                        children: [
                          if (info.address.isNotEmpty)
                            _ContactTile(icon: Icons.place_outlined, label: 'Alamat', value: info.address),
                          if (info.whatsapp.isNotEmpty)
                            _ContactTile(icon: Icons.chat_bubble_outline, label: 'WhatsApp', value: info.whatsapp),
                          if (info.instagram.isNotEmpty)
                            _ContactTile(icon: Icons.camera_alt_outlined, label: 'Instagram', value: info.instagram),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.login),
                    label: const Text('Masuk untuk booking'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.text);

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 12, child: Text('$number', style: const TextStyle(fontSize: 12))),
          const SizedBox(width: 12),
          Expanded(child: Padding(padding: const EdgeInsets.only(top: 2), child: Text(text))),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.copy, size: 18),
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        await Clipboard.setData(ClipboardData(text: value));
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('$label disalin.')));
      },
    );
  }
}