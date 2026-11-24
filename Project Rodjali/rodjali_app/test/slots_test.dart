import 'package:flutter_test/flutter_test.dart';

import 'package:rodjali_app/core/format.dart';
import 'package:rodjali_app/core/slots.dart';
import 'package:rodjali_app/models/models.dart';

void main() {
  final date = DateTime.utc(2026, 11, 2);
  final taken = [TakenSlot(start: DateTime.utc(2026, 11, 2, 11, 0), end: DateTime.utc(2026, 11, 2, 11, 30))];

  List<SlotOption> slots({int duration = 30, DateTime? now, TakenSlot? ignore}) => buildSlots(
        date: date,
        open: '10:00',
        close: '21:00',
        durationMinutes: duration,
        taken: taken,
        now: now ?? DateTime.utc(2026, 11, 1, 9, 0),
        ignore: ignore,
      );

  bool ok(List<SlotOption> l, String hm) => l.firstWhere((s) => hhmm(s.start) == hm).available;

  test('slot dibuat dari jam buka sampai layanan masih muat sebelum tutup', () {
    final l = slots();
    expect(hhmm(l.first.start), '10:00');
    expect(hhmm(l.last.start), '20:30');
    expect(l.length, 22);
  });

  test('slot yang bentrok dengan booking aktif tidak tersedia, yang menempel tetap tersedia', () {
    final l = slots();
    expect(ok(l, '11:00'), false);
    expect(ok(l, '10:30'), true); // selesai tepat 11:00
    expect(ok(l, '11:30'), true); // mulai tepat saat yang lain selesai
  });

  test('layanan 60 menit yang beririsan dengan booking lain ditolak', () {
    final l = slots(duration: 60);
    expect(ok(l, '10:30'), false);
    expect(ok(l, '10:00'), true);
    expect(hhmm(l.last.start), '20:00');
  });

  test('slot yang sudah lewat tidak tersedia', () {
    final l = slots(now: DateTime.utc(2026, 11, 2, 10, 45));
    expect(ok(l, '10:00'), false);
    expect(ok(l, '10:30'), false);
    expect(ok(l, '12:00'), true);
  });

  test('saat ganti jadwal, jadwal lama sendiri tidak dianggap bentrok', () {
    final l = slots(ignore: taken.first);
    expect(ok(l, '11:00'), true);
  });
}
