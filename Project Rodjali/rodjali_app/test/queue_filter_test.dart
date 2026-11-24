import 'package:flutter_test/flutter_test.dart';

import 'package:rodjali_app/core/queue_filter.dart';
import 'package:rodjali_app/models/models.dart';

Booking b(int id, String status, int hour, {String? payment}) => Booking(
      id: id,
      customerName: 'P$id',
      startAt: DateTime.utc(2026, 10, 31, hour),
      endAt: DateTime.utc(2026, 10, 31, hour, 30),
      status: status,
      source: 'online',
      transaction: payment == null
          ? null
          : PaymentTransaction(id: id, bookingId: id, amount: 35000, status: payment),
    );

void main() {
  final all = [
    b(1, 'selesai', 10, payment: 'lunas'),
    b(2, 'dibatalkan', 11),
    b(3, 'dipesan', 15),
    b(4, 'dikerjakan', 13),
    b(5, 'selesai', 12, payment: 'belum_lunas'),
    b(6, 'tidak_datang', 14),
    b(7, 'selesai', 9, payment: 'lunas'),
  ];

  test('antrean aktif: dipesan, dikerjakan, dan selesai yang belum dibayar, urut jam awal', () {
    expect(activeQueue(all).map((e) => e.id), [5, 4, 3]);
  });

  test('riwayat: lunas, batal, tidak datang, yang terbaru di atas', () {
    expect(doneQueue(all).map((e) => e.id), [6, 2, 1, 7]);
  });

  test('selesai tanpa data transaksi tetap dianggap aktif agar tidak terlewat', () {
    expect(isQueueActive(b(8, 'selesai', 10)), true);
  });

  test('daftar kosong menghasilkan dua daftar kosong', () {
    expect(activeQueue([]), isEmpty);
    expect(doneQueue([]), isEmpty);
  });
}
