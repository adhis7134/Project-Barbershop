import 'package:flutter/material.dart';

import '../models/models.dart';
import 'queue_screen.dart';
import 'report_screen.dart';
import 'services_screen.dart';

/// Beranda pemilik: antrean (sama seperti kasir), laporan, dan kelola layanan.
/// Setiap tab dibuat ulang saat dipilih, jadi datanya selalu segar.
class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  int _index = 1; // pemilik paling sering membuka laporan

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      QueueScreen(user: widget.user),
      const ReportScreen(),
      const ServicesScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Antrean'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Laporan'),
          NavigationDestination(icon: Icon(Icons.content_cut), label: 'Layanan'),
        ],
      ),
    );
  }
}
