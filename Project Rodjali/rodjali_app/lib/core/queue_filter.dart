import '../models/models.dart';

/// Booking yang masih perlu ditangani kasir: belum mulai, sedang dikerjakan, atau sudah selesai
/// dicukur tetapi belum dibayar (supaya tagihan tidak terlewat).
bool isQueueActive(Booking b) => switch (b.status) {
      'dipesan' || 'dikerjakan' => true,
      'selesai' => b.transaction?.isPaid != true,
      _ => false, // selesai+lunas, dibatalkan, tidak_datang
    };

/// Antrean aktif, urut jam mulai paling awal.
List<Booking> activeQueue(List<Booking> all) =>
    all.where(isQueueActive).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));

/// Riwayat hari itu (selesai dibayar, batal, tidak datang), yang terbaru di atas.
List<Booking> doneQueue(List<Booking> all) =>
    all.where((b) => !isQueueActive(b)).toList()..sort((a, b) => b.startAt.compareTo(a.startAt));
