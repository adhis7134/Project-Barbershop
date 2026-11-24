import 'package:flutter_test/flutter_test.dart';

import 'package:rodjali_app/core/format.dart';
import 'package:rodjali_app/models/models.dart';

void main() {
  test('rupiah memakai pemisah ribuan titik', () {
    expect(rupiah(35000), 'Rp 35.000');
    expect(rupiah(1500000), 'Rp 1.500.000');
    expect(rupiah(0), 'Rp 0');
  });

  test('waktu server (UTC) diubah ke jam dinding WIB', () {
    final t = parseServerTime('2026-10-31T04:00:00.000000Z');
    expect(hhmm(t), '11:00');
    expect(ymd(t), '2026-10-31');
  });

  test('Booking.fromJson membaca antrean kasir', () {
    final b = Booking.fromJson({
      'id': 1,
      'customer_name': 'Budi',
      'customer_phone': null,
      'start_at': '2026-10-31T04:00:00.000000Z',
      'end_at': '2026-10-31T04:30:00.000000Z',
      'status': 'selesai',
      'source': 'walk_in',
      'service': {'id': 1, 'name': 'Potong Rambut', 'price': 35000, 'duration_minutes': 30, 'is_active': true},
      'transaction': {'id': 9, 'booking_id': 1, 'amount': 35000, 'status': 'belum_lunas'},
    });
    expect(b.isWalkIn, true);
    expect(b.transaction!.isPaid, false);
    expect(hhmm(b.endAt), '11:30');
  });
}
